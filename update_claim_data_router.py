"""
update_claim_data_router.py
────────────────────────────
Endpoints / MCP tools:
  update_claim_data   POST /update_claim_data
"""

import logging
from fastapi import APIRouter, HTTPException

from update_claim_data_mcp import handler
from update_claim_data_mcp.models import UpdateClaimDataRequest

log = logging.getLogger(__name__)
router = APIRouter()


@router.post(
    "/update_claim_data",
    operation_id="update_claim_data",
    summary="Sync claim data from local DB to Guidewire ClaimCenter via PATCH",
)
def update_claim_data(req: UpdateClaimDataRequest):
    """
    Fetches the claim's loss_type, address fields (from policy_details), and
    area_affected / occupancy_at_loss (from fnol_submissions) from the local DB,
    then PATCHes the corresponding Guidewire ClaimCenter claim record with:

    - lossCause        — derived from claims.loss_type (only valid GW codes sent)
    - lossLocation     — from policy_details address fields
    - DwellingIncident — description, room damages, occupancy type

    Only values that map to Guidewire-allowed enum codes are included in the
    payload; un-mappable values are silently omitted rather than causing an error.

    Returns the GW API response plus a summary of what was sent.
    """
    try:
        return handler.update_claim_data(req.gw_claim_id)
    except Exception as exc:
        log.exception("update_claim_data error for %s", req.gw_claim_id)
        raise HTTPException(status_code=500, detail=str(exc))
