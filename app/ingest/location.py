"""Map a HybridChunker chunk (with Docling provenance) to our ChunkLocation.

Which location fields are populated depends on the source format. The
format hint is passed in because not every format carries page numbers
or bounding boxes; in those cases we lean on section path or paragraph
index instead.
"""

from __future__ import annotations

from typing import Any

from app.models import ChunkLocation


def infer_format(filename: str) -> str:
    """Lowercase filename extension → our format label."""
    name = filename.lower()
    if name.endswith(".pdf"):
        return "pdf"
    if name.endswith(".docx"):
        return "docx"
    if name.endswith((".xlsx", ".xls")):
        return "xlsx"
    if name.endswith(".pptx"):
        return "pptx"
    if name.endswith((".html", ".htm")):
        return "html"
    if name.endswith(".md"):
        return "md"
    if name.endswith(".csv"):
        return "csv"
    if name.endswith((".png", ".jpg", ".jpeg", ".tif", ".tiff", ".bmp", ".gif", ".webp")):
        return "image"
    return "txt"


def section_path(chunk: Any) -> list[str] | None:
    """Extract the heading chain for a HybridChunker chunk, if present."""
    meta = getattr(chunk, "meta", None)
    if meta is None:
        return None
    headings = getattr(meta, "headings", None)
    if not headings:
        return None
    return [str(h) for h in headings if h]


def build_location(chunk: Any, *, fmt: str) -> ChunkLocation:
    """Turn the first Docling provenance on a chunk into our location shape."""
    loc: dict[str, Any] = {"format": fmt}

    meta = getattr(chunk, "meta", None)
    doc_items = getattr(meta, "doc_items", None) or []

    first_prov = None
    first_item = None
    for item in doc_items:
        provs = getattr(item, "prov", None) or []
        if provs:
            first_prov = provs[0]
            first_item = item
            break

    if first_prov is not None:
        page_no = getattr(first_prov, "page_no", None)
        if page_no:
            # PPTX slides come back as page_no too; map into the right field.
            if fmt == "pptx":
                loc["slide"] = int(page_no)
            else:
                loc["page_no"] = int(page_no)

        bbox = getattr(first_prov, "bbox", None)
        if bbox is not None:
            coords = _bbox_to_tuple(bbox)
            if coords is not None:
                loc["bbox"] = coords

    if first_item is not None:
        element_id = getattr(first_item, "self_ref", None) or getattr(first_item, "id", None)
        if element_id:
            loc["element_id"] = str(element_id)

    sp = section_path(chunk)
    if sp:
        loc["section_path"] = sp

    return ChunkLocation(**loc)


def _bbox_to_tuple(bbox: Any) -> tuple[float, float, float, float] | None:
    """Coerce a Docling BoundingBox to a (l, t, r, b) tuple, tolerating
    different attribute names across versions.
    """
    for attrs in (("l", "t", "r", "b"), ("left", "top", "right", "bottom")):
        try:
            vals = tuple(float(getattr(bbox, a)) for a in attrs)
            return vals  # type: ignore[return-value]
        except (AttributeError, TypeError, ValueError):
            continue
    return None
