"""
process_claim_payment_router.py
────────────────────────────────
Endpoints / MCP tools:
  process_claim_payment   POST /process_claim_payment
"""

import logging
from fastapi import APIRouter, HTTPException

from process_claim_payment_mcp import handler
from process_claim_payment_mcp.models import ProcessClaimPaymentRequest

log = logging.getLogger(__name__)
router = APIRouter()


@router.post(
    "/process_claim_payment",
    operation_id="process_claim_payment",
    summary="Run full Guidewire financial flow: exposure → reserve → validate → payment",
)
def process_claim_payment(req: ProcessClaimPaymentRequest):
    """
    Executes the complete post-update Guidewire ClaimCenter financial sequence
    for a claim identified by its internal GW claim ID (cc:...):

    1. GET  location-based risk units        → riskUnitId
    2. GET  coverages for that risk unit     → coverageId  (filtered by coverage type code)
    3. GET  claim detail                     → insuredId
    4. POST create exposure                  → exposureId
    5. POST create reserve-set               (amount from claims_master.reserve_amount)
    6. POST validate exposure
    7. POST create check-set / payment       (amount from loss_assessments.net_payable_amount)

    Address fields (tempLocation_Ext, mailingAddress) are sourced from policy_details.
    All currency codes are hardcoded to 'eur' as required.

    Returns a step-by-step result dict including all GW-issued IDs.
    """
    try:
        return handler.process_claim_payment(req.gw_claim_id)
    except Exception as exc:
        log.exception("process_claim_payment error for %s", req.gw_claim_id)
        raise HTTPException(status_code=500, detail=str(exc))
