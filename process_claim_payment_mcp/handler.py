"""
handler.py — Process Claim Payment
────────────────────────────────────
Executes the full post-update financial flow against Guidewire ClaimCenter:

  Step 1 — GET  location-based risk units        → riskUnitId
  Step 2 — GET  coverages for that risk unit      → coverageId
  Step 3 — GET  claim detail                      → insuredId
  Step 4 — POST create exposure                   → exposureId
  Step 5 — POST create reserve-set
  Step 6 — POST validate exposure
  Step 7 — POST create check-set (payment)

DB sources:
  claims          → gw_claim_id, short_description, policyholder_name, loss_type
  policy_details  → address fields (addressLine1, city, state, country, postal_code)
  claims_master   → reserve_amount (→ reserve transactionAmount)
  loss_assessments → net_payable_amount (→ payment transactionAmount, fallback: reserve_amount)
"""

import logging
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "common"))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))

from db import get_db_connection, row_to_dict  # noqa: E402
from policy_coverage_mcp import guidewire_client  # noqa: E402
from update_claim_data_mcp.handler import _map_state  # reuse state abbreviation mapper

log = logging.getLogger(__name__)

# Hardcoded GW constants (as specified)
COVERAGE_TYPE_CODE = "z26h4fbq18l81e5n478v5v07mj8"
CURRENCY = "eur"


# ── DB fetch ───────────────────────────────────────────────────────────────────

def _fetch_data(gw_claim_id: str) -> tuple:
    """
    Returns (claim, policy, claims_master_row, loss_assessment_row).
    Any may be None if not found.
    """
    conn = get_db_connection()
    try:
        cur = conn.cursor()

        cur.execute("SELECT * FROM claims WHERE gw_claim_id = %s", (gw_claim_id,))
        claim = row_to_dict(cur.fetchone())
        if not claim:
            return None, None, None, None

        policy = None
        cm = None
        la = None
        policy_number = claim.get("policy_number")

        if policy_number:
            cur.execute(
                "SELECT * FROM policy_details WHERE policy_number = %s",
                (policy_number,),
            )
            policy = row_to_dict(cur.fetchone())

            cur.execute(
                "SELECT * FROM claims_master WHERE claim_number = %s",
                (claim.get("claim_number"),),
            )
            cm = row_to_dict(cur.fetchone())

            cur.execute(
                """
                SELECT * FROM loss_assessments
                WHERE claim_number = %s
                ORDER BY created_at DESC
                LIMIT 1
                """,
                (claim.get("claim_number"),),
            )
            la = row_to_dict(cur.fetchone())

        return claim, policy, cm, la
    finally:
        conn.close()


# ── Address builder (shared for tempLocation_Ext and mailingAddress) ───────────

def _build_address(policy: dict) -> dict:
    """Builds a GW address block from policy_details columns."""
    addr = {}
    if policy:
        if policy.get("policy_address"):
            addr["addressLine1"] = policy["policy_address"]
        if policy.get("city"):
            addr["city"] = policy["city"]
        addr["country"] = policy.get("country") or "US"
        if policy.get("postal_code"):
            addr["postalCode"] = policy["postal_code"]
        state_abbrev = _map_state(policy.get("state") or "")
        if state_abbrev:
            addr["state"] = {"code": state_abbrev}
    return addr


# ── Step helpers ───────────────────────────────────────────────────────────────

def _get_risk_unit_id(gw_claim_id: str) -> str:
    resp = guidewire_client.get_location_risk_units(gw_claim_id)
    items = resp.get("data") or []
    if not items:
        raise ValueError("No location-based risk units returned for claim")
    return items[0]["attributes"]["id"]


def _get_coverage_id(gw_claim_id: str, risk_unit_id: str) -> str:
    resp = guidewire_client.get_risk_unit_coverages(gw_claim_id, risk_unit_id)
    items = resp.get("data") or []
    for item in items:
        attrs = item.get("attributes") or {}
        if (attrs.get("coverageType") or {}).get("code") == COVERAGE_TYPE_CODE:
            return attrs["id"]
    raise ValueError(
        f"No coverage with code '{COVERAGE_TYPE_CODE}' found in risk unit {risk_unit_id}"
    )


def _get_insured_id(gw_claim_id: str) -> str:
    resp = guidewire_client.get_claim(gw_claim_id)
    attrs = (resp.get("data") or {}).get("attributes") or {}
    # Try common paths GW uses for the insured contact
    insured_id = (
        (attrs.get("insured") or {}).get("id")
        or (attrs.get("claimant") or {}).get("id")
        or (attrs.get("reporter") or {}).get("id")
    )
    if not insured_id:
        raise ValueError(
            "Could not extract insuredId from GET /claims response. "
            f"Available attribute keys: {list(attrs.keys())}"
        )
    return insured_id


def _create_exposure(gw_claim_id: str, insured_id: str, coverage_id: str, address: dict) -> str:
    jurisdiction_code = (address.get("state") or {}).get("code") or "IL"
    payload = {
        "data": {
            "attributes": {
                "claimant": {"id": insured_id},
                "claimantType": {"code": "insured"},
                "contactPermitted": True,
                "coverage": {"id": coverage_id},
                "coverageSubtype": {"code": COVERAGE_TYPE_CODE},
                "lossParty": {"code": "insured"},
                "primaryCoverage": {"code": COVERAGE_TYPE_CODE},
                "tier": {"code": "lossofuse"},
                "jurisdiction": {"code": jurisdiction_code},
                "otherStructureIncident": {"refid": "newOtherStructureIncident"},
            }
        },
        "included": {
            "OtherStructureIncident": [
                {
                    "attributes": {
                        "description": "Damage to other structures.",
                        "fencesDamaged": True,
                        "lossParty": {"code": "insured"},
                    },
                    "refid": "newOtherStructureIncident",
                    "method": "post",
                    "uri": f"/claim/v1/claims/{gw_claim_id}/other-structure-incidents",
                }
            ]
        },
    }
    if address:
        payload["data"]["attributes"]["tempLocation_Ext"] = address

    resp = guidewire_client.create_exposure(gw_claim_id, payload)
    exposure_id = (
        (resp.get("data") or {}).get("attributes") or {}
    ).get("id")
    if not exposure_id:
        raise ValueError(f"Create exposure did not return an id. Response: {resp}")
    return exposure_id


def _create_reserve_set(gw_claim_id: str, exposure_id: str, reserve_amount) -> dict:
    payload = {
        "data": {
            "attributes": {
                "reservesToWrite": [
                    {
                        "currency": {"code": CURRENCY},
                        "lineItems": [
                            {
                                "transactionAmount": {
                                    "amount": str(reserve_amount),
                                    "currency": CURRENCY,
                                }
                            }
                        ],
                        "reserveLine": {
                            "costCategory": {"code": "property_repair"},
                            "costType": {"code": "claimcost"},
                            "exposure": {"id": exposure_id},
                            "reservingCurrency": {"code": CURRENCY},
                        },
                    }
                ]
            }
        }
    }
    return guidewire_client.create_reserve_set(gw_claim_id, payload)


def _validate_exposure(gw_claim_id: str, exposure_id: str) -> dict:
    payload = {
        "data": {
            "attributes": {
                "validateClaim": True,
                "validationLevel": {"code": "payment"},
            }
        }
    }
    return guidewire_client.validate_exposure(gw_claim_id, exposure_id, payload)


def _create_check_set(
    gw_claim_id: str,
    exposure_id: str,
    insured_id: str,
    payment_amount,
    address: dict,
    payee_name: str,
) -> dict:
    payload = {
        "data": {
            "attributes": {
                "primaryCheckToWrite": {
                    "paymentsToWrite": [
                        {
                            "lineItems": [
                                {
                                    "lineCategory": {"code": "other", "name": "Other"},
                                    "transactionAmount": {
                                        "amount": str(payment_amount),
                                        "currency": CURRENCY,
                                    },
                                }
                            ],
                            "paymentType": {"code": "final"},
                            "reserveLine": {
                                "costCategory": {"code": "property_repair"},
                                "costType": {"code": "claimcost"},
                                "exposure": {"id": exposure_id},
                                "reservingCurrency": {"code": CURRENCY},
                            },
                            "currency": {"code": CURRENCY},
                        }
                    ],
                    "payees": [
                        {
                            "contact": {"id": insured_id},
                            "payeeType": {"code": "insured"},
                        }
                    ],
                    "paymentMethod": {"code": "check"},
                    "reportability": {"code": "notreportable"},
                    "checkBatching": {"code": "apdefault"},
                    "deliveryMethod": {"code": "send"},
                    "payTo": payee_name,
                }
            }
        }
    }
    if address:
        payload["data"]["attributes"]["primaryCheckToWrite"]["mailingAddress"] = address

    return guidewire_client.create_check_set(gw_claim_id, payload)


# ── Public handler ─────────────────────────────────────────────────────────────

def process_claim_payment(gw_claim_id: str) -> dict:
    """
    Executes the full post-update Guidewire financial flow:
    risk units → coverages → exposure → reserve → validate → payment.

    Returns a summary of each step's outcome.
    """
    # ── 1. Fetch DB data ───────────────────────────────────────────────────────
    claim, policy, cm, la = _fetch_data(gw_claim_id)
    if not claim:
        return {
            "success": False,
            "gw_claim_id": gw_claim_id,
            "error": f"No claim found in local DB with gw_claim_id='{gw_claim_id}'",
        }

    claim_number = claim.get("claim_number")
    address = _build_address(policy)
    payee_name = (
        (policy or {}).get("policyholder_name")
        or claim.get("policyholder_name")
        or "Insured"
    )

    # reserve_amount from claims_master; fallback to estimated_cost on claim
    reserve_amount = (
        (cm or {}).get("reserve_amount")
        or claim.get("estimated_cost")
        or 10000
    )
    # payment amount: net_payable_amount from loss_assessments; fallback to reserve
    payment_amount = (
        (la or {}).get("net_payable_amount")
        or reserve_amount
    )

    results: dict = {
        "success": True,
        "gw_claim_id": gw_claim_id,
        "claim_number": claim_number,
        "steps": {},
    }

    try:
        # ── Step 1: Risk units ─────────────────────────────────────────────────
        log.info("[Step 1] Fetching risk units for %s", gw_claim_id)
        risk_unit_id = _get_risk_unit_id(gw_claim_id)
        results["steps"]["risk_unit_id"] = risk_unit_id

        # ── Step 2: Coverages ──────────────────────────────────────────────────
        log.info("[Step 2] Fetching coverages for risk unit %s", risk_unit_id)
        coverage_id = _get_coverage_id(gw_claim_id, risk_unit_id)
        results["steps"]["coverage_id"] = coverage_id

        # ── Step 3: Insured contact ID ─────────────────────────────────────────
        log.info("[Step 3] Fetching insured contact id from claim %s", gw_claim_id)
        insured_id = _get_insured_id(gw_claim_id)
        results["steps"]["insured_id"] = insured_id

        # ── Step 4: Create exposure ────────────────────────────────────────────
        log.info("[Step 4] Creating exposure")
        exposure_id = _create_exposure(gw_claim_id, insured_id, coverage_id, address)
        results["steps"]["exposure_id"] = exposure_id

        # ── Step 5: Create reserve set ─────────────────────────────────────────
        log.info("[Step 5] Creating reserve set (amount=%s)", reserve_amount)
        reserve_resp = _create_reserve_set(gw_claim_id, exposure_id, reserve_amount)
        results["steps"]["reserve_set"] = reserve_resp

        # ── Step 6: Validate exposure ──────────────────────────────────────────
        log.info("[Step 6] Validating exposure %s", exposure_id)
        validate_resp = _validate_exposure(gw_claim_id, exposure_id)
        results["steps"]["validate"] = validate_resp

        # ── Step 7: Create check set (payment) ────────────────────────────────
        log.info("[Step 7] Creating check set (amount=%s)", payment_amount)
        check_resp = _create_check_set(
            gw_claim_id, exposure_id, insured_id, payment_amount, address, payee_name
        )
        results["steps"]["check_set"] = check_resp

    except Exception as exc:
        log.exception("process_claim_payment failed at step for %s", gw_claim_id)
        results["success"] = False
        results["error"] = str(exc)
        results["completed_steps"] = list(results["steps"].keys())

    return results
