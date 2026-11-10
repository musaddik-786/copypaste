"""
fnol_data_router.py
────────────────────
Endpoints / MCP tools:
  gw_get_fnol_data   POST /gw_get_fnol_data
"""

import logging
from fastapi import APIRouter, HTTPException

from fnol_data_mcp import handler
from fnol_data_mcp.models import GetFnolDataRequest

log = logging.getLogger(__name__)
router = APIRouter()


@router.post(
    "/gw_get_fnol_data",
    operation_id="gw_get_fnol_data",
    summary="Fetch FNOL/claim data from Guidewire ClaimCenter by claim number",
)
def gw_get_fnol_data(req: GetFnolDataRequest):
    """
    Looks up a claim in Guidewire ClaimCenter using the claim number
    (GET /claim/v1/claims, filtered via the `filter: claimNumber:eq:<value>`
    header). Returns found=True with claim details, or found=False with a
    message if no claim matched.
    """
    try:
        return handler.get_fnol_data(req.claim_number)
    except Exception as e:
        log.exception("gw_get_fnol_data error")
        raise HTTPException(status_code=500, detail=str(e))
