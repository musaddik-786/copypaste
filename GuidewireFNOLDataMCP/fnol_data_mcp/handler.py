"""
handler.py
──────────
Business logic for the gw_get_fnol_data MCP tool.
"""

import logging

from fnol_data_mcp import guidewire_client as gw

log = logging.getLogger(__name__)


def get_fnol_data(claim_number: str) -> dict:
    """
    Looks up FNOL/claim data in Guidewire ClaimCenter by claim number.
    Returns found=True with the parsed claim data, or found=False with a
    message if no claim matched.
    """
    gw_response = gw.get_fnol_data_by_claim_number(claim_number)
    parsed = gw.parse_fnol_data(gw_response)

    if parsed is None:
        return {
            "found": False,
            "claim_number": claim_number,
            "message": f"No claim found in Guidewire for claim number '{claim_number}'",
            "raw": gw_response,
        }

    return {
        "found": True,
        "claim_number": claim_number,
        "data": parsed,
    }


def list_claims(page_size: int = 10) -> dict:
    """
    Debug helper: fetches an unfiltered page of claims from Guidewire
    ClaimCenter to sanity-check connectivity/auth and to find real claim
    numbers to test gw_get_fnol_data with.
    """
    gw_response = gw.list_claims(page_size=page_size)
    claim_numbers = [
        (item.get("attributes", {}) or {}).get("claimNumber")
        for item in gw_response.get("data", [])
    ]
    return {
        "count": gw_response.get("count"),
        "claim_numbers": claim_numbers,
        "raw": gw_response,
    }
