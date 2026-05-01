"""CLI entry for running a batch sweep.

Usage:
    python -m batch.cli --source gdrive --root <folder_id>
    python -m batch.cli --source local  --root /path/to/folder

Env vars:
    AFAI_INGEST_URL              URL of the FastAPI /ingest endpoint
                                 (default: http://localhost:8000/ingest)
    AFAI_INGEST_TIMEOUT          Request timeout in seconds (default: 300)

    BATCH_PG_HOST, BATCH_PG_PORT, BATCH_PG_DB,
    BATCH_PG_USER, BATCH_PG_PASSWORD
                                 Postgres connection for the ledger / staging.

    GDRIVE_SERVICE_ACCOUNT_JSON  Path to Google service-account JSON
                                 (only needed for --source gdrive)
"""

from __future__ import annotations

import argparse
import logging
import sys
from pathlib import Path

from batch.ingestor import BatchIngestor
from batch.ledger import IngestionLedger
from batch.sources import GoogleDriveAdapter, LocalFolderAdapter, SourceAdapter


def main() -> int:
    parser = argparse.ArgumentParser(description="Run one batch ingestion sweep.")
    parser.add_argument(
        "--source",
        choices=["local", "gdrive"],
        required=True,
        help="Where to watch for documents.",
    )
    parser.add_argument(
        "--root",
        required=True,
        help="Folder path (local) or Drive folder id (gdrive).",
    )
    parser.add_argument(
        "--parallelism",
        type=int,
        default=2,
        help="Max concurrent /ingest calls (default: 2).",
    )
    parser.add_argument(
        "--log-level",
        default="INFO",
        choices=["DEBUG", "INFO", "WARNING", "ERROR"],
    )
    args = parser.parse_args()

    logging.basicConfig(
        level=getattr(logging, args.log_level),
        format="%(asctime)s %(levelname)s %(name)s: %(message)s",
    )

    adapter: SourceAdapter
    if args.source == "local":
        adapter = LocalFolderAdapter(Path(args.root))
    elif args.source == "gdrive":
        adapter = GoogleDriveAdapter(folder_id=args.root)
    else:  # pragma: no cover — argparse guards this
        print(f"unsupported source: {args.source}", file=sys.stderr)
        return 2

    runner = BatchIngestor(
        adapter=adapter,
        ledger=IngestionLedger(),
        parallelism=args.parallelism,
    )
    report = runner.sweep()
    print(f"[done] {report}")
    return 1 if report.failed else 0


if __name__ == "__main__":
    sys.exit(main())
