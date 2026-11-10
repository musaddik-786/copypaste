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

# Either set GW_AUTHORIZATION directly (a full "Basic <base64>" / "Bearer <token>"
# header value), or set GW_USERNAME + GW_PASSWORD and let requests build the Basic
# auth header the same way Postman's Authorization tab does.
GW_AUTH = os.environ.get("GW_AUTHORIZATION", "")
GW_USERNAME = os.environ.get("GW_USERNAME", "")
GW_PASSWORD = os.environ.get("GW_PASSWORD", "")

REQUEST_TIMEOUT = int(os.environ.get("GW_TIMEOUT_SECONDS", "30"))

log.info(
    "Guidewire client configured | base_url=%s | auth_mode=%s | username=%r",
    CC_BASE_URL,
    "basic" if (GW_USERNAME and not GW_AUTH) else ("header" if GW_AUTH else "NONE (no credentials set!)"),
    GW_USERNAME or None,
)


def _cc_get(uri: str, extra_headers: Optional[dict] = None, params: Optional[dict] = None) -> dict:
    url = CC_BASE_URL + uri
    headers = {
        "accept": "application/json",
        "Content-Type": "application/json",
    }
    if GW_AUTH:
        headers["authorization"] = GW_AUTH
    if extra_headers:
        headers.update(extra_headers)

    # Prefer GW_USERNAME/GW_PASSWORD (requests builds the Basic auth header
    # itself, exactly like Postman's Authorization tab does) unless a raw
    # GW_AUTHORIZATION header value was supplied instead.
    auth = (GW_USERNAME, GW_PASSWORD) if (GW_USERNAME and not GW_AUTH) else None

    log.info(
        "GW CC GET %s | filter_header=%r | filter_param=%r | auth_mode=%s",
        url, headers.get("filter"), (params or {}).get("filter"),
        "basic" if auth else ("header" if GW_AUTH else "none"),
    )
    resp = requests.get(url, headers=headers, params=params, auth=auth, timeout=REQUEST_TIMEOUT)
    _raise_for_status(resp, "CC GET", uri)
    body = resp.json()
    log.info("GW CC GET %s -> count=%s", uri, body.get("count") if isinstance(body, dict) else "n/a")
    return body


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

    Sends the `claimNumber:eq:<value>` filter as both a `filter` header and
    a `filter` query parameter (the documented ClaimCenter Cloud API
    syntax), but does NOT trust the server to apply it — on this
    environment, ClaimCenter silently ignores the filter and always returns
    its full (unfiltered) claims page regardless of what's sent. So the
    actual matching is done client-side against whatever `data` comes back.
    """
    filter_value = f"claimNumber:eq:{claim_number}"
    resp = _cc_get(
        "/claim/v1/claims",
        extra_headers={"filter": filter_value},
        params={"filter": filter_value, "pageSize": 1000},
    )
    all_claims = resp.get("data", [])
    matches = [
        c for c in all_claims
        if (c.get("attributes") or {}).get("claimNumber") == claim_number
    ]
    log.info(
        "Client-side filter: %d/%d claims matched claimNumber=%r",
        len(matches), len(all_claims), claim_number,
    )
    return {**resp, "data": matches, "count": len(matches)}


def list_claims(page_size: int = 10) -> dict:
    """
    Fetches an unfiltered page of claims — useful for sanity-checking that
    auth/connectivity works and for finding real claim numbers to test with.

    Uses: GET /claim/v1/claims
    """
    return _cc_get("/claim/v1/claims", params={"pageSize": page_size})


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
            "status": (attrs.get("state") or {}).get("name", attrs.get("status", "Unknown")),
            "loss_cause": (attrs.get("lossCause") or {}).get("name", attrs.get("lossCause", "")),
            "loss_type": (attrs.get("lossType") or {}).get("name", attrs.get("lossType", "")),
            "loss_description": attrs.get("description", ""),
            "policy_number": attrs.get("policyNumber", (attrs.get("policy") or {}).get("policyNumber", "")),
            "insured_name": (attrs.get("insured") or attrs.get("primaryInsured") or {}).get("displayName", ""),
            "loss_location": (attrs.get("lossLocation") or {}).get("displayName", ""),
            "adjuster": (attrs.get("assignedUser") or attrs.get("adjuster") or {}).get("displayName", ""),
            "raw": gw_response,
        }

        log.info("Parsed FNOL/claim data: %s", {k: v for k, v in parsed.items() if k != "raw"})
        return parsed

    except Exception as exc:
        log.exception("Failed to parse Guidewire FNOL/claim response")
        raise ValueError(f"Unable to parse Guidewire response: {str(exc)}")
