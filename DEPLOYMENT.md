# afai-redux Deployment Guide

Deployment guide for the AF AI Helper document ingestion service. This service parses documents into structured chunks that AeroChat embeds and stores in PGVector for retrieval.

## Architecture overview

Three concerns, each independently deployable:

```
                          (triggered by: upload UI in AeroChat)
AeroChat (existing) ────────────────────────────────────────────┐
                                                                │
                          (triggered by: Drive watcher)          │
Google Drive ──► afai-redux batch watcher ──────────────────────┤
                 (this repo, batch/ package)                    │
                                                                │
                                                                ▼
                                                          POST /ingest
                                                                │
                                                                ▼
                                          afai-redux FastAPI (this repo, app/)
                                          chunking + metadata enrichment
                                                                │
                                                                │ POST /v1/convert/source
                                                                ▼
                                          docling-serve  (upstream, Docker image)
                                          parsing / OCR / VLM / tables
                                                                │
                                                                │ DoclingDocument JSON
                                                                ▼
                                          afai-redux  (HybridChunker → chunks)
                                                                │
                                                                ▼
                                          Response: structured chunks
                                                                │
     ┌──────────────────────────────────────────────────────────┘
     │ (from UI-triggered ingest)      (from watcher-triggered ingest)
     │                                          │
     ▼                                          ▼
AeroChat: embed + PGVector       ingest_staging table (in batch layer's DB)
                                          │
                                          │ (handoff: open question)
                                          ▼
                                 AeroChat / worker:
                                 embed + PGVector
```

**afai-redux FastAPI service (`app/`)**: chunking core. Receives documents, forwards to docling-serve for parsing, runs HybridChunker locally, returns structured chunks. Stateless. Never touches PGVector.

**afai-redux batch watcher (`batch/`)**: separate process that watches Google Drive (or local / Microsoft Graph) for new, modified, or deleted documents and calls `POST /ingest` for each change. Persists ledger + staging state in its own Postgres tables (schema in `batch/schema.sql`). Never touches PGVector — the eventual handoff of staged chunks to AeroChat's embedder is an open question documented below.

**docling-serve**: Maintained by the Docling team. Handles the heavy lifting -- PDF parsing, OCR, VLM (vision-language model for image description), table extraction. Published as a Docker image.

**AeroChat (existing)**: co-pilot app. Owns embedding and PGVector writes. Two triggers feed it: (a) tenant-uploaded documents via its admin UI, (b) Drive-sourced documents via the batch watcher → staging-table handoff.

## Prerequisites

- Docker and Docker Compose (or equivalent container platform)
- Python 3.11+ (if running without Docker)
- AeroChat instance with PGVector configured
- Network connectivity between all three services (AeroChat, afai-redux, docling-serve)

## Environment variables

### afai-redux

| Variable | Required | Default | Description |
|---|---|---|---|
| `DOCLING_SERVE_URL` | Yes | `http://localhost:5001` | Base URL of the docling-serve instance |
| `DOCLING_SERVE_TIMEOUT` | No | `300` | Timeout in seconds for conversion requests |
| `PORT` | No | `8000` | Port this service listens on |

### docling-serve

Refer to the [docling-serve documentation](https://github.com/docling-project/docling-serve) for the full list. Key ones:

| Variable | Description |
|---|---|
| `DOCLING_SERVE_CONCURRENCY` | Max parallel conversions (default varies by version) |
| `DOCLING_SERVE_HOST` | Bind host (default `0.0.0.0`) |
| `DOCLING_SERVE_PORT` | Bind port (default `5001`) |

VLM and OCR configuration on docling-serve is handled via their API options or environment variables -- see their docs for current settings.

## Option 1: Docker Compose (recommended for initial deployment)

Create a `docker-compose.yml` in the deployment directory:

```yaml
version: "3.8"

services:
  # ---------------------------------------------------------------
  # docling-serve: document conversion (parsing, OCR, VLM, tables)
  # ---------------------------------------------------------------
  docling-serve:
    image: ghcr.io/docling-project/docling-serve:v1.16.1
    ports:
      - "5001:5001"
    environment:
      - DOCLING_SERVE_PORT=5001
    volumes:
      # Persist model cache so restarts don't re-download models
      - docling-cache:/root/.cache
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5001/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  # ---------------------------------------------------------------
  # afai-redux: chunking + metadata enrichment
  # ---------------------------------------------------------------
  afai-redux:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "8000:8000"
    environment:
      - DOCLING_SERVE_URL=http://docling-serve:5001
      - DOCLING_SERVE_TIMEOUT=300
    depends_on:
      docling-serve:
        condition: service_healthy
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  docling-cache:
```

### Dockerfile for afai-redux

Create this `Dockerfile` in the repo root:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install system deps (curl for healthcheck)
RUN apt-get update && apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

# Install Python deps
COPY pyproject.toml .
RUN pip install --no-cache-dir .

# Copy application code
COPY app/ app/

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Deploy

```bash
# Clone the repo
git clone <repo-url>
cd afai-redux
git checkout claude/explore-codebase-oW8QJ

# Build and start both services
docker compose up -d

# Verify both services are healthy
curl http://localhost:8000/health
# Expected: {"status":"ok","version":"0.1.0","docling_serve_reachable":true,"chunker_available":true}

curl http://localhost:5001/health
# Expected: 200 OK with docling-serve health info
```

### First cold start note

The first time docling-serve starts, it downloads ML models (OCR, TableFormer, etc.) into the cache volume. This can take several minutes. Subsequent starts are fast because the volume persists.

## Option 2: Railway deployment

### Deploy docling-serve

1. Create a new Railway project
2. Add a service from Docker image: `ghcr.io/docling-project/docling-serve:v1.16.1`
3. Set port to `5001`
4. Add a persistent volume mounted at `/root/.cache` (for model cache)
5. Note the internal URL Railway assigns (e.g., `docling-serve.railway.internal:5001`)

### Deploy afai-redux

1. In the same Railway project, add a service from this GitHub repo
2. Set the root directory to the repo root
3. Railway will auto-detect the `Dockerfile` (create the Dockerfile from Option 1 above first, commit it)
4. Set environment variables:
   - `DOCLING_SERVE_URL=http://docling-serve.railway.internal:5001`
   - `PORT=8000`
5. Set port to `8000`

### Verify

Use Railway's public URL for afai-redux:
```bash
curl https://<your-afai-redux>.up.railway.app/health
```

## Option 3: Manual / VM deployment

```bash
# Terminal 1: Start docling-serve
docker run -d \
  --name docling-serve \
  -p 5001:5001 \
  -v docling-cache:/root/.cache \
  ghcr.io/docling-project/docling-serve:v1.16.1

# Terminal 2: Start afai-redux
cd afai-redux
python -m venv .venv
source .venv/bin/activate
pip install .
DOCLING_SERVE_URL=http://localhost:5001 \
  uvicorn app.main:app --host 0.0.0.0 --port 8000
```

## Wiring into AeroChat

Once both services are running and healthy, AeroChat needs to call `/ingest` when a co-pilot tenant uploads a document.

### 1. Add tenant flag

In AeroChat's company/tenant config, add a flag that identifies co-pilot tenants (e.g., a column on the companies table, or a config entry). When this flag is set, AeroChat routes document uploads to afai-redux instead of its own ingestion path.

### 2. Call /ingest on document upload

When a co-pilot tenant uploads a document through AeroChat's admin UI, instead of (or after) writing to `knowledge_base` / `pdf_documents`, AeroChat calls:

```
POST http://<afai-redux-host>:8000/ingest
Content-Type: application/json

{
  "document": {
    "url": "https://<file-storage-url>/handbook.pdf",
    "filename": "ActiveFireEmployeeHandbook.pdf"
  },
  "doc_id": "<knowledge_base.uid or pdf_documents.uid>",
  "metadata": {
    "project": "company_wide",
    "document_type": "handbook",
    "source_url": "https://<file-storage-url>/handbook.pdf"
  }
}
```

Or with base64 for direct upload:

```
{
  "document": {
    "file_bytes": "<base64-encoded-file-content>",
    "filename": "EquipmentList_SGP2.xlsx"
  },
  "doc_id": "<uid>",
  "metadata": {
    "project": "SGP2-AWP",
    "document_type": "equipment_list"
  }
}
```

### 3. Handle the response

afai-redux returns structured chunks:

```json
{
  "status": "completed",
  "doc_id": "<uid>",
  "chunks": [
    {
      "chunk_id": "a1b2c3d4...",
      "text": "The annual leave entitlement is...",
      "metadata": {
        "doc_id": "<uid>",
        "chunk_index": 0,
        "chunk_type": "text",
        "section_path": ["Employee Handbook", "Leave Policy", "Annual Leave"],
        "location": {
          "format": "pdf",
          "page_no": 29
        },
        "project": "company_wide",
        "document_type": "handbook",
        "source_url": "https://..."
      }
    }
  ],
  "counts": {
    "pages_processed": 42,
    "chunks_produced": 87,
    "tables_extracted": 3,
    "images_processed": 6,
    "figures_described": 0
  },
  "warnings": [],
  "errors": []
}
```

AeroChat then:

1. **Embeds each chunk** using the tenant's embedding model (from `llm_config`)
2. **Writes to PGVector** -- each chunk becomes a vector with its metadata stored alongside
3. **Stores chunk IDs** in `pdf_documents.ids` for later deletion/re-ingestion:
   ```python
   chunk_ids = [c["chunk_id"] for c in response["chunks"]]
   # UPDATE pdf_documents SET ids = json(chunk_ids) WHERE uid = doc_id
   ```

### 4. Re-ingestion

When a document is re-uploaded or updated:

1. Read existing chunk IDs from `pdf_documents.ids`
2. Delete those vectors from PGVector
3. Call `/ingest` again with the same `doc_id`
4. Embed + store the new chunks
5. Update `pdf_documents.ids` with the new chunk IDs

The deterministic chunk ID scheme means that unchanged content produces the same IDs -- AeroChat can diff old vs. new if it wants to do incremental updates rather than full re-ingestion.

### 5. Configure co-pilot tenant in AeroChat

For the query side (no code changes needed -- config only):

**Biz Schema / User's Custom Instructions** for the co-pilot tenant:
```
You are an internal employee assistant for Active Fire Protection.
Answer questions based only on the provided sources. If the sources
do not contain enough information, say "I don't have information on
that in the uploaded documents."

When citing sources, include the document name and page number or
section path from the source metadata.

If retrieved sources span multiple projects and the user hasn't
specified which project they mean, ask them to clarify before
answering. List the candidate projects found.
```

**rag_config.additional_prompt** for the co-pilot tenant:
```
Use metadata filters when the user specifies a project name.
Prioritize exact project matches over company-wide documents.
```

## API reference

### POST /ingest

Parse a document into structured chunks.

**Request body:**

| Field | Type | Required | Description |
|---|---|---|---|
| `document.file_bytes` | string | One of three | Base64-encoded file content |
| `document.url` | string | One of three | URL to fetch the document from |
| `document.storage_ref` | string | One of three | Storage reference (not yet implemented) |
| `document.filename` | string | Yes | Original filename (format detection + display) |
| `document.mime_type` | string | No | MIME type override |
| `doc_id` | string | Yes | Stable identifier. Used in chunk ID derivation. |
| `metadata` | object | No | Free-form key-value pairs attached to every chunk |
| `config.ocr.engine` | string | No | `"easyocr"` (default), `"rapidocr"`, `"tesseract"` |
| `config.vision.model` | string | No | VLM model name (default: docling-serve default) |
| `config.vision.mode` | string | No | `"description"` (default) or `"off"` |
| `config.table_mode` | string | No | `"accurate"` (default) or `"fast"` |
| `config.chunker.target_tokens` | int | No | Chunk size target (default: 512, range: 64-4096) |

**Response body:**

| Field | Type | Description |
|---|---|---|
| `status` | string | `"completed"`, `"partial"`, or `"failed"` |
| `doc_id` | string | Echo of the request doc_id |
| `chunks` | array | Array of chunk objects (see below) |
| `counts` | object | Processing counts (pages, tables, images, chunks) |
| `warnings` | array | Non-fatal issues encountered |
| `errors` | array | Fatal issues (when status is `"failed"`) |

**Chunk object:**

| Field | Type | Description |
|---|---|---|
| `chunk_id` | string | Deterministic 32-char hex ID |
| `text` | string | The chunk text content (what AeroChat embeds) |
| `metadata.doc_id` | string | Parent document ID |
| `metadata.chunk_index` | int | Position in sequence |
| `metadata.chunk_type` | string | `"text"`, `"table"`, or `"figure_description"` |
| `metadata.section_path` | array | Heading breadcrumb (e.g., `["Ch 1", "Section A"]`) |
| `metadata.parent_chunk_id` | string | For parent-child expansion (future) |
| `metadata.location` | object | Format-dependent provenance (page_no, bbox, sheet, etc.) |
| `metadata.*` | any | All caller-supplied metadata fields passed through |

### GET /health

**Response:**

| Field | Type | Description |
|---|---|---|
| `status` | string | `"ok"` or `"degraded"` |
| `version` | string | Service version |
| `docling_serve_reachable` | bool | Whether docling-serve responded to a health check |
| `chunker_available` | bool | Whether HybridChunker is importable |

## Troubleshooting

### /health returns `"degraded"` with `docling_serve_reachable: false`

- Check that docling-serve is running: `curl http://<docling-serve-host>:5001/health`
- Check `DOCLING_SERVE_URL` is set correctly in afai-redux's environment
- If using Docker Compose, check that both services are on the same network
- On first start, docling-serve may take several minutes to download models before becoming healthy

### /health returns `"degraded"` with `chunker_available: false`

- The `docling` Python package is not installed or is broken in afai-redux's environment
- Rebuild the Docker image: `docker compose build afai-redux`

### /ingest returns `"failed"` with conversion errors

- Check docling-serve logs: `docker compose logs docling-serve`
- Common causes: unsupported file format, corrupt file, docling-serve out of memory on very large documents
- For large PDFs (500+ pages), increase `DOCLING_SERVE_TIMEOUT` and ensure docling-serve has enough RAM (4GB+ recommended)

### Chunks have no page numbers or section paths

- For DOCX files: page numbers are not available (Word doesn't track layout). Section paths are derived from headings.
- For scanned PDFs: ensure OCR is enabled (it is by default). Check docling-serve logs for OCR errors.
- If location fields are all null, the docling-serve response may have changed format -- check afai-redux logs for deserialization warnings.

### Slow ingestion

- First request is always slow (model warm-up on docling-serve)
- Scanned PDFs with many pages are CPU-intensive. Consider:
  - Increasing docling-serve resources (more CPU/RAM)
  - Moving docling-serve to a GPU-capable host for faster OCR/VLM
  - Using `config.table_mode: "fast"` for less table accuracy but faster processing

## Upgrading docling-serve

To upgrade docling-serve to a newer version:

1. Check the [docling-serve releases](https://github.com/docling-project/docling-serve/releases) for breaking changes
2. Update the image tag in `docker-compose.yml` (e.g., `v1.16.1` -> `v1.17.0`)
3. Test with a known document to verify chunks are equivalent
4. Deploy

afai-redux does not need to change when upgrading docling-serve, unless they change the `/v1/convert/source` response format (which would be a major version bump on their side).

## GPU upgrade path (when needed)

When ingestion speed on image-heavy or scanned documents becomes a bottleneck:

1. Move docling-serve to a GPU-capable platform (Cloud Run with GPU, a GPU VM, Modal, etc.)
2. Update `DOCLING_SERVE_URL` in afai-redux to point at the new host
3. No code changes, no rebuild of afai-redux

afai-redux itself never needs GPU -- it only does text chunking.

---

## Batch watcher layer (`batch/`)

The FastAPI service chunks one document per HTTP call. The batch watcher is a separate process that turns a **Google Drive folder** (or a local directory, or a Microsoft 365 drive) into a stream of `POST /ingest` calls. It runs independently of the FastAPI service — they communicate only over HTTP.

### What the watcher does on each sweep

1. Ask the configured source adapter for every file that changed since the last sweep (including deletions where the provider surfaces them).
2. For each new or modified file:
   - Skip if already pushed (dedup by `(source_type, source_file_id, etag)`).
   - Download to a temp file, base64-encode, call `POST /ingest`.
   - Record the outcome in `ingest_ledger`, park the returned chunks in `ingest_staging`.
3. For each deleted file: insert an event into `ingest_deletion_queue` (no PGVector action — downstream handoff, see "Open questions").
4. Persist the new cursor for the next sweep.

Sweeps are idempotent. Crashing mid-sweep is safe — the next run replays from the same cursor and the ledger filters out already-pushed files.

### Source adapters

| Adapter | `source_type` | Status |
|---|---|---|
| `GoogleDriveAdapter` | `gdrive` | Pilot. Uses Drive `changes.list` + startPageToken. Surfaces deletions natively. |
| `LocalFolderAdapter` | `local` | Dev/test fixture. Walks a directory, reconciles deletions by set-diff. |
| `GraphDriveAdapter` | `graph` | Stub for M365 cutover. Delta query implementation spec in module docstring. |

Adding a new source (e.g. Dropbox, S3, SharePoint without Graph) means one class satisfying the `SourceAdapter` protocol in `batch/sources/base.py`. No changes to the orchestrator, ledger, or schema.

### Environment variables (watcher)

| Variable | Required | Default | Description |
|---|---|---|---|
| `AFAI_INGEST_URL` | No | `http://localhost:8000/ingest` | URL of the FastAPI `/ingest` endpoint the watcher calls. |
| `AFAI_INGEST_TIMEOUT` | No | `300` | Per-request timeout in seconds (matches docling-serve default). |
| `BATCH_PG_HOST` | Yes | — | Postgres host for ledger / staging tables. |
| `BATCH_PG_PORT` | Yes | — | Postgres port. |
| `BATCH_PG_DB` | Yes | — | Postgres database name. |
| `BATCH_PG_USER` | Yes | — | Postgres user. |
| `BATCH_PG_PASSWORD` | Yes | — | Postgres password. |
| `GDRIVE_SERVICE_ACCOUNT_JSON` | For gdrive | — | Absolute path to Google service-account JSON key file. |
| `GRAPH_TENANT_ID` / `GRAPH_CLIENT_ID` / `GRAPH_CLIENT_SECRET` / `GRAPH_DRIVE_ID` | For graph | — | Entra ID app credentials. Not used until `GraphDriveAdapter` is implemented. |

The batch layer's Postgres (`BATCH_PG_*`) can be the same physical database as AeroChat's PGVector, or a different one — these tables are strictly the watcher's concern.

### Database schema (watcher)

DDL is in `batch/schema.sql`. Apply once before the first sweep:

```bash
psql -h "$BATCH_PG_HOST" -p "$BATCH_PG_PORT" -U "$BATCH_PG_USER" -d "$BATCH_PG_DB" \
     -f batch/schema.sql
```

Four tables are created:

| Table | Purpose |
|---|---|
| `ingest_ledger` | One row per pushed file version. Dedup key, status, error, chunk count. |
| `ingest_staging` | Full `/ingest` response (chunks + counts) for downstream consumption. `consumed_at` / `consumed_by` columns let a consumer claim rows. |
| `ingest_deletion_queue` | Deletion events from the source, waiting for a downstream handler. |
| `ingest_cursor` | Per-source incremental-sweep cursor token. |

### Installation

```bash
# From the repo root — installs FastAPI service + batch layer + its deps.
pip install ".[batch]"

# Or in a pyproject-native tool:
pip install -e ".[batch]"
```

The `[batch]` extra adds `psycopg2-binary`, `google-api-python-client`, and `google-auth`. The FastAPI service does not require these.

### Running a sweep

Manual run:

```bash
python -m batch.cli --source gdrive --root <drive_folder_id> --parallelism 2
```

Or via the installed script:

```bash
afai-batch-sweep --source gdrive --root <drive_folder_id>
```

Expected output:

```
[done] pushed=5 skipped=0 failed=0 chunks=142 deletions_enqueued=0
```

### Scheduling

The watcher is designed to be invoked on a schedule. Two recommended patterns:

**(i) Cron / systemd timer — simplest.** Runs the CLI every N minutes.

```cron
*/5 * * * * cd /opt/afai-redux && python -m batch.cli --source gdrive --root $DRIVE_FOLDER_ID >> /var/log/afai-batch.log 2>&1
```

**(ii) APScheduler in a long-running process.** Useful if you also want to run other scheduled jobs in the same process, or want in-process observability.

```python
from apscheduler.schedulers.blocking import BlockingScheduler
from batch.ingestor import BatchIngestor
from batch.ledger import IngestionLedger
from batch.sources import GoogleDriveAdapter

scheduler = BlockingScheduler()

@scheduler.scheduled_job("interval", minutes=5)
def sweep():
    runner = BatchIngestor(
        adapter=GoogleDriveAdapter(folder_id=os.environ["DRIVE_FOLDER_ID"]),
        ledger=IngestionLedger(),
    )
    print(runner.sweep())

scheduler.start()
```

Push-based alternatives (Drive `files.watch`, Graph `subscriptions`) are possible but carry operational cost — subscriptions expire, webhooks need a public HTTPS endpoint with validation. Polling via `changes.list` / `delta` at a 5-minute cadence is the blessed default; switch to push only if latency becomes a real complaint.

### Pilot runbook (Google Drive)

One-time setup:

1. Apply the watcher schema:
   `psql ... -f batch/schema.sql`
2. Create a GCP service account, download its JSON key.
3. Share the target Drive folder with the service-account email (Viewer role is enough).
4. Export `BATCH_PG_*`, `GDRIVE_SERVICE_ACCOUNT_JSON`, and `AFAI_INGEST_URL`.
5. Make sure the FastAPI service is reachable from the watcher host and healthy (`curl $AFAI_INGEST_URL/../health`).

First sweep:

```bash
afai-batch-sweep --source gdrive --root <drive_folder_id>
```

Verify:

```sql
SELECT status, count(*) FROM ingest_ledger GROUP BY status;
SELECT file_name, chunks_received, pushed_at FROM ingest_ledger
 ORDER BY pushed_at DESC LIMIT 10;
SELECT count(*) FROM ingest_staging WHERE consumed_at IS NULL;
```

Subsequent sweeps only pick up changed files (dedup via `etag` / `md5Checksum`).

---

## Open questions for developer decision

Two handoff points are intentionally deferred. The batch layer parks its output; a downstream consumer picks it up and writes to PGVector. That consumer's exact shape is a design call your team should make, not hardcode here.

### OQ-1: Upsert handoff — who consumes `ingest_staging`?

The watcher writes full `/ingest` responses (chunks + counts + metadata) into `ingest_staging` with `consumed_at IS NULL`. Someone needs to read these rows, embed each chunk with the tenant's embedding model, write to PGVector (and probably `pdf_documents.ids` per the "Wiring into AeroChat" section), then mark the row consumed.

Options to evaluate:

1. **AeroChat polls `ingest_staging` directly.** Simplest if both services share the same Postgres. AeroChat adds a scheduled task: `SELECT ... WHERE consumed_at IS NULL`, process, `UPDATE ... SET consumed_at = NOW(), consumed_by = 'aerochat'`.
2. **A separate embedder worker in this repo.** New process in `batch/consumer.py` that polls the staging table and calls AeroChat's existing internal embedding/PGVector code as a library. Requires that code to be importable outside AeroChat.
3. **Postgres `LISTEN/NOTIFY`.** Watcher issues `NOTIFY` on insert; AeroChat `LISTEN`s. Near-real-time, no polling, but couples the two services at the notification channel.
4. **AeroChat exposes an `/ingest/chunks` endpoint.** Watcher POSTs each staging row (or batches them) to AeroChat. Removes the shared-DB dependency at the cost of another HTTP hop. Closest to PR #1's original AeroChat-initiated design.
5. **Message queue** (e.g. Redis / RabbitMQ / SQS). Watcher publishes; AeroChat consumes. Adds infrastructure; useful if you expect high volume or need retries across machine restarts.

Recommendation for the pilot: **option 1 or 4**, whichever matches your team's preference for DB-coupling vs. HTTP-coupling.

### OQ-2: Deletion handoff — who consumes `ingest_deletion_queue`?

When the batch layer detects that a Drive file was trashed or hard-deleted, it writes to `ingest_deletion_queue` and flips the corresponding `ingest_ledger` rows to `status='deleted_at_source'`. It does **not** delete from PGVector — that's not its database.

Options to evaluate:

1. **Same consumer as OQ-1.** Whichever component processes `ingest_staging` also polls `ingest_deletion_queue` and runs a `DELETE FROM langchain_pg_embedding WHERE cmetadata->>'doc_id' = <doc_id>` (or equivalent) scoped to the tenant's collection.
2. **AeroChat maintains `pdf_documents.ids`** (already referenced in the "Wiring into AeroChat" section). On deletion, look up the chunk IDs in that row and delete them by ID, which is cheaper than a JSONB filter.
3. **afai-redux adds a `DELETE /ingest/{doc_id}` endpoint** that AeroChat calls. Symmetric with the upsert path. Requires AeroChat to expose its PGVector credentials to afai-redux, which is the reason PR #1 explicitly kept PGVector ownership on AeroChat's side. Probably not worth the coupling.

Recommendation: **option 1 + 2 together** — one consumer for both queues, using `pdf_documents.ids` for fast chunk deletion.

### Other things worth deciding

- **Do we purge stale chunks on re-ingest?** When a file is modified, the watcher pushes a fresh `/ingest` call and stages the new chunks, but nothing automatically deletes the prior version's chunks from PGVector. Two approaches: (a) the consumer in OQ-1 diffs old vs. new chunk IDs on AeroChat's side (the `/ingest` response is deterministic on input, so unchanged content produces identical IDs — this is cheap); or (b) the consumer treats every staging row as a full replace, deleting all prior chunks for that `doc_id` before writing the new ones. Option (a) is more efficient; option (b) is simpler and more robust.
- **Cursor drift recovery.** If `ingest_cursor.cursor_token` is lost or too old (Drive's pageToken has a bounded lifetime), the next sweep fails. Decide whether the watcher should fall back to a full re-listing when this happens (safe, idempotent, expensive on large folders) or alert and halt.
- **Tenant routing.** Today a watcher instance watches one folder and calls one `/ingest` URL. When more co-pilot tenants come online, decide whether each tenant gets its own watcher process (simple, isolated) or one watcher handles many folders with per-folder config (fewer processes, more complex config surface).

---

## File structure (updated)

```
afai-redux/
  app/                         # FastAPI ingestion service
    __init__.py
    main.py                    # /ingest, /health endpoints
    models.py                  # Pydantic request/response — the contract
    ingest/
      __init__.py
      docling_client.py        # HTTP client for docling-serve
      chunker.py               # HybridChunker wrapper
      location.py              # Docling provenance -> ChunkLocation mapping
      chunk_id.py              # Deterministic chunk ID derivation
      pipeline.py              # Orchestrator: convert -> chunk -> respond

  batch/                       # Batch watcher layer (separate concern)
    __init__.py
    ingestor.py                # BatchIngestor — HTTP client of /ingest
    ledger.py                  # IngestionLedger — push-tracking + staging
    schema.sql                 # DDL for ingest_ledger / _staging / _cursor / _deletion_queue
    cli.py                     # `python -m batch.cli` / `afai-batch-sweep`
    sources/
      __init__.py
      base.py                  # SourceAdapter protocol, FileChange, FileRef
      local_folder.py          # LocalFolderAdapter (dev/test)
      google_drive.py          # GoogleDriveAdapter (pilot)
      graph_drive.py           # GraphDriveAdapter (stub — M365 cutover)

  pyproject.toml               # Base service deps + [batch] extra
  Dockerfile                   # FastAPI service container
  docker-compose.yml           # FastAPI + docling-serve locally
  DEPLOYMENT.md                # This document
  afai_agent.py                # LEGACY — retrieval logic, not used, kept for reference
```
