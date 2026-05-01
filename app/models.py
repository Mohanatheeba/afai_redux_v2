"""Pydantic request/response models for the ingestion API.

Schema is the contract between this service and the caller (AeroChat).
Changes here are changes to the integration surface — treat with care.
"""

from __future__ import annotations

from typing import Any, Literal

from pydantic import BaseModel, ConfigDict, Field, model_validator


# ---------------------------------------------------------------------------
# Request
# ---------------------------------------------------------------------------


class DocumentSource(BaseModel):
    """Where to fetch the document bytes from. Exactly one of the three
    source fields must be set.
    """

    model_config = ConfigDict(extra="forbid")

    file_bytes: str | None = Field(
        default=None,
        description="Base64-encoded document bytes for direct upload.",
    )
    url: str | None = Field(
        default=None,
        description="HTTP(S) URL to fetch the document from.",
    )
    storage_ref: str | None = Field(
        default=None,
        description="Opaque storage reference (e.g. s3://bucket/key) resolved by the service.",
    )

    filename: str = Field(
        ...,
        description="Original filename. Used as a format hint and for display in citations.",
    )
    mime_type: str | None = Field(
        default=None,
        description="Optional MIME type override. Takes precedence over filename-based detection.",
    )

    @model_validator(mode="after")
    def _exactly_one_source(self) -> "DocumentSource":
        provided = [x for x in (self.file_bytes, self.url, self.storage_ref) if x]
        if len(provided) != 1:
            raise ValueError(
                "Exactly one of file_bytes, url, or storage_ref must be provided."
            )
        return self


class OCRConfig(BaseModel):
    model_config = ConfigDict(extra="forbid")
    engine: Literal["easyocr", "rapidocr", "tesseract"] = "easyocr"


class VisionConfig(BaseModel):
    model_config = ConfigDict(extra="forbid")
    # Wiring is TBD pending ecosystem research. When None, the service's
    # default vision pipeline is used (or vision is skipped if unconfigured).
    model: str | None = None
    mode: Literal["description", "off"] = "description"


class ChunkerConfig(BaseModel):
    model_config = ConfigDict(extra="forbid")
    type: Literal["hybrid"] = "hybrid"
    target_tokens: int = Field(default=512, ge=64, le=4096)


class IngestConfig(BaseModel):
    model_config = ConfigDict(extra="forbid")
    ocr: OCRConfig = Field(default_factory=OCRConfig)
    vision: VisionConfig = Field(default_factory=VisionConfig)
    table_mode: Literal["accurate", "fast"] = "accurate"
    chunker: ChunkerConfig = Field(default_factory=ChunkerConfig)


class IngestRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    document: DocumentSource
    doc_id: str = Field(
        ...,
        description="Caller-supplied stable identifier. Deterministic chunk IDs are derived from it.",
    )
    metadata: dict[str, Any] = Field(
        default_factory=dict,
        description="Free-form caller metadata. Attached verbatim to every returned chunk.",
    )
    config: IngestConfig = Field(default_factory=IngestConfig)


# ---------------------------------------------------------------------------
# Response
# ---------------------------------------------------------------------------


class ChunkLocation(BaseModel):
    """Generalized provenance pointing back to a position inside the source
    document. Which fields are populated depends on the document format.
    """

    model_config = ConfigDict(extra="allow")  # format-specific fields vary

    format: Literal["pdf", "docx", "xlsx", "pptx", "image", "html", "md", "txt", "csv"]
    page_no: int | None = None
    bbox: tuple[float, float, float, float] | None = None
    section_path: list[str] | None = None
    paragraph_idx: int | None = None
    sheet: str | None = None
    row_range: tuple[int, int] | None = None
    slide: int | None = None
    element_id: str | None = None


class ChunkMetadata(BaseModel):
    """Metadata attached to every chunk. Caller-supplied metadata is merged
    in via extra fields.
    """

    model_config = ConfigDict(extra="allow")  # caller metadata passed through

    doc_id: str
    chunk_index: int
    chunk_type: Literal["text", "table", "figure_description"] = "text"
    section_path: list[str] | None = None
    parent_chunk_id: str | None = None
    location: ChunkLocation


class Chunk(BaseModel):
    model_config = ConfigDict(extra="forbid")
    chunk_id: str
    text: str
    metadata: ChunkMetadata


class IngestCounts(BaseModel):
    model_config = ConfigDict(extra="forbid")
    pages_processed: int = 0
    images_processed: int = 0
    figures_described: int = 0
    tables_extracted: int = 0
    chunks_produced: int = 0


class IngestResponse(BaseModel):
    model_config = ConfigDict(extra="forbid")
    status: Literal["completed", "partial", "failed"]
    doc_id: str
    chunks: list[Chunk]
    counts: IngestCounts
    warnings: list[str] = Field(default_factory=list)
    errors: list[str] = Field(default_factory=list)


# ---------------------------------------------------------------------------
# Health
# ---------------------------------------------------------------------------


class HealthResponse(BaseModel):
    model_config = ConfigDict(extra="forbid")
    status: Literal["ok", "degraded"]
    version: str
    docling_serve_reachable: bool
    chunker_available: bool
