"""Thin wrapper over Docling's HybridChunker.

HybridChunker is tokenization-aware and preserves Docling provenance on
every chunk, which is what we need for citation-faithful retrieval
downstream. Its constructor signature has changed a couple of times
across Docling releases, so we probe a small set of known kwargs and
fall back to the default constructor if nothing sticks.
"""

from __future__ import annotations

from typing import Any, Iterator

from docling.chunking import HybridChunker


def build_chunker(*, target_tokens: int = 512) -> HybridChunker:
    """Construct a HybridChunker, tolerating minor API drift.

    Known kwargs across Docling versions: ``max_tokens``, ``chunk_size``,
    ``merge_peers``. We try them in order; the first accepted combination
    wins.
    """
    attempts: list[dict[str, Any]] = [
        {"max_tokens": target_tokens, "merge_peers": True},
        {"max_tokens": target_tokens},
        {"chunk_size": target_tokens},
        {},
    ]
    last_err: Exception | None = None
    for kwargs in attempts:
        try:
            return HybridChunker(**kwargs)
        except TypeError as e:
            last_err = e
            continue
    # If even the no-arg form failed, surface the most recent error.
    raise RuntimeError(f"could not construct HybridChunker: {last_err}")


def chunk_document(doc: Any, *, target_tokens: int = 512) -> Iterator[Any]:
    """Yield chunks from a DoclingDocument."""
    chunker = build_chunker(target_tokens=target_tokens)
    yield from chunker.chunk(dl_doc=doc)
