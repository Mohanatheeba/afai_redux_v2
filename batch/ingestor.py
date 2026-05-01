"""Batch watcher orchestrator.

Drives one "sweep" per call:
  1. Ask the source adapter for all changes since the last cursor.
  2. For each upsert event:
       - skip if the ledger already has a 'pushed' row for (file, etag);
       - otherwise download the file, base64-encode it, POST /ingest,
         record the outcome in the ledger, stage the response chunks.
  3. For each delete event: enqueue it in ingest_deletion_queue so
       a downstream consumer can purge PGVector chunks. (The exact
       deletion handoff mechanism is deferred — see DEPLOYMENT.md
       §"Open questions".)
  4. Persist the new cursor on successful completion.

The orchestrator never touches PGVector, never embeds, never chunks.
All of that is the responsibility of the FastAPI service at /ingest
(for chunking) and AeroChat (for embedding + PGVector writes).
"""

from __future__ import annotations

import base64
import logging
import os
import time
import traceback
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass, field
from pathlib import Path
from threading import Lock
from typing import Any, Dict, List, Optional

import httpx

from batch.ledger import IngestionLedger, LedgerRow
from batch.sources.base import (
    CHANGE_DELETE,
    CHANGE_UPSERT,
    FileChange,
    FileRef,
    SourceAdapter,
)


log = logging.getLogger(__name__)

SUPPORTED_EXTS = {".pdf", ".xlsx", ".xls", ".docx", ".pptx", ".html", ".md", ".txt"}

DEFAULT_INGEST_URL = "http://localhost:8000/ingest"
DEFAULT_INGEST_TIMEOUT = 300.0  # matches docling-serve's default upstream timeout


# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------


@dataclass
class RunReport:
    pushed: int = 0
    skipped: int = 0           # already in ledger with same etag
    failed: int = 0
    deleted: int = 0           # deletion events enqueued
    total_chunks: int = 0      # sum of chunks_received across successful pushes
    errors: List[str] = field(default_factory=list)

    def __str__(self) -> str:
        base = (
            f"pushed={self.pushed} skipped={self.skipped} "
            f"failed={self.failed} chunks={self.total_chunks} "
            f"deletions_enqueued={self.deleted}"
        )
        if self.errors:
            base += "\n  errors:\n    " + "\n    ".join(self.errors)
        return base


# ---------------------------------------------------------------------------
# Orchestrator
# ---------------------------------------------------------------------------


class BatchIngestor:
    """Runs one sweep per call. Stateless between calls — all state lives
    in the ledger."""

    def __init__(
        self,
        adapter: SourceAdapter,
        ledger: IngestionLedger,
        ingest_url: Optional[str] = None,
        timeout: Optional[float] = None,
        default_metadata: Optional[Dict[str, Any]] = None,
        parallelism: int = 2,
    ) -> None:
        self.adapter = adapter
        self.ledger = ledger
        self.ingest_url = (
            ingest_url
            or os.getenv("AFAI_INGEST_URL")
            or DEFAULT_INGEST_URL
        )
        self.timeout = timeout if timeout is not None else float(
            os.getenv("AFAI_INGEST_TIMEOUT", DEFAULT_INGEST_TIMEOUT)
        )
        self.default_metadata = default_metadata or {}
        self.parallelism = max(1, parallelism)
        self._report_lock = Lock()

    # ------------------------------------------------------------------
    def sweep(self) -> RunReport:
        report = RunReport()

        since = self.ledger.get_cursor(
            self.adapter.source_type, self.adapter.source_root
        )
        known_ids = self.ledger.known_source_file_ids(
            self.adapter.source_type, self.adapter.source_root
        )
        changes = self.adapter.list_changes(
            since_cursor=since, known_ids=known_ids
        )

        # Partition events. Deletions processed first so a rename
        # (= delete + upsert on some providers) doesn't race.
        deletes: List[FileChange] = []
        upserts: List[FileRef] = []
        for ch in changes:
            if ch.kind == CHANGE_DELETE:
                deletes.append(ch)
            elif ch.kind == CHANGE_UPSERT:
                f = ch.ref
                if Path(f.name).suffix.lower() not in SUPPORTED_EXTS:
                    continue
                if self.ledger.is_already_pushed(
                    self.adapter.source_type, f.id, f.etag
                ):
                    with self._report_lock:
                        report.skipped += 1
                    continue
                upserts.append(f)

        # --- Deletions ----------------------------------------------------
        for ch in deletes:
            self._process_delete(ch.ref, report)

        # --- Upserts ------------------------------------------------------
        if self.parallelism == 1 or len(upserts) <= 1:
            for f in upserts:
                self._process_upsert(f, report)
        else:
            with ThreadPoolExecutor(max_workers=self.parallelism) as pool:
                futures = [
                    pool.submit(self._process_upsert, f, report)
                    for f in upserts
                ]
                for fut in as_completed(futures):
                    try:
                        fut.result()
                    except Exception as exc:
                        log.exception("worker crashed: %s", exc)
                        with self._report_lock:
                            report.failed += 1
                            report.errors.append(f"<worker>: {exc}")

        # Cursor only advances when the sweep completes. If we crashed
        # mid-sweep, the next run replays from the same cursor and the
        # ledger dedup handles the already-pushed files.
        try:
            new_cursor = self.adapter.get_new_cursor()
            if new_cursor is not None:
                self.ledger.save_cursor(
                    self.adapter.source_type,
                    self.adapter.source_root,
                    new_cursor,
                )
        except Exception as exc:
            log.exception("failed to persist cursor: %s", exc)

        return report

    # ------------------------------------------------------------------
    def _process_upsert(self, f: FileRef, report: RunReport) -> None:
        tmp_path: Optional[Path] = None
        try:
            # Mark any prior 'pushed' rows for this file (different etag)
            # as 'superseded' so the latest-per-file query is clean.
            self.ledger.mark_superseded_for(
                self.adapter.source_type, f.id, f.etag
            )

            tmp_path = self.adapter.download_to_temp(f)

            # Build request.
            with tmp_path.open("rb") as fh:
                file_bytes_b64 = base64.b64encode(fh.read()).decode("ascii")

            metadata = dict(self.default_metadata)
            metadata["source_type"] = self.adapter.source_type
            metadata["source_file_id"] = f.id
            if f.web_url:
                metadata["source_url"] = f.web_url
            if f.extra_metadata:
                metadata.update(f.extra_metadata)

            req_body = {
                "document": {
                    "file_bytes": file_bytes_b64,
                    "filename": f.name,
                    **({"mime_type": f.mime_type} if f.mime_type else {}),
                },
                "doc_id": _doc_id_for(self.adapter.source_type, f),
                "metadata": metadata,
            }

            # Call /ingest with lightweight retry on transient errors.
            response = _call_ingest_with_retry(
                self.ingest_url, req_body, timeout=self.timeout
            )

            ingest_status = response.get("status", "unknown")
            chunks_received = int(
                (response.get("counts") or {}).get("chunks_produced", 0)
            )

            row = LedgerRow(
                source_type=self.adapter.source_type,
                source_root=self.adapter.source_root,
                source_file_id=f.id,
                etag=f.etag,
                file_hash=f.hash,
                file_name=f.name,
                mime_type=f.mime_type,
                size_bytes=f.size,
                modified_time=f.modified_time,
                doc_id=req_body["doc_id"],
                web_url=f.web_url,
                ingest_status=ingest_status,
                chunks_received=chunks_received,
            )

            if ingest_status == "failed":
                err = "; ".join(response.get("errors", [])) or "ingest returned status=failed"
                self.ledger.record_push_failure(row, err)
                with self._report_lock:
                    report.failed += 1
                    report.errors.append(f"{f.name}: {err}")
                return

            self.ledger.record_push_success(row, response)
            with self._report_lock:
                report.pushed += 1
                report.total_chunks += chunks_received

        except Exception as exc:
            err_detail = f"{exc}\n{traceback.format_exc()}"
            try:
                self.ledger.record_push_failure(
                    LedgerRow(
                        source_type=self.adapter.source_type,
                        source_root=self.adapter.source_root,
                        source_file_id=f.id,
                        etag=f.etag,
                        file_hash=f.hash,
                        file_name=f.name,
                        mime_type=f.mime_type,
                        size_bytes=f.size,
                        modified_time=f.modified_time,
                        doc_id=_doc_id_for(self.adapter.source_type, f),
                        web_url=f.web_url,
                        ingest_status=None,
                        chunks_received=0,
                    ),
                    error=err_detail,
                )
            except Exception as ledger_exc:
                log.critical(
                    "ledger unreachable while recording failure for %s: %s",
                    f.name, ledger_exc,
                )
            with self._report_lock:
                report.failed += 1
                report.errors.append(f"{f.name}: {exc}")

        finally:
            if tmp_path is not None:
                try:
                    tmp_path.unlink(missing_ok=True)
                except Exception as exc:
                    log.warning("could not unlink temp file %s: %s", tmp_path, exc)

    # ------------------------------------------------------------------
    def _process_delete(self, f: FileRef, report: RunReport) -> None:
        """Enqueue a deletion event. Does not touch PGVector — that's the
        downstream consumer's job (see DEPLOYMENT.md §"Open questions")."""
        try:
            deletion_id = self.ledger.enqueue_deletion(
                source_type=self.adapter.source_type,
                source_root=self.adapter.source_root,
                source_file_id=f.id,
                file_name=f.name or None,
            )
            if deletion_id:
                with self._report_lock:
                    report.deleted += 1
            # deletion_id == 0 means the ledger had no record of this file
            # (e.g. Drive change-feed delete for a file outside our folder);
            # silently ignored.
        except Exception as exc:
            with self._report_lock:
                report.failed += 1
                report.errors.append(
                    f"{f.name or f.id}: deletion enqueue failed: {exc}"
                )


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _doc_id_for(source_type: str, f: FileRef) -> str:
    """Derive a stable doc_id for /ingest from the source's file id.

    Drive fileId and Graph itemId are both already stable across
    modifications — use them verbatim. Local paths are prefixed with
    ``local:`` for readability in logs.
    """
    if source_type == "local":
        return f"local:{f.id}"
    return f.id


def _call_ingest_with_retry(
    url: str,
    body: Dict[str, Any],
    *,
    timeout: float,
    attempts: int = 3,
) -> Dict[str, Any]:
    """POST /ingest with simple exponential backoff on transient errors.

    Transient = network errors, timeouts, HTTP 429 / 5xx. Permanent
    errors (4xx other than 429) raise immediately.
    """
    last_exc: Optional[BaseException] = None
    for i in range(1, attempts + 1):
        try:
            with httpx.Client(timeout=timeout) as client:
                r = client.post(url, json=body)
                if r.status_code == 429 or 500 <= r.status_code < 600:
                    raise _Transient(
                        f"HTTP {r.status_code}: {r.text[:200]}"
                    )
                r.raise_for_status()
                return r.json()
        except (httpx.TransportError, httpx.TimeoutException, _Transient) as exc:
            last_exc = exc
            if i == attempts:
                break
            delay = min(10.0, 1.0 * (2 ** (i - 1)))
            log.warning(
                "transient error calling /ingest (attempt %d/%d): %s — retrying in %.1fs",
                i, attempts, exc, delay,
            )
            time.sleep(delay)
    assert last_exc is not None
    raise last_exc


class _Transient(Exception):
    """Internal marker for HTTP responses we want to retry."""
