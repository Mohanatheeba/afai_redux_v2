"""GoogleDriveAdapter — pilot source.

Watches a Google Drive folder that the customer uploads documents into.

Auth
----
Service account JSON whose email has been granted Viewer access to the
target folder. Path provided via env var ``GDRIVE_SERVICE_ACCOUNT_JSON``.

Incremental sweep model
-----------------------
  * First sweep: full recursive listing of the folder. Seeds a
    ``startPageToken`` for subsequent incremental sweeps.
  * Subsequent sweeps: call Drive's ``changes.list`` with the saved
    pageToken, then filter to items whose parent is inside our folder
    subtree. Drive's change feed is drive-wide, so parent filtering is
    mandatory.

Deletion handling
-----------------
Drive surfaces deletions natively via the change feed:
  * ``ch["removed"] is True``            → hard-delete or access revoked
  * ``ch["file"]["trashed"] is True``    → moved to Trash
Both map to ``FileChange(kind='delete')`` events carrying just the file id.
The orchestrator ignores ids the ledger has never seen, so it's safe to
emit deletes without the parent filter (removed items don't retain parent
metadata anyway).

Reference:
  https://developers.google.com/drive/api/guides/manage-changes

Dependencies (add to pyproject.toml when this adapter is activated):
  google-api-python-client
  google-auth
"""

from __future__ import annotations

import os
import tempfile
from datetime import datetime
from pathlib import Path
from typing import Iterable, List, Optional, Set

from .base import CHANGE_DELETE, CHANGE_UPSERT, FileChange, FileRef


# Google SDK imports are deferred so this module can be imported on systems
# without google libs installed (e.g. CI that only tests LocalFolderAdapter).
def _build_service():
    from google.oauth2 import service_account
    from googleapiclient.discovery import build

    sa_path = os.getenv("GDRIVE_SERVICE_ACCOUNT_JSON")
    if not sa_path:
        raise RuntimeError(
            "GDRIVE_SERVICE_ACCOUNT_JSON env var is not set. "
            "Point it at the service-account JSON key file."
        )
    creds = service_account.Credentials.from_service_account_file(
        sa_path, scopes=["https://www.googleapis.com/auth/drive.readonly"]
    )
    return build("drive", "v3", credentials=creds, cache_discovery=False)


class GoogleDriveAdapter:
    source_type = "gdrive"

    # Every field here is metadata we actually use.
    FIELDS = (
        "id,name,mimeType,size,md5Checksum,modifiedTime,"
        "webViewLink,parents,trashed"
    )

    def __init__(self, folder_id: str) -> None:
        self.folder_id = folder_id
        self.source_root = folder_id
        self._service = None
        self._new_page_token: Optional[str] = None
        self._descendants_cache: Optional[Set[str]] = None

    @property
    def service(self):
        if self._service is None:
            self._service = _build_service()
        return self._service

    # ------------------------------------------------------------------
    # SourceAdapter contract
    # ------------------------------------------------------------------
    def list_changes(
        self,
        since_cursor: Optional[str],
        known_ids: Iterable[str] = (),
    ) -> List[FileChange]:
        # known_ids is ignored — Drive's change feed is authoritative for
        # both upserts and deletes.
        del known_ids
        if since_cursor:
            return self._list_via_changes(page_token=since_cursor)
        # First-ever sweep: full listing and seed cursor for next time.
        self._new_page_token = self._get_start_page_token()
        return self._list_folder_recursive()

    def get_new_cursor(self) -> Optional[str]:
        return self._new_page_token

    def download_to_temp(self, ref: FileRef) -> Path:
        from googleapiclient.http import MediaIoBaseDownload

        request = self.service.files().get_media(fileId=ref.id)
        fd, tmp = tempfile.mkstemp(suffix=Path(ref.name).suffix)
        os.close(fd)
        with open(tmp, "wb") as fh:
            downloader = MediaIoBaseDownload(fh, request)
            done = False
            while not done:
                _, done = downloader.next_chunk()
        return Path(tmp)

    # ------------------------------------------------------------------
    # Internals
    # ------------------------------------------------------------------
    def _get_start_page_token(self) -> str:
        resp = self.service.changes().getStartPageToken().execute()
        return resp["startPageToken"]

    def _list_folder_recursive(self) -> List[FileChange]:
        """Depth-first listing of the folder, emitted as CHANGE_UPSERT events."""
        out: List[FileChange] = []
        stack = [self.folder_id]
        while stack:
            parent = stack.pop()
            page_token = None
            while True:
                resp = self.service.files().list(
                    q=f"'{parent}' in parents and trashed = false",
                    fields=f"nextPageToken, files({self.FIELDS})",
                    pageToken=page_token,
                    pageSize=1000,
                    supportsAllDrives=True,
                    includeItemsFromAllDrives=True,
                ).execute()
                for f in resp.get("files", []):
                    if f.get("mimeType") == "application/vnd.google-apps.folder":
                        stack.append(f["id"])
                        continue
                    out.append(FileChange(kind=CHANGE_UPSERT, ref=_to_fileref(f)))
                page_token = resp.get("nextPageToken")
                if not page_token:
                    break
        return out

    def _list_via_changes(self, page_token: str) -> List[FileChange]:
        """Pull the drive-wide change feed, emit upserts + deletes.

        Upserts are filtered to files under our folder subtree. Delete
        events are NOT filtered — we don't have parent info for a removed
        file, so we emit and let the orchestrator skip any id that was
        never in the ledger.
        """
        out: List[FileChange] = []
        descendants = self._descendant_folder_ids()
        token: Optional[str] = page_token

        while token:
            resp = self.service.changes().list(
                pageToken=token,
                fields=(
                    "nextPageToken, newStartPageToken, "
                    f"changes(fileId, removed, file({self.FIELDS}))"
                ),
                pageSize=1000,
                restrictToMyDrive=False,
                supportsAllDrives=True,
                includeItemsFromAllDrives=True,
            ).execute()

            for ch in resp.get("changes", []):
                f = ch.get("file")

                # --- Deletion paths -------------------------------------
                if ch.get("removed"):
                    fid = ch.get("fileId")
                    if fid:
                        out.append(
                            FileChange(
                                kind=CHANGE_DELETE,
                                ref=FileRef(id=fid, name=""),
                            )
                        )
                    continue
                if f and f.get("trashed"):
                    out.append(
                        FileChange(
                            kind=CHANGE_DELETE,
                            ref=FileRef(id=f["id"], name=f.get("name", "")),
                        )
                    )
                    continue

                # --- Upsert paths ---------------------------------------
                if not f:
                    continue
                if f.get("mimeType") == "application/vnd.google-apps.folder":
                    continue
                parents = set(f.get("parents") or [])
                if not (parents & descendants):
                    continue
                out.append(FileChange(kind=CHANGE_UPSERT, ref=_to_fileref(f)))

            token = resp.get("nextPageToken")
            if "newStartPageToken" in resp:
                self._new_page_token = resp["newStartPageToken"]
                break

        return out

    def _descendant_folder_ids(self) -> Set[str]:
        """Set of folder ids under self.folder_id; used to filter the change feed.

        Cached per-instance, rebuilt each sweep to pick up new subfolders.
        """
        if self._descendants_cache is not None:
            return self._descendants_cache

        ids: Set[str] = {self.folder_id}
        stack = [self.folder_id]
        while stack:
            parent = stack.pop()
            page_token = None
            while True:
                resp = self.service.files().list(
                    q=(
                        f"'{parent}' in parents and trashed = false "
                        "and mimeType = 'application/vnd.google-apps.folder'"
                    ),
                    fields="nextPageToken, files(id)",
                    pageToken=page_token,
                    pageSize=1000,
                    supportsAllDrives=True,
                    includeItemsFromAllDrives=True,
                ).execute()
                for f in resp.get("files", []):
                    if f["id"] not in ids:
                        ids.add(f["id"])
                        stack.append(f["id"])
                page_token = resp.get("nextPageToken")
                if not page_token:
                    break

        self._descendants_cache = ids
        return ids


def _to_fileref(f: dict) -> FileRef:
    modified = f.get("modifiedTime")
    mtime = (
        datetime.fromisoformat(modified.replace("Z", "+00:00"))
        if modified
        else None
    )
    size = int(f["size"]) if f.get("size") else None
    return FileRef(
        id=f["id"],
        name=f.get("name", "unknown"),
        mime_type=f.get("mimeType"),
        size=size,
        # md5Checksum is perfect as etag for binary files; fall back to
        # modifiedTime for types Drive doesn't hash (rare for PDFs/XLSX).
        etag=f.get("md5Checksum") or f.get("modifiedTime"),
        hash=f.get("md5Checksum"),
        modified_time=mtime,
        web_url=f.get("webViewLink"),
    )
