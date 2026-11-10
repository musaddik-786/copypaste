"""
guidewire_client.py
────────────────────
HTTP calls to the Guidewire ClaimCenter REST API for retrieving FNOL /
claim data.

ClaimCenter base: https://cc-sandbox-gwcpdev.hexaware.zeta1-andromeda.guidewire.net/rest
"""

import logging
import os
from typing import Optional

import requests
from dotenv import load_dotenv

load_dotenv()

log = logging.getLogger(__name__)

CC_BASE_URL = os.environ.get(
    "GW_CC_BASE_URL",
    "https://cc-sandbox-gwcpdev.hexaware.zeta1-andromeda.guidewire.net/rest",
)
GW_AUTH = os.environ.get("GW_AUTHORIZATION", "")

REQUEST_TIMEOUT = int(os.environ.get("GW_TIMEOUT_SECONDS", "30"))


def _cc_get(uri: str, extra_headers: Optional[dict] = None) -> dict:
    url = CC_BASE_URL + uri
    headers = {
        "accept": "application/json",
        "Content-Type": "application/json",
        "authorization": GW_AUTH,
    }
    if extra_headers:
        headers.update(extra_headers)

    log.info("GW CC GET %s", url)
    resp = requests.get(url, headers=headers, timeout=REQUEST_TIMEOUT)
    _raise_for_status(resp, "CC GET", uri)
    return resp.json()


def _raise_for_status(resp: requests.Response, method: str, uri: str):
    if not resp.ok:
        log.error(
            "Guidewire %s %s -> HTTP %s: %s",
            method, uri, resp.status_code, resp.text[:500],
        )
        resp.raise_for_status()


# -- ClaimCenter -- FNOL / Claim lookup -----------------------------------

def get_fnol_data_by_claim_number(claim_number: str) -> dict:
    """
    Fetches claim/FNOL data from Guidewire ClaimCenter for a given claim
    number.

    Uses: GET /claim/v1/claims
    Filtered via the ClaimCenter Cloud API header-based filter syntax, e.g.:
        filter: claimNumber:eq:000-00-004122
    """
    filter_value = f"claimNumber:eq:{claim_number}"
    return _cc_get("/claim/v1/claims", extra_headers={"filter": filter_value})


# -- Response parsers -------------------------------------------------------

def parse_fnol_data(gw_response: dict) -> Optional[dict]:
    """
    Extracts a flat, normalised FNOL/claim dict from a Guidewire
    GET /claim/v1/claims response. Returns None if no claim was found.
    """
    try:
        data_list = gw_response.get("data", [])
        if not data_list:
            log.warning("No claim data returned from Guidewire for this claim number")
            return None

        claim = data_list[0]
        attrs = claim.get("attributes", {})

        parsed = {
            "claim_id": claim.get("id", ""),
            "claim_number": attrs.get("claimNumber", ""),
            "loss_date": attrs.get("lossDate", ""),
            "report_date": attrs.get("reportedDate", ""),
            "status": attrs.get("state", attrs.get("status", "Unknown")),
            "loss_cause": (attrs.get("lossCause") or {}).get("name", attrs.get("lossCause", "")),
            "loss_type": (attrs.get("lossType") or {}).get("name", attrs.get("lossType", "")),
            "loss_description": attrs.get("description", ""),
            "policy_number": (attrs.get("policy") or {}).get("policyNumber", ""),
            "insured_name": (attrs.get("primaryInsured") or {}).get("displayName", ""),
            "loss_location": (attrs.get("lossLocation") or {}).get("displayName", ""),
            "adjuster": (attrs.get("adjuster") or {}).get("displayName", ""),
            "raw": gw_response,
        }

        log.info("Parsed FNOL/claim data: %s", {k: v for k, v in parsed.items() if k != "raw"})
        return parsed

    except Exception as exc:
        log.exception("Failed to parse Guidewire FNOL/claim response")
        raise ValueError(f"Unable to parse Guidewire response: {str(exc)}")
