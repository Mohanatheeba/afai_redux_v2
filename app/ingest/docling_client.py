"""HTTP client for docling-serve.

Sends documents to a remote docling-serve instance for conversion and
returns the parsed result as a dict (DoclingDocument JSON). All heavy
lifting — parsing, OCR, VLM, table extraction — happens on the
docling-serve side. We only receive the result.

Environment variables:
  DOCLING_SERVE_URL      Base URL (default: http://localhost:5001)
  DOCLING_SERVE_TIMEOUT  Conversion timeout in seconds (default: 300)
"""

from __future__ import annotations

import logging
import os
from typing import Any

import httpx

from app.models import DocumentSource, IngestConfig

log = logging.getLogger(__name__)

DOCLING_SERVE_URL = os.environ.get("DOCLING_SERVE_URL", "http://localhost:5001")
CONVERT_TIMEOUT_S = float(os.environ.get("DOCLING_SERVE_TIMEOUT", "300"))


class DoclingServeError(RuntimeError):
    """Raised when docling-serve returns an error or is unreachable."""


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------


def convert(source: DocumentSource, config: IngestConfig) -> dict[str, Any]:
    """Send a document to docling-serve for conversion.

    Returns the ``json_content`` dict from docling-serve's response —
    a serialized DoclingDocument that can be deserialized via
    ``DoclingDocument.model_validate()``.

    Raises ``DoclingServeError`` on any failure.
    """
    payload = _build_request(source, config)
    url = f"{DOCLING_SERVE_URL.rstrip('/')}/v1/convert/source"

    try:
        with httpx.Client(timeout=CONVERT_TIMEOUT_S) as client:
            resp = client.post(url, json=payload)
            resp.raise_for_status()
            result = resp.json()
    except httpx.TimeoutException as e:
        raise DoclingServeError(
            f"docling-serve timed out after {CONVERT_TIMEOUT_S}s: {e}"
        ) from e
    except httpx.HTTPStatusError as e:
        body = (e.response.text or "")[:500]
        raise DoclingServeError(
            f"docling-serve returned {e.response.status_code}: {body}"
        ) from e
    except httpx.ConnectError as e:
        raise DoclingServeError(
            f"cannot reach docling-serve at {DOCLING_SERVE_URL}: {e}"
        ) from e
    except Exception as e:
        raise DoclingServeError(f"docling-serve request failed: {e}") from e

    return _extract_document(result)


def health_check() -> bool:
    """Return True if docling-serve is reachable and healthy."""
    try:
        with httpx.Client(timeout=5.0) as client:
            resp = client.get(f"{DOCLING_SERVE_URL.rstrip('/')}/health")
            return resp.status_code == 200
    except Exception:
        return False


# ---------------------------------------------------------------------------
# Internals
# ---------------------------------------------------------------------------


def _build_request(source: DocumentSource, config: IngestConfig) -> dict[str, Any]:
    """Translate our models into docling-serve's ``/v1/convert/source``
    request shape.

    docling-serve accepts:
      - ``http_sources``: list of ``{"url": "..."}``
      - ``file_sources``: list of ``{"base64": "...", "filename": "..."}``
      - ``options``:      conversion knobs (OCR, table mode, VLM, etc.)
    """
    payload: dict[str, Any] = {"options": _build_options(config)}

    if source.url is not None:
        payload["sources"] = [{"kind": "http", "url": source.url}]
    elif source.file_bytes is not None:
        payload["sources"] = [
            {"kind": "file", "base64_string": source.file_bytes, "filename": source.filename}
        ]
    elif source.storage_ref is not None:
        raise DoclingServeError(
            "storage_ref not supported yet — resolve to a URL or base64 bytes "
            "before calling the ingestion service."
        )
    return payload


def _build_options(config: IngestConfig) -> dict[str, Any]:
    """Map our ``IngestConfig`` to docling-serve's options dict.

    The exact field names depend on docling-serve's version. We use the
    names from the v1.x API; mismatches will surface as warnings from
    docling-serve rather than silent failures.
    """
    opts: dict[str, Any] = {
        "do_ocr": True,
        "table_mode": config.table_mode,
        "to_formats": ["json"]
    }

    # VLM — pass config through when enabled.
    if config.vision.mode != "off":
        if config.vision.model:
            opts["vlm_enabled"] = True
            opts["vlm_model"] = config.vision.model

    return opts


def _extract_document(result: Any) -> dict[str, Any]:
    """Pull the DoclingDocument JSON out of docling-serve's response.

    Expected shape (v1.x):
      ``{"document": {"json_content": { ... }}, ...}``

    We try a few known paths to be resilient to minor response-shape
    changes across docling-serve versions.
    """
    if isinstance(result, dict):
        # Primary path: nested under "document" → "json_content".
        doc = result.get("document", {})
        if isinstance(doc, dict):
            jc = doc.get("json_content")
            if jc is not None:
                return jc

        # Fallback: top-level "json_content" (some versions).
        jc = result.get("json_content")
        if jc is not None:
            return jc

        # Fallback: the result itself IS the DoclingDocument.
        if "texts" in result or "body" in result or "main_text" in result:
            return result
    
    raise DoclingServeError(
        "could not locate DoclingDocument JSON in docling-serve response — "
        "check docling-serve version compatibility"
    )
