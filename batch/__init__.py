"""Batch watcher layer for afai-redux.

Detects new/modified/deleted documents in a source (Google Drive, local
folder, or Microsoft 365 drive) and calls the FastAPI /ingest endpoint
for each file, staging the returned chunks for downstream consumption.

Public surface:
  - BatchIngestor (batch.ingestor)
  - IngestionLedger (batch.ledger)
  - source adapters (batch.sources)
"""

__all__: list[str] = []
