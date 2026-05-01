"""Source adapter contract.

An adapter turns a document source (Google Drive folder, local directory,
M365 SharePoint/OneDrive drive) into a stream of `FileChange` events that
the batch orchestrator can act on.

The adapter is responsible for:
  - enumerating new or modified files since the last sweep (`kind='upsert'`);
  - surfacing deletions (`kind='delete'`) when the provider exposes them;
  - producing a cursor token the ledger can persist for incremental sweeps;
  - downloading file bytes to a temp path on demand.

Adapters do NOT chunk, embed, or call the FastAPI service — that's the
orchestrator's job.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Iterable, List, Optional, Protocol


CHANGE_UPSERT = "upsert"   # new or modified file — needs (re)ingestion
CHANGE_DELETE = "delete"   # file removed/trashed at the source


@dataclass
class FileRef:
    """Provider-agnostic reference to a file under observation.

    For delete events, only `id` (and usually `name`) is guaranteed to be
    populated — providers often don't return metadata for removed items.
    """

    id: str                                   # provider-unique id (drive fileId / graph itemId / abs path)
    name: str                                 # filename with extension (may be "" for deletes)
    mime_type: Optional[str] = None
    size: Optional[int] = None
    etag: Optional[str] = None                # provider change signal (md5Checksum, eTag, mtime)
    hash: Optional[str] = None                # md5/sha from provider if available
    modified_time: Optional[datetime] = None
    web_url: Optional[str] = None             # human-clickable link (flows into request metadata)
    extra_metadata: dict = field(default_factory=dict)


@dataclass
class FileChange:
    """A single change event emitted by an adapter."""

    kind: str          # CHANGE_UPSERT | CHANGE_DELETE
    ref: FileRef


class SourceAdapter(Protocol):
    """Minimal contract every source implementation must satisfy."""

    source_type: str          # 'local' | 'gdrive' | 'graph' — ledger routing key
    source_root: str          # folder path / drive id — cursor and known-ids key

    def list_changes(
        self,
        since_cursor: Optional[str],
        known_ids: Iterable[str] = (),
    ) -> List[FileChange]:
        """Return change events since the last cursor.

        First call (cursor is None) should return the current inventory as
        upserts AND internally seed a fresh cursor that `get_new_cursor()`
        will return after the sweep completes.

        `known_ids` is the set of source_file_ids the ledger currently
        believes are in a 'pushed' state under this root. Adapters that
        expose deletions natively (Drive changes API, Graph delta) ignore
        it. Adapters without a native delete signal (local folders) use
        it to reconcile: any id in `known_ids` that is no longer present
        in the source is emitted as a CHANGE_DELETE event.
        """
        ...

    def get_new_cursor(self) -> Optional[str]:
        """Cursor token to persist after a successful sweep."""
        ...

    def download_to_temp(self, ref: FileRef) -> Path:
        """Download file bytes locally and return the temp path.

        Only called for CHANGE_UPSERT events. The caller is responsible
        for unlinking the returned path.
        """
        ...
