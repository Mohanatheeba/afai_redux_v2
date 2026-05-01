"""LocalFolderAdapter — walks a local directory.

Primarily a dev/test fixture. The production pilot uses Google Drive.

Cursor is an ISO timestamp of sweep start; a file is "changed" if its
mtime is newer than the stored cursor. Deletions are detected by
set-diff against `known_ids` supplied by the orchestrator.
"""

from __future__ import annotations

import hashlib
import os
import shutil
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable, List, Optional

from .base import CHANGE_DELETE, CHANGE_UPSERT, FileChange, FileRef


class LocalFolderAdapter:
    source_type = "local"

    def __init__(self, folder: Path, recursive: bool = True) -> None:
        self.folder = Path(folder).resolve()
        self.recursive = recursive
        self.source_root = str(self.folder)
        self._sweep_started_at: Optional[datetime] = None

    def list_changes(
        self,
        since_cursor: Optional[str],
        known_ids: Iterable[str] = (),
    ) -> List[FileChange]:
        # Record sweep start BEFORE listing so we never miss files created mid-sweep.
        self._sweep_started_at = datetime.now(timezone.utc)
        since = _parse_iso(since_cursor)
        pattern = "**/*" if self.recursive else "*"

        seen_ids: set[str] = set()
        changes: List[FileChange] = []
        for p in self.folder.glob(pattern):
            if not p.is_file():
                continue
            stat = p.stat()
            mtime = datetime.fromtimestamp(stat.st_mtime, tz=timezone.utc)
            file_id = str(p.resolve())
            seen_ids.add(file_id)

            if since and mtime <= since:
                continue  # unchanged since last sweep

            changes.append(
                FileChange(
                    kind=CHANGE_UPSERT,
                    ref=FileRef(
                        id=file_id,
                        name=p.name,
                        size=stat.st_size,
                        etag=str(int(mtime.timestamp())),
                        hash=_sha256(p),
                        modified_time=mtime,
                        web_url=p.as_uri(),
                    ),
                )
            )

        # Set-diff reconciliation: anything the ledger knew about but is
        # no longer on disk is a deletion.
        for gone_id in set(known_ids) - seen_ids:
            changes.append(
                FileChange(
                    kind=CHANGE_DELETE,
                    ref=FileRef(id=gone_id, name=Path(gone_id).name),
                )
            )

        return changes

    def get_new_cursor(self) -> Optional[str]:
        return self._sweep_started_at.isoformat() if self._sweep_started_at else None

    def download_to_temp(self, ref: FileRef) -> Path:
        """Copy the source file to a temp path so the orchestrator can unlink
        freely without touching the source."""
        fd, tmp = tempfile.mkstemp(suffix=Path(ref.name).suffix)
        os.close(fd)
        shutil.copyfile(Path(ref.id), tmp)
        return Path(tmp)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _parse_iso(s: Optional[str]) -> Optional[datetime]:
    if not s:
        return None
    try:
        return datetime.fromisoformat(s)
    except ValueError:
        return None


def _sha256(p: Path, chunk: int = 1 << 20) -> str:
    h = hashlib.sha256()
    with p.open("rb") as f:
        while True:
            b = f.read(chunk)
            if not b:
                break
            h.update(b)
    return h.hexdigest()
