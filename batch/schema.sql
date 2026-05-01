-- batch/schema.sql
-- ----------------------------------------------------------------------
-- Ledger + staging tables for the batch watcher layer.
--
-- This schema is owned by the batch process. It does NOT include any
-- PGVector tables — embedding and vector storage is AeroChat's concern.
--
-- The tables record:
--   1. `ingest_ledger`         — which source files we've pushed to
--                                 POST /ingest, with dedup state.
--   2. `ingest_staging`        — full /ingest responses (chunks + counts)
--                                 waiting to be consumed downstream.
--   3. `ingest_cursor`         — per-source incremental-sweep cursor.
--   4. `ingest_deletion_queue` — deletion events from the source that
--                                 need developer-decided downstream action
--                                 (see DEPLOYMENT.md §"Open questions").
--
-- Apply once to the Postgres database the batch layer talks to:
--   psql ... -f batch/schema.sql
--
-- Safe to re-run: everything uses IF NOT EXISTS.
-- ----------------------------------------------------------------------


-- ----------------------------------------------------------------------
-- ingest_ledger — what have we already pushed to /ingest?
-- ----------------------------------------------------------------------
-- Used for dedup across sweeps and for deletion reconciliation.
-- One row per (source_type, source_file_id, etag).
--
-- A file being present here as 'pushed' means: we called /ingest, got
-- a response, and wrote it to ingest_staging. It does NOT mean the
-- chunks are in PGVector — that's whoever consumes ingest_staging.
-- ----------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ingest_ledger (
    id                BIGSERIAL   PRIMARY KEY,
    source_type       TEXT        NOT NULL,           -- 'local' | 'gdrive' | 'graph'
    source_root       TEXT        NOT NULL,           -- folder path / drive id
    source_file_id    TEXT        NOT NULL,           -- provider file id
    etag              TEXT,                           -- provider change token
    file_hash         TEXT,                           -- md5/sha from provider if available
    file_name         TEXT        NOT NULL,
    mime_type         TEXT,
    size_bytes        BIGINT,
    modified_time     TIMESTAMPTZ,                    -- provider's last-modified
    doc_id            TEXT        NOT NULL,           -- what we sent to /ingest (usually = source_file_id)
    web_url           TEXT,                           -- human-clickable link
    -- Push outcome
    status            TEXT        NOT NULL,           -- 'pushed' | 'failed' | 'superseded' | 'deleted_at_source'
    ingest_status     TEXT,                           -- from response: 'completed' | 'partial' | 'failed'
    chunks_received   INTEGER,                        -- count from response.counts.chunks_produced
    error             TEXT,                           -- on failure, the error detail
    pushed_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT ingest_ledger_uniq UNIQUE (source_type, source_file_id, etag)
);

CREATE INDEX IF NOT EXISTS idx_ingest_ledger_status
    ON ingest_ledger (status);
CREATE INDEX IF NOT EXISTS idx_ingest_ledger_source_root
    ON ingest_ledger (source_type, source_root, status);
CREATE INDEX IF NOT EXISTS idx_ingest_ledger_source_file
    ON ingest_ledger (source_type, source_file_id);
CREATE INDEX IF NOT EXISTS idx_ingest_ledger_doc_id
    ON ingest_ledger (doc_id);


-- ----------------------------------------------------------------------
-- ingest_staging — chunks returned from /ingest, awaiting consumption.
-- ----------------------------------------------------------------------
-- One row per successful push. Stores the full /ingest response so
-- downstream (AeroChat or a separate embedding worker) has everything
-- needed to embed and write to PGVector.
--
-- HANDOFF OPEN QUESTION: see DEPLOYMENT.md §"Open questions" — who
-- reads this table, when, and by what mechanism (polling worker,
-- listen/notify, shared-DB direct query from AeroChat, etc.).
-- ----------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ingest_staging (
    id                BIGSERIAL   PRIMARY KEY,
    ledger_id         BIGINT      NOT NULL
        REFERENCES ingest_ledger(id) ON DELETE CASCADE,
    doc_id            TEXT        NOT NULL,
    response_status   TEXT        NOT NULL,           -- 'completed' | 'partial' | 'failed'
    chunks            JSONB       NOT NULL,           -- full chunk list from /ingest response
    counts            JSONB,                          -- IngestCounts
    warnings          JSONB,                          -- list[str]
    errors            JSONB,                          -- list[str]
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    consumed_at       TIMESTAMPTZ,                    -- NULL = not yet consumed
    consumed_by       TEXT                            -- caller-supplied identity of consumer
);

CREATE INDEX IF NOT EXISTS idx_ingest_staging_unconsumed
    ON ingest_staging (created_at) WHERE consumed_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_ingest_staging_doc_id
    ON ingest_staging (doc_id);


-- ----------------------------------------------------------------------
-- ingest_deletion_queue — source-side deletion events.
-- ----------------------------------------------------------------------
-- When the batch layer detects a file was removed at the source, it
-- writes here. No action is taken against PGVector — that's also a
-- downstream concern. Rows are marked processed once a consumer handles
-- the deletion.
--
-- HANDOFF OPEN QUESTION: see DEPLOYMENT.md §"Open questions" — who
-- consumes this table and how chunks get removed from PGVector.
-- ----------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ingest_deletion_queue (
    id                BIGSERIAL   PRIMARY KEY,
    source_type       TEXT        NOT NULL,
    source_root       TEXT        NOT NULL,
    source_file_id    TEXT        NOT NULL,
    doc_id            TEXT        NOT NULL,           -- what was sent to /ingest originally
    file_name         TEXT,
    detected_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    processed_at      TIMESTAMPTZ,                    -- NULL = not yet processed
    processed_by      TEXT
);

CREATE INDEX IF NOT EXISTS idx_deletion_queue_unprocessed
    ON ingest_deletion_queue (detected_at) WHERE processed_at IS NULL;


-- ----------------------------------------------------------------------
-- ingest_cursor — per-source incremental-sweep cursor.
-- ----------------------------------------------------------------------
--   local   → ISO timestamp of last sweep
--   gdrive  → Drive changes pageToken
--   graph   → Graph deltaLink
-- ----------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS ingest_cursor (
    source_type       TEXT        NOT NULL,
    source_root       TEXT        NOT NULL,
    cursor_token      TEXT,
    last_sweep_at     TIMESTAMPTZ,
    PRIMARY KEY (source_type, source_root)
);
