"""Ingestion orchestrator (Path A — docling-serve upstream).

One public entry point — ``run_ingest(req)`` — that takes a validated
``IngestRequest`` and returns an ``IngestResponse``.

Flow:
  1. Forward document to docling-serve for conversion (parsing, OCR, VLM).
  2. Deserialize the returned DoclingDocument JSON.
  3. Run HybridChunker locally to produce structured chunks.
  4. Attach metadata, deterministic chunk IDs, and provenance to each chunk.
  5. Return chunks to caller (AeroChat embeds and stores them).

Any failure is captured into the response ``errors`` list with a status of
``"failed"`` or ``"partial"``; we don't raise out of the pipeline.
"""

from __future__ import annotations

import logging
from typing import Any

from app.ingest.chunk_id import make_chunk_id
from app.ingest.chunker import chunk_document
from app.ingest.docling_client import DoclingServeError, convert
from app.ingest.location import build_location, infer_format, section_path
from app.models import (
    Chunk,
    ChunkMetadata,
    IngestCounts,
    IngestRequest,
    IngestResponse,
)

log = logging.getLogger(__name__)


# Keys we fill on ChunkMetadata ourselves. Caller metadata cannot clobber
# these — collisions are silently ignored with a warning.
_RESERVED_METADATA_KEYS = frozenset(
    {
        "doc_id",
        "chunk_index",
        "chunk_type",
        "section_path",
        "parent_chunk_id",
        "location",
    }
)


def run_ingest(req: IngestRequest) -> IngestResponse:
    warnings: list[str] = []
    errors: list[str] = []
    counts = IngestCounts()

    # 1. Send to docling-serve for conversion.
    try:
        doc_json = convert(req.document, req.config)
    except DoclingServeError as e:
        errors.append(str(e))
        return _fail(req.doc_id, counts, warnings, errors)

    # 2. Deserialize into a DoclingDocument so HybridChunker can consume it.
    try:
        doc = _deserialize_document(doc_json)
    except Exception as e:  # noqa: BLE001
        log.exception("failed to deserialize DoclingDocument from docling-serve response")
        errors.append(f"DoclingDocument deserialization failed: {e}")
        return _fail(req.doc_id, counts, warnings, errors)

    # 3. Populate counts from the parsed document.
    fmt = infer_format(req.document.filename)
    _fill_counts(counts, doc, fmt, warnings)

    # 4. Chunk.
    chunks_out: list[Chunk] = []
    try:
        caller_md = _sanitize_caller_metadata(req.metadata, warnings)
        for idx, ch in enumerate(
            chunk_document(doc, target_tokens=req.config.chunker.target_tokens)
        ):
            text = (getattr(ch, "text", None) or "").strip()
            if not text:
                continue
            location = build_location(ch, fmt=fmt)
            chunk = Chunk(
                chunk_id=make_chunk_id(req.doc_id, idx, text),
                text=text,
                metadata=ChunkMetadata(
                    doc_id=req.doc_id,
                    chunk_index=idx,
                    chunk_type="text",
                    section_path=section_path(ch),
                    parent_chunk_id=None,
                    location=location,
                    **caller_md,
                ),
            )
            chunks_out.append(chunk)
    except Exception as e:  # noqa: BLE001
        log.exception("chunking failed")
        errors.append(f"chunking failed: {e}")
        return IngestResponse(
            status="partial" if chunks_out else "failed",
            doc_id=req.doc_id,
            chunks=chunks_out,
            counts=counts,
            warnings=warnings,
            errors=errors,
        )

    counts.chunks_produced = len(chunks_out)

    status: Any = "completed"
    if not chunks_out:
        warnings.append("no chunks produced — document may be empty or unparseable")
        status = "partial"
    elif warnings:
        status = "partial"

    return IngestResponse(
        status=status,
        doc_id=req.doc_id,
        chunks=chunks_out,
        counts=counts,
        warnings=warnings,
        errors=errors,
    )


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _deserialize_document(doc_json: dict[str, Any]) -> Any:
    """Reconstruct a DoclingDocument object from its JSON representation.

    We try the modern ``docling_core`` import path first, then fall back
    to older module paths. If none work, we return the raw dict — the
    chunker may still be able to consume it via duck-typing.
    """
    # Try modern docling-core path.
    try:
        from docling_core.types.doc import DoclingDocument
        return DoclingDocument.model_validate(doc_json)
    except ImportError:
        pass

    # Try older path (some versions expose it differently).
    try:
        from docling.datamodel.document import DoclingDocument  # type: ignore[import]
        return DoclingDocument.model_validate(doc_json)
    except ImportError:
        pass

    log.warning(
        "could not import DoclingDocument for deserialization — "
        "falling back to raw dict (chunker may fail)"
    )
    return doc_json


def _fail(
    doc_id: str,
    counts: IngestCounts,
    warnings: list[str],
    errors: list[str],
) -> IngestResponse:
    return IngestResponse(
        status="failed",
        doc_id=doc_id,
        chunks=[],
        counts=counts,
        warnings=warnings,
        errors=errors,
    )


def _fill_counts(counts: IngestCounts, doc: Any, fmt: str, warnings: list[str]) -> None:
    try:
        if fmt in {"pdf", "pptx"}:
            pages = getattr(doc, "pages", None)
            if pages is not None:
                counts.pages_processed = len(pages)
        counts.tables_extracted = len(getattr(doc, "tables", None) or [])
        counts.images_processed = len(getattr(doc, "pictures", None) or [])
    except Exception as e:  # noqa: BLE001
        warnings.append(f"counts collection partial: {e}")


def _sanitize_caller_metadata(
    metadata: dict[str, Any], warnings: list[str]
) -> dict[str, Any]:
    """Drop caller metadata keys that would collide with our own fields."""
    clean = {}
    for k, v in metadata.items():
        if k in _RESERVED_METADATA_KEYS:
            warnings.append(f"caller metadata key '{k}' is reserved; ignored")
            continue
        clean[k] = v
    return clean
