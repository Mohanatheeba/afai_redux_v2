"""Ledger + staging store for the batch watcher layer.

All persistence concerns live here. Nothing in this module knows
anything about PGVector, embeddings, or the FastAPI service — it just
records what files have been pushed to ``/ingest`` and parks the
responses for a downstream consumer to embed.

Connection uses the standard ``BATCH_PG_*`` env vars (separate from
any other DB the service might talk to). See DEPLOYMENT.md for the
full list.
"""

from __future__ import annotations

import json
import os
from dataclasses import dataclass
from datetime import datetime
from typing import Any, Dict, List, Optional, Set, Tuple

import psycopg2
from psycopg2.extras import Json


# ---------------------------------------------------------------------------
# Ledger row shape
# ---------------------------------------------------------------------------


@dataclass
class LedgerRow:
    source_type: str
    source_root: str
    source_file_id: str
    etag: Optional[str]
    file_hash: Optional[str]
    file_name: str
    mime_type: Optional[str]
    size_bytes: Optional[int]
    modified_time: Optional[datetime]
    doc_id: str
    web_url: Optional[str]
    ingest_status: Optional[str]        # from /ingest response status
    chunks_received: int


# ---------------------------------------------------------------------------
# Ledger
# ---------------------------------------------------------------------------


class IngestionLedger:
    """Wraps ingest_ledger, ingest_staging, ingest_deletion_queue, ingest_cursor."""

    def __init__(self) -> None:
        self._conn_params = self._read_env()

    # ------------------------------------------------------------------
    @staticmethod
    def _read_env() -> Dict[str, Any]:
        host = os.getenv("BATCH_PG_HOST")
        port = os.getenv("BATCH_PG_PORT")
        db = os.getenv("BATCH_PG_DB")
        user = os.getenv("BATCH_PG_USER")
        pwd = os.getenv("BATCH_PG_PASSWORD")
        missing = [
            name for name, val in [
                ("BATCH_PG_HOST", host),
                ("BATCH_PG_PORT", port),
                ("BATCH_PG_DB", db),
                ("BATCH_PG_USER", user),
                ("BATCH_PG_PASSWORD", pwd),
            ]
            if val is None
        ]
        if missing:
            raise RuntimeError(
                f"Batch ledger requires these env vars: {', '.join(missing)}."
            )
        return dict(host=host, port=int(port), dbname=db, user=user, password=pwd)

    def _conn(self):
        return psycopg2.connect(**self._conn_params)

    # ------------------------------------------------------------------
    # Dedup
    # ------------------------------------------------------------------
    def is_already_pushed(
        self, source_type: str, source_file_id: str, etag: Optional[str]
    ) -> bool:
        with self._conn() as conn, conn.cursor() as cur:
            cur.execute(
                """
                SELECT 1 FROM ingest_ledger
                 WHERE source_type = %s
                   AND source_file_id = %s
                   AND COALESCE(etag, '') = COALESCE(%s, '')
                   AND status = 'pushed'
                 LIMIT 1
                """,
                (source_type, source_file_id, etag),
            )
            return cur.fetchone() is not None

    def mark_superseded_for(
        self, source_type: str, source_file_id: str, new_etag: Optional[str]
    ) -> None:
        """Flip any prior 'pushed' rows for this file (different etag) to
        'superseded'. Kept for audit; the new version will be recorded
        alongside as a fresh row."""
        with self._conn() as conn, conn.cursor() as cur:
            cur.execute(
                """
                UPDATE ingest_ledger
                   SET status = 'superseded'
                 WHERE source_type = %s
                   AND source_file_id = %s
                   AND COALESCE(etag, '') <> COALESCE(%s, '')
                   AND status = 'pushed'
                """,
                (source_type, source_file_id, new_etag),
            )

    # ------------------------------------------------------------------
    # Recording push outcomes + staging chunks
    # ------------------------------------------------------------------
    def record_push_success(
        self,
        row: LedgerRow,
        response: Dict[str, Any],
    ) -> int:
        """Write the ledger row and stage the /ingest response atomically.

        Returns the new ledger id.
        """
        with self._conn() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    INSERT INTO ingest_ledger (
                        source_type, source_root, source_file_id, etag,
                        file_hash, file_name, mime_type, size_bytes,
                        modified_time, doc_id, web_url, status,
                        ingest_status, chunks_received
                    ) VALUES (
                        %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s,
                        'pushed', %s, %s
                    )
                    ON CONFLICT (source_type, source_file_id, etag)
                    DO UPDATE SET
                        source_root     = EXCLUDED.source_root,
                        file_hash       = EXCLUDED.file_hash,
                        file_name       = EXCLUDED.file_name,
                        mime_type       = EXCLUDED.mime_type,
                        size_bytes      = EXCLUDED.size_bytes,
                        modified_time   = EXCLUDED.modified_time,
                        doc_id          = EXCLUDED.doc_id,
                        web_url         = EXCLUDED.web_url,
                        status          = 'pushed',
                        ingest_status   = EXCLUDED.ingest_status,
                        chunks_received = EXCLUDED.chunks_received,
                        error           = NULL,
                        pushed_at       = NOW()
                    RETURNING id
                    """,
                    (
                        row.source_type, row.source_root, row.source_file_id,
                        row.etag, row.file_hash, row.file_name, row.mime_type,
                        row.size_bytes, row.modified_time, row.doc_id,
                        row.web_url, row.ingest_status, row.chunks_received,
                    ),
                )
                ledger_id = cur.fetchone()[0]

                cur.execute(
                    """
                    INSERT INTO ingest_staging (
                        ledger_id, doc_id, response_status,
                        chunks, counts, warnings, errors
                    ) VALUES (%s, %s, %s, %s, %s, %s, %s)
                    """,
                    (
                        ledger_id,
                        row.doc_id,
                        response.get("status", "failed"),
                        Json(response.get("chunks", [])),
                        Json(response.get("counts", {})),
                        Json(response.get("warnings", [])),
                        Json(response.get("errors", [])),
                    ),
                )
        return ledger_id

    def record_push_failure(
        self,
        row: LedgerRow,
        error: str,
    ) -> None:
        """Record a failed push attempt. No staging row is written."""
        with self._conn() as conn, conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO ingest_ledger (
                    source_type, source_root, source_file_id, etag,
                    file_hash, file_name, mime_type, size_bytes,
                    modified_time, doc_id, web_url, status, error
                ) VALUES (
                    %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s,
                    'failed', %s
                )
                ON CONFLICT (source_type, source_file_id, etag)
                DO UPDATE SET
                    source_root = EXCLUDED.source_root,
                    status      = 'failed',
                    error       = EXCLUDED.error,
                    pushed_at   = NOW()
                """,
                (
                    row.source_type, row.source_root, row.source_file_id,
                    row.etag, row.file_hash, row.file_name, row.mime_type,
                    row.size_bytes, row.modified_time, row.doc_id,
                    row.web_url, error,
                ),
            )

    # ------------------------------------------------------------------
    # Deletion handoff
    # ------------------------------------------------------------------
    def known_source_file_ids(
        self, source_type: str, source_root: str
    ) -> Set[str]:
        """Source file ids currently in 'pushed' state under this root.

        Used by LocalFolderAdapter to reconcile deletions.
        """
        with self._conn() as conn, conn.cursor() as cur:
            cur.execute(
                """
                SELECT source_file_id FROM ingest_ledger
                 WHERE source_type = %s
                   AND source_root = %s
                   AND status = 'pushed'
                """,
                (source_type, source_root),
            )
            return {r[0] for r in cur.fetchall()}

    def enqueue_deletion(
        self,
        source_type: str,
        source_root: str,
        source_file_id: str,
        file_name: Optional[str],
    ) -> int:
        """Record a deletion event for downstream processing. Also flips
        all 'pushed' / 'superseded' ledger rows for this file to
        'deleted_at_source' so future sweeps don't re-push deleted files.

        Returns the deletion queue row id (0 if nothing to enqueue because
        this file has no live ledger row — a common case for Drive delete
        events on files that live outside our watched folder).
        """
        with self._conn() as conn:
            with conn.cursor() as cur:
                # Look up the doc_id we originally pushed, if any.
                cur.execute(
                    """
                    SELECT doc_id, file_name FROM ingest_ledger
                     WHERE source_type = %s
                       AND source_file_id = %s
                       AND status IN ('pushed', 'superseded')
                     ORDER BY pushed_at DESC
                     LIMIT 1
                    """,
                    (source_type, source_file_id),
                )
                hit = cur.fetchone()
                if not hit:
                    return 0  # never-seen-before file — silent no-op
                doc_id, known_name = hit

                cur.execute(
                    """
                    INSERT INTO ingest_deletion_queue (
                        source_type, source_root, source_file_id,
                        doc_id, file_name
                    ) VALUES (%s, %s, %s, %s, %s)
                    RETURNING id
                    """,
                    (
                        source_type, source_root, source_file_id,
                        doc_id, file_name or known_name,
                    ),
                )
                deletion_id = cur.fetchone()[0]

                cur.execute(
                    """
                    UPDATE ingest_ledger
                       SET status = 'deleted_at_source'
                     WHERE source_type = %s
                       AND source_file_id = %s
                       AND status IN ('pushed', 'superseded')
                    """,
                    (source_type, source_file_id),
                )
        return deletion_id

    # ------------------------------------------------------------------
    # Cursor
    # ------------------------------------------------------------------
    def get_cursor(self, source_type: str, source_root: str) -> Optional[str]:
        with self._conn() as conn, conn.cursor() as cur:
            cur.execute(
                """
                SELECT cursor_token FROM ingest_cursor
                 WHERE source_type = %s AND source_root = %s
                """,
                (source_type, source_root),
            )
            r = cur.fetchone()
            return r[0] if r else None

    def save_cursor(self, source_type: str, source_root: str, token: str) -> None:
        with self._conn() as conn, conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO ingest_cursor (source_type, source_root, cursor_token, last_sweep_at)
                VALUES (%s, %s, %s, NOW())
                ON CONFLICT (source_type, source_root)
                DO UPDATE SET cursor_token  = EXCLUDED.cursor_token,
                              last_sweep_at = NOW()
                """,
                (source_type, source_root, token),
            )
