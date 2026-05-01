"""Deterministic chunk-ID derivation.

Same ``(doc_id, chunk_index, chunk_text)`` must always produce the same
chunk ID so that re-ingesting an unchanged document produces stable IDs
the caller (AeroChat) can use to upsert into PGVector without creating
duplicates.
"""

from __future__ import annotations

import hashlib

_SEP = b"\x00"


def make_chunk_id(doc_id: str, index: int, text: str) -> str:
    """Derive a stable 32-char hex chunk ID.

    Truncating a SHA-256 digest to 128 bits gives us a collision-resistant
    ID that still fits comfortably in a UUID-sized column without the
    ambiguity of pretending it's a UUID.
    """
    h = hashlib.sha256()
    h.update(doc_id.encode("utf-8"))
    h.update(_SEP)
    h.update(str(index).encode("ascii"))
    h.update(_SEP)
    h.update(text.encode("utf-8"))
    return h.hexdigest()[:32]
