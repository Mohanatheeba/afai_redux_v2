"""FastAPI entrypoint for the ingestion service.

Two endpoints:
  * POST /ingest  — parse a document into structured chunks
  * GET  /health  — liveness + readiness (checks docling-serve upstream)
"""

from __future__ import annotations

from fastapi import FastAPI

from app import __version__
from app.ingest.docling_client import health_check as docling_serve_healthy
from app.ingest.pipeline import run_ingest
from app.models import HealthResponse, IngestRequest, IngestResponse

app = FastAPI(
    title="afai-redux ingestion service",
    version=__version__,
    description=(
        "Parses documents into structured chunks with rich metadata. "
        "Conversion is delegated to docling-serve; this service owns "
        "chunking, metadata enrichment, and the chunk contract with AeroChat."
    ),
)


@app.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    """Liveness + readiness.

    Checks that docling-serve (upstream conversion) is reachable and
    that the chunking module is importable locally.
    """
    serve_ok = docling_serve_healthy()
    chunker_ok = _module_importable("docling.chunking")
    all_ok = serve_ok and chunker_ok
    return HealthResponse(
        status="ok" if all_ok else "degraded",
        version=__version__,
        docling_serve_reachable=serve_ok,
        chunker_available=chunker_ok,
    )


@app.post("/ingest", response_model=IngestResponse)
def ingest(req: IngestRequest) -> IngestResponse:
    """Parse a document into structured chunks.

    The conversion (parsing, OCR, VLM) is handled by docling-serve over
    HTTP. Chunking + metadata enrichment happens here. Declared as a
    sync ``def`` — FastAPI runs it on its threadpool, which is fine for
    the blocking HTTP call to docling-serve + CPU-bound chunking.
    """
    return run_ingest(req)


def _module_importable(name: str) -> bool:
    try:
        __import__(name)
        return True
    except ImportError:
        return False
