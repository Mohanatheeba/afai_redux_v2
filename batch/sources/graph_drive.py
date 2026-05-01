"""GraphDriveAdapter — Microsoft 365 SharePoint / OneDrive via Graph API.

PRODUCTION STUB. Not implemented — exists so the orchestrator, ledger,
and CLI can all be built against the final interface today, with the
M365 cutover a localized change later.

Implementation plan (for the developer wiring this up):

1. Auth — client-credentials flow via MSAL:

       import msal
       app = msal.ConfidentialClientApplication(
           client_id=GRAPH_CLIENT_ID,
           client_credential=GRAPH_CLIENT_SECRET,
           authority=f"https://login.microsoftonline.com/{GRAPH_TENANT_ID}",
       )
       token = app.acquire_token_for_client(
           scopes=["https://graph.microsoft.com/.default"]
       )["access_token"]

   Entra ID app registration requires (application permission,
   admin-consented):

     - Files.Read.All       for OneDrive-for-Business
     - Sites.Read.All       for SharePoint document libraries

2. Enumeration — delta query:

       GET /drives/{drive_id}/root/delta

   Response contains items plus either ``@odata.nextLink`` (more pages
   this call) or ``@odata.deltaLink`` (save this as the cursor). On the
   next sweep, call the stored deltaLink and you get only what changed.

3. Deletion handling — delta returns deleted items as:

       { "id": "...", "deleted": { "state": "deleted" }, "name": "...", ... }

   When an item has a ``deleted`` facet, emit
   ``FileChange(kind=CHANGE_DELETE, ref=FileRef(id=item["id"], name=item.get("name", "")))``.
   Like Drive, ``known_ids`` can be ignored — delta is authoritative.

4. Download:

       GET /drives/{drive_id}/items/{item_id}/content   (302 to pre-signed URL)

   Follow the redirect and stream bytes to tempfile.

5. Dedup signal — each driveItem includes an ``eTag``. Use it as
   ``FileRef.etag``. ``file.hashes.quickXorHash`` (OneDrive) or
   ``sha1Hash`` (SharePoint) populate ``FileRef.hash`` when present.

Env vars (when implemented):
  GRAPH_TENANT_ID
  GRAPH_CLIENT_ID
  GRAPH_CLIENT_SECRET
  GRAPH_DRIVE_ID
"""

from __future__ import annotations

from pathlib import Path
from typing import Iterable, List, Optional

from .base import FileChange, FileRef


class GraphDriveAdapter:
    source_type = "graph"

    def __init__(self, drive_id: str) -> None:
        self.drive_id = drive_id
        self.source_root = drive_id

    def list_changes(
        self,
        since_cursor: Optional[str],
        known_ids: Iterable[str] = (),
    ) -> List[FileChange]:
        raise NotImplementedError(
            "GraphDriveAdapter is a production stub. Implement delta query "
            "against /drives/{drive_id}/root/delta — see module docstring. "
            "Emit CHANGE_UPSERT for items without a `deleted` facet and "
            "CHANGE_DELETE for those with one."
        )

    def get_new_cursor(self) -> Optional[str]:
        raise NotImplementedError

    def download_to_temp(self, ref: FileRef) -> Path:
        raise NotImplementedError
