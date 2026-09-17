

"""
policy_coverage_router.py
──────────────────────────
Endpoints / MCP tools:
  gw_search_policy        POST /gw_search_policy
  gw_get_policy_coverages POST /gw_get_policy_coverages
  save_policy_details     POST /save_policy_details
  get_policy_details      GET  /get_policy_details/{policy_id}
  verify_coverage         POST /api/policy_coverage/verify/{claim_id}
  record_claim_payment    POST /api/policy_coverage/payment
"""

import logging
from fastapi import APIRouter, HTTPException, Query

from policy_coverage_mcp import handler
from policy_coverage_mcp.models import (
    GwSearchPolicyRequest,
    SavePolicyDetailsRequest,
    RecordClaimPaymentRequest,
    GetClaimDetailsRequest,
)

log = logging.getLogger(__name__)
router = APIRouter()


@router.post(
    "/get_claim_details",
    operation_id="get_claim_details",
    summary="Fetch claim details from local database (Homeowners: claims table, Motor: motor_fnol_submissions)",
)
def get_claim_details(req: GetClaimDetailsRequest):
    return handler.get_claim_details(req.claim_number, lob=req.lob)


@router.post(
    "/gw_search_policy",
    operation_id="gw_search_policy",
    summary="Search for a policy (Homeowners: Guidewire PC, Motor: motor_policy_details table)",
)
def gw_search_policy(req: GwSearchPolicyRequest):
    """
    Motor: reads from motor_policy_details (no Guidewire call).
    Homeowners: searches Guidewire PolicyCenter as usual.
    """
    return handler.gw_search_policy(req.policy_number, lob=req.lob)


@router.post(
    "/gw_get_policy_coverages",
    operation_id="gw_get_policy_coverages",
    summary="Fetch full policy coverage details (Homeowners: Guidewire, Motor: motor_policy_details)",
)
def gw_get_policy_coverages(req: GwSearchPolicyRequest):
    return handler.gw_get_policy_coverages(req.policy_number, lob=req.lob)


@router.post(
    "/save_policy_details",
    operation_id="save_policy_details",
    summary="Persist policy data locally (Homeowners: fetches from Guidewire, Motor: reads motor_policy_details)",
)
def save_policy_details(req: SavePolicyDetailsRequest):
    try:
        return handler.save_policy_details(req.policy_number, lob=req.lob)
    except Exception as e:
        log.exception("save_policy_details error")
        raise HTTPException(status_code=500, detail=str(e))


@router.get(
    "/get_policy_details/{policy_number}",
    operation_id="get_policy_details",
    summary="Read policy details from the local database",
)
def get_policy_details(policy_number: str, lob: str = Query("Homeowners")):
    """Returns the full policy_details or motor_policy_details record."""
    record = handler.get_policy_details(policy_number, lob=lob)
    if not record:
        return {"status": "not_found", "policy_number": policy_number}
    return record


@router.get(
    "/api/policy_coverage/result/{claim_number}",
    operation_id="get_coverage_verification_result",
    summary="Read an existing coverage verification result for a claim",
)
def get_coverage_verification_result(claim_number: str, lob: str = Query("Homeowners")):
    return handler.get_coverage_verification_result(claim_number, lob=lob)


@router.post(
    "/api/policy_coverage/verify/{claim_number}",
    operation_id="verify_coverage",
    summary="Verify whether a claim's loss is covered by the linked policy",
)
def verify_coverage(claim_number: str, lob: str = Query("Homeowners")):
    """
    Motor: uses motor_fnol_submissions + motor_policy_details.
    Homeowners: uses claims + policy_details.
    """
    return handler.verify_coverage(claim_number, lob=lob)


@router.post(
    "/api/policy_coverage/payment",
    operation_id="record_claim_payment",
    summary="Record an approved claim payment and reduce remaining policy coverage",
)
def record_claim_payment(req: RecordClaimPaymentRequest):
    try:
        return handler.record_claim_payment(
            req.claim_number, req.amount_paid, lob=req.lob,
            approved_by=req.approved_by, notes=req.notes,
        )
    except Exception as e:
        log.exception("record_claim_payment error")
        raise HTTPException(status_code=500, detail=str(e))






"""
handler.py — Policy Coverage Verification (dual-LOB: Homeowners + Motor)
──────────────────────────────────────────────────────────────────────────
Homeowners: Guidewire PolicyCenter lookup → local policy_details table
Motor:      Local motor_policy_details table (pre-populated dummy data,
            mimics what Guidewire PC would return for real motor policies)
"""

import json
import logging
import os
import random
import sys
from datetime import datetime
from zoneinfo import ZoneInfo

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "common"))

from db import get_db_connection, row_to_dict  # noqa: E402
from dotenv import load_dotenv, find_dotenv
from openai import AzureOpenAI
try:
    from policy_coverage_mcp import guidewire_client
except ImportError:
    guidewire_client = None

load_dotenv(find_dotenv())

log = logging.getLogger(__name__)

AZURE_OPENAI_ENDPOINT = os.environ.get("AZURE_OPENAI_ENDPOINT", "")
AZURE_OPENAI_API_KEY = os.environ.get("AZURE_OPENAI_API_KEY", "")
AZURE_OPENAI_API_VERSION = os.environ.get("AZURE_OPENAI_API_VERSION", "2025-01-01-preview")
AZURE_OPENAI_CHAT_DEPLOYMENT = os.environ.get("AZURE_OPENAI_CHAT_DEPLOYMENT", "gpt-4.1-claims")

LOCAL_ONLY_POLICY_NUMBERS = {"73-300676", "73-400676", "73-123676"}


# ── LOB routing helpers ───────────────────────────────────────────────────────

def _is_motor(lob: str) -> bool:
    return (lob or "").strip().lower() == "motor"


def _policy_table(lob: str) -> str:
    return "motor_policy_details" if _is_motor(lob) else "policy_details"


def _claims_table(lob: str) -> str:
    """Both Motor and HO claim records (with claim_number) live in the claims table.
    motor_fnol_submissions is the draft/intake table and has no claim_number column."""
    return "claims"


def _coverage_table(lob: str) -> str:
    return "motor_coverage_verification_results" if _is_motor(lob) else "coverage_verification_results"


def _get_openai_client() -> AzureOpenAI:
    return AzureOpenAI(
        api_key=AZURE_OPENAI_API_KEY,
        api_version=AZURE_OPENAI_API_VERSION,
        azure_endpoint=AZURE_OPENAI_ENDPOINT,
    )


def _policy_from_local_row(row: dict) -> dict:
    """Maps a policy_details / motor_policy_details row into the shape gw_search_policy returns."""
    coverage_type = row.get("coverage_type")
    return {
        "gw_policy_id": row.get("gw_policy_id") or "",
        "policy_number": row.get("policy_number") or "",
        "status": row.get("status") or "Unknown",
        "effective_date": row.get("effective_date"),
        "expiration_date": row.get("expiration_date"),
        "coverage_types": [coverage_type] if coverage_type else [],
        "policyholder_name": row.get("policyholder_name") or "",
        "policyholder_address": row.get("policy_address") or "",
        "account_number": row.get("account_number") or "",
        "product_name": coverage_type or "",
        "raw": None,
    }


# ── Policy Search ─────────────────────────────────────────────────────────────

def gw_search_policy(policy_number: str, lob: str = "Homeowners") -> dict:
    """
    Motor: reads from motor_policy_details (no Guidewire call).
    Homeowners: checks LOCAL_ONLY_POLICY_NUMBERS first, else hits Guidewire PC.
    """
    trimmed = (policy_number or "").strip()

    if _is_motor(lob):
        row = get_policy_details(trimmed, lob=lob)
        if not row:
            return {
                "found": False,
                "policy": None,
                "error": f"Motor policy '{trimmed}' not found in motor_policy_details table.",
                "raw_gw_response": {},
            }
        return {"found": True, "policy": _policy_from_local_row(row), "error": None, "raw_gw_response": None}

    # Homeowners — check local-only set first
    if trimmed in LOCAL_ONLY_POLICY_NUMBERS:
        row = get_policy_details(trimmed, lob=lob)
        if not row:
            return {
                "found": False,
                "policy": None,
                "error": f"Policy '{trimmed}' not found in local policy_details table.",
                "raw_gw_response": {},
            }
        return {"found": True, "policy": _policy_from_local_row(row), "error": None, "raw_gw_response": None}

    try:
        raw = guidewire_client.search_policy(policy_number)
        parsed = guidewire_client.parse_policy_from_search(raw)
        if not parsed:
            return {
                "found": False,
                "policy": None,
                "error": f"No policy found in Guidewire for policy number '{policy_number}'.",
                "raw_gw_response": raw,
            }
        return {"found": True, "policy": parsed, "error": None, "raw_gw_response": raw}
    except Exception as exc:
        status_code = getattr(getattr(exc, "response", None), "status_code", None)
        if status_code == 404:
            return {
                "found": False, "policy": None,
                "error": f"Policy '{policy_number}' not found in Guidewire (HTTP 404).",
                "raw_gw_response": {},
            }
        log.exception("Guidewire policy search failed for %s", policy_number)
        return {
            "found": False, "policy": None,
            "error": f"Guidewire API error: {str(exc)}", "raw_gw_response": {},
        }


# ── Policy Coverages ──────────────────────────────────────────────────────────

def gw_get_policy_coverages(policy_number: str, lob: str = "Homeowners") -> dict:
    """
    Motor: returns coverage detail directly from motor_policy_details row.
    Homeowners: fetches from Guidewire PolicyCenter.
    """
    search_result = gw_search_policy(policy_number, lob=lob)
    if not search_result["found"]:
        return search_result

    if _is_motor(lob):
        row = get_policy_details(policy_number, lob=lob)
        return {"found": True, "policy_id": policy_number, "coverage_detail": row, "error": None}

    gw_policy_id = search_result["policy"]["gw_policy_id"]
    try:
        detail = guidewire_client.get_policy_coverages(gw_policy_id)
        return {"found": True, "policy_id": gw_policy_id, "coverage_detail": detail, "error": None}
    except Exception as exc:
        log.exception("gw_get_policy_coverages failed for %s", gw_policy_id)
        return {"found": False, "policy_id": gw_policy_id, "coverage_detail": None, "error": str(exc)}


# ── Local DB: Save & Read policy_details / motor_policy_details ──────────────

def save_policy_details(policy_number: str, lob: str = "Homeowners") -> dict:
    """
    Motor: motor_policy_details is pre-populated with dummy data; no GW fetch needed.
           Just returns the existing record (or error if not found).
    Homeowners: fetches from Guidewire and upserts to policy_details.
    """
    trimmed = (policy_number or "").strip()

    if _is_motor(lob):
        row = get_policy_details(trimmed, lob=lob)
        if not row:
            return {
                "found": False, "policy": None,
                "error": f"Motor policy '{trimmed}' not found in motor_policy_details. Pre-populate the table first.",
                "raw_gw_response": {},
            }
        return {"saved": True, **row}

    # Homeowners LOCAL_ONLY short-circuit
    if trimmed in LOCAL_ONLY_POLICY_NUMBERS:
        row = get_policy_details(trimmed, lob=lob)
        if not row:
            return {"found": False, "policy": None, "error": f"Policy '{trimmed}' not found in local policy_details table.", "raw_gw_response": {}}
        return {"saved": True, **row}

    search_result = gw_search_policy(policy_number, lob=lob)
    if not search_result["found"]:
        return search_result

    policy = search_result["policy"]
    gw_policy_id = policy.get("gw_policy_id")
    effective_date = policy.get("effective_date")
    expiration_date = policy.get("expiration_date")
    policyholder_name = policy.get("policyholder_name")
    account_number = policy.get("account_number")
    policy_address = policy.get("policyholder_address") or (
        policy.get("raw", {})
        .get("data", [{}])[0]
        .get("attributes", {})
        .get("policyAddress")
    )

    coverage_result = gw_get_policy_coverages(policy_number, lob=lob)
    attrs = {}
    if coverage_result.get("found"):
        raw_detail = coverage_result.get("coverage_detail", {})
        log.info("[GW DEBUG] raw_detail top-level keys: %s", list(raw_detail.keys()) if isinstance(raw_detail, dict) else type(raw_detail).__name__)
        data_node = raw_detail.get("data", {}) if isinstance(raw_detail, dict) else {}
        log.info("[GW DEBUG] data_node type=%s", type(data_node).__name__)
        # Guidewire detail endpoint may return data as a dict (single record) or as a list
        if isinstance(data_node, list):
            log.info("[GW DEBUG] data is a LIST with %d items — taking first element", len(data_node))
            data_node = data_node[0] if data_node else {}
        attrs = data_node.get("attributes", {}) if isinstance(data_node, dict) else {}
        log.info("[GW DEBUG] attrs keys: %s", sorted(attrs.keys()))
        log.info("[GW DEBUG] totalPremium=%s  lines_type=%s", attrs.get("totalPremium"), type(attrs.get("lines")).__name__)
    else:
        log.warning("[GW DEBUG] gw_get_policy_coverages not found for %s: %s", policy_number, coverage_result.get("error"))

    state = attrs.get("baseState", {}).get("name") if isinstance(attrs.get("baseState"), dict) else None
    term_type = attrs.get("termType", {}).get("name") if isinstance(attrs.get("termType"), dict) else None
    premium_amount = (attrs.get("totalPremium") or {}).get("amount") if isinstance(attrs.get("totalPremium"), dict) else None
    currency = (attrs.get("preferredCoverageCurrency") or {}).get("code") if isinstance(attrs.get("preferredCoverageCurrency"), dict) else None

    addr = attrs.get("policyAddress") or {}
    city = addr.get("city") if isinstance(addr, dict) else None
    country = addr.get("country") if isinstance(addr, dict) else None
    postal_code = addr.get("postalCode") if isinstance(addr, dict) else None

    product_name = (attrs.get("product") or {}).get("displayName", "") if isinstance(attrs.get("product"), dict) else ""
    coverage_type = "Homeowners" if "Homeowners" in product_name else (product_name or policy.get("product_name", ""))
    status = "Active" if coverage_result.get("found") else (policy.get("status") or "Unknown")

    # Extract deductible, coverage limit, and exclusions from Guidewire coverage lines
    # deductible = None
    # coverage_limit = None
    # exclusions_list = []

    # lines_data = (attrs.get("lines") or {}).get("data", []) if isinstance(attrs.get("lines"), dict) else []
    # for line in lines_data:
    #     line_attrs = line.get("attributes", {}) if isinstance(line, dict) else {}
    #     coverages_data = (line_attrs.get("coverages") or {}).get("data", []) if isinstance(line_attrs.get("coverages"), dict) else []
    #     for cov in coverages_data:
    #         cov_attrs = cov.get("attributes", {}) if isinstance(cov, dict) else {}
    #         # Deductible — take the first non-null value found
    #         if deductible is None:
    #             ded = cov_attrs.get("deductible") or {}
    #             if isinstance(ded, dict) and ded.get("amount") is not None:
    #                 try:
    #                     deductible = float(ded["amount"])
    #                 except (TypeError, ValueError):
    #                     pass
    #         # Coverage limit
    #         if coverage_limit is None:
    #             lim = cov_attrs.get("coverageAmount") or cov_attrs.get("limit") or {}
    #             if isinstance(lim, dict) and lim.get("amount") is not None:
    #                 try:
    #                     # coverage_limit = float(lim["amount"])
    #                     coverage_limit = 500000
    #                 except (TypeError, ValueError):
    #                     pass
    #         # Exclusions
    #         for excl in (cov_attrs.get("exclusions") or []):
    #             name = (excl.get("attributes") or {}).get("name") if isinstance(excl, dict) else None
    #             if name:
    #                 exclusions_list.append(name)

    # exclusions = ",".join(exclusions_list) if exclusions_list else None







# Extract deductible, coverage limit, and exclusions from Guidewire coverage lines
    # deductible = None
    # coverage_limit = None
    # exclusions_list = []
    # lines_data = (attrs.get("lines") or {}).get("data", []) if isinstance(attrs.get("lines"), dict) else []
    # for line in lines_data:
    #     line_attrs = line.get("attributes", {}) if isinstance(line, dict) else {}
    #     coverages_data = (
    #         (line_attrs.get("coverages") or {}).get("data", [])
    #         if isinstance(line_attrs.get("coverages"), dict)
    #         else []
    #     )
    #     for cov in coverages_data:
    #         cov_attrs = cov.get("attributes", {}) if isinstance(cov, dict) else {}
    #         # Deductible
    #         if deductible is None:
    #             ded = cov_attrs.get("deductible") or {}
    #             if isinstance(ded, dict) and ded.get("amount") is not None:
    #                 try:
    #                     deductible = float(ded["amount"])
    #                 except (TypeError, ValueError):
    #                     pass
    #         # Coverage Limit
    #         if coverage_limit is None:
    #             lim = cov_attrs.get("coverageAmount") or cov_attrs.get("limit") or {}
    #             if isinstance(lim, dict) and lim.get("amount") is not None:
    #                 try:
    #                     coverage_limit = float(lim["amount"])
    #                 except (TypeError, ValueError):
    #                     pass
    #         # Exclusions
    #         for excl in (cov_attrs.get("exclusions") or []):
    #             name = (
    #                 (excl.get("attributes") or {}).get("name")
    #                 if isinstance(excl, dict)
    #                 else None
    #             )
    #             if name:
    #                 exclusions_list.append(name)
    # # Fallback ONLY if Guidewire did not provide a coverage limit
    # if coverage_limit is None:
    #     log.warning(
    #         "Guidewire did not return a coverage limit for policy %s. Using default PoC value 500000.",
    #         policy_number,
    #     )
    #     coverage_limit = 500000.0
    # exclusions = ",".join(exclusions_list) if exclusions_list else None








    # Extract deductible, coverage limit, and exclusions from Guidewire coverage lines
    deductible = None
    coverage_limit = None
    exclusions_list = []

    lines_data = (
        (attrs.get("lines") or {}).get("data", [])
        if isinstance(attrs.get("lines"), dict)
        else []
    )

    for line in lines_data:
        line_attrs = line.get("attributes", {}) if isinstance(line, dict) else {}

        coverages_data = (
            (line_attrs.get("coverages") or {}).get("data", [])
            if isinstance(line_attrs.get("coverages"), dict)
            else []
        )

        for cov in coverages_data:
            cov_attrs = cov.get("attributes", {}) if isinstance(cov, dict) else {}

            # Deductible from Guidewire
            if deductible is None:
                ded = cov_attrs.get("deductible") or {}
                if isinstance(ded, dict) and ded.get("amount") is not None:
                    try:
                        deductible = float(ded["amount"])
                    except (TypeError, ValueError):
                        pass

            # Coverage Limit from Guidewire
            if coverage_limit is None:
                lim = cov_attrs.get("coverageAmount") or cov_attrs.get("limit") or {}
                if isinstance(lim, dict) and lim.get("amount") is not None:
                    try:
                        coverage_limit = float(lim["amount"])
                    except (TypeError, ValueError):
                        pass

            # Exclusions
            for excl in (cov_attrs.get("exclusions") or []):
                name = (
                    (excl.get("attributes") or {}).get("name")
                    if isinstance(excl, dict)
                    else None
                )
                if name:
                    exclusions_list.append(name)

    # ------------------------------------------------------------------
    # PoC fallback logic when Guidewire does not provide values
    # ------------------------------------------------------------------
    coverage = (coverage_type or "").lower()

    if premium_amount is not None:
        premium_amount = float(premium_amount)

        # Coverage Limit
        # Industry benchmark: homeowners premium ≈ 0.7% of dwelling coverage → limit = premium / 0.007
        # Vehicle premium ≈ 3% of vehicle value → limit = premium / 0.03
        if coverage_limit is None:
            if "vehicle" in coverage:
                coverage_limit = round(premium_amount / 0.03, 2)
            elif "homeowners" in coverage or "personal" in coverage:
                coverage_limit = round(premium_amount / 0.007, 2)
            log.info(
                "Coverage limit not returned by Guidewire. Calculated value: %s",
                coverage_limit,
            )

        # Deductible
        # Homeowners: typically $1,000–$2,500; approximate as 1% of coverage limit
        # Vehicle: typically $500–$1,000; approximate as 1% of coverage limit
        if deductible is None:
            if coverage_limit is not None:
                deductible = round(coverage_limit * 0.01, 2)
            elif "vehicle" in coverage:
                deductible = round(premium_amount * 0.35, 2)
            elif "homeowners" in coverage or "personal" in coverage:
                deductible = round(premium_amount * 0.65, 2)
            log.info(
                "Deductible not returned by Guidewire. Calculated value: %s",
                deductible,
            )

    exclusions = ",".join(exclusions_list) if exclusions_list else None



    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            """
            INSERT INTO policy_details (
                policy_number, gw_policy_id, status, coverage_type,
                deductible, coverage_limit, remaining_coverage_limit, exclusions,
                effective_date, expiration_date, premium_amount,
                policyholder_name, account_number, policy_address,
                state, term_type, currency, city, country, postal_code
            ) VALUES (
                %s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s
            )
            ON CONFLICT (policy_number) DO UPDATE SET
                gw_policy_id = EXCLUDED.gw_policy_id,
                status = EXCLUDED.status,
                coverage_type = EXCLUDED.coverage_type,
                deductible = EXCLUDED.deductible,
                coverage_limit = EXCLUDED.coverage_limit,
                remaining_coverage_limit = COALESCE(
                    policy_details.remaining_coverage_limit, EXCLUDED.coverage_limit
                ),
                exclusions = EXCLUDED.exclusions,
                effective_date = EXCLUDED.effective_date,
                expiration_date = EXCLUDED.expiration_date,
                premium_amount = EXCLUDED.premium_amount,
                policyholder_name = EXCLUDED.policyholder_name,
                account_number = EXCLUDED.account_number,
                policy_address = EXCLUDED.policy_address,
                state = EXCLUDED.state,
                term_type = EXCLUDED.term_type,
                currency = EXCLUDED.currency,
                city = EXCLUDED.city,
                country = EXCLUDED.country,
                postal_code = EXCLUDED.postal_code
            """,
            (
                policy_number, gw_policy_id, status, coverage_type,
                deductible, coverage_limit, coverage_limit, exclusions,
                effective_date, expiration_date, premium_amount,
                policyholder_name, account_number, policy_address,
                state, term_type, currency, city, country, postal_code,
            ),
        )
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()

    return {
        "saved": True,
        "policy_number": policy_number,
        "gw_policy_id": gw_policy_id,
        "status": status,
        "coverage_type": coverage_type,
        "deductible": deductible,
        "coverage_limit": coverage_limit,
        "exclusions": exclusions,
        "premium_amount": premium_amount,
        "currency": currency,
    }


def get_policy_details(policy_number: str, lob: str = "Homeowners") -> dict:
    """Read a policy record from policy_details or motor_policy_details."""
    table = _policy_table(lob)
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute(f"SELECT * FROM {table} WHERE policy_number = %s", (policy_number,))
        return row_to_dict(cur.fetchone())
    finally:
        conn.close()


# ── Coverage Verification ─────────────────────────────────────────────────────

def get_coverage_verification_result(claim_id: str, lob: str = "Homeowners") -> dict:
    """Read an existing coverage verification result for the claim."""
    table = _coverage_table(lob)
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute(f"SELECT * FROM {table} WHERE claim_number = %s", (claim_id,))
        row = row_to_dict(cur.fetchone())
        if row:
            return {"found": True, **row}
        return {"found": False, "claim_number": claim_id}
    finally:
        conn.close()


def verify_coverage(claim_id: str, lob: str = "Homeowners") -> dict:
    """
    Motor: reads from motor_fnol_submissions + motor_policy_details → motor_coverage_verification_results.
    Homeowners: reads from claims + policy_details → coverage_verification_results.
    """
    claims_tbl = _claims_table(lob)
    policy_tbl = _policy_table(lob)
    coverage_tbl = _coverage_table(lob)

    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute(f"SELECT * FROM {claims_tbl} WHERE claim_number = %s", (claim_id,))
        claim = row_to_dict(cur.fetchone())
        if not claim:
            return {"error": f"Claim {claim_id} not found in {claims_tbl}"}

        policy_number = claim.get("policy_number")
        if not policy_number:
            return {"error": "No policy_number on claim", "claim": claim}

        cur.execute(f"SELECT * FROM {policy_tbl} WHERE policy_number = %s", (policy_number,))
        policy = row_to_dict(cur.fetchone())
        if not policy:
            return {
                "error": f"Policy {policy_number} not found in {policy_tbl} — run save_policy_details first",
                "claim": claim,
            }
    finally:
        conn.close()

    loss_type = claim.get("loss_type", "")
    cause_of_loss = claim.get("detected_cause") or claim.get("cause_of_loss", "")
    coverage_type = policy.get("coverage_type", "")
    coverage_limit = float(policy.get("remaining_coverage_limit") or policy.get("coverage_limit") or 0)
    deductible = float(policy.get("deductible") or 0)
    exclusions_raw = policy.get("exclusions") or ""
    exclusions = (
        json.loads(exclusions_raw)
        if isinstance(exclusions_raw, str) and exclusions_raw.startswith("[")
        else [x.strip() for x in exclusions_raw.split(",") if x.strip()]
    )
    loss_amount = float(
        claim.get("loss_amount") or claim.get("estimated_loss_amount") or claim.get("estimated_cost") or 0
    )

    try:
        client = _get_openai_client()
        prompt = (
            "You are a policy coverage analyst. Determine whether the claim is covered.\n"
            "IMPORTANT: If Estimated Loss Amount is 0 or not provided, the damage has not yet been assessed. "
            "Do NOT return 'Needs Investigation' solely because the loss amount is zero. "
            "Instead, evaluate whether the loss type and cause of loss are covered under the policy type "
            "and whether any exclusions apply. "
            "If covered with no exclusion triggered, return coverage_verdict='Covered - Pending Assessment' "
            "with net_payable=0 and coverage_notes explaining that the net payable will be calculated "
            "once the damage assessment is complete.\n"
            "Respond with JSON only: "
            '{"coverage_verdict": "Covered|Covered - Pending Assessment|Partially Covered|Not Covered|Needs Investigation", '
            '"exclusion_triggered": true/false, '
            '"exclusion_details": "...", '
            '"net_payable": <number>, '
            '"coverage_notes": "..."}.\n\n'
            f"Policy Coverage Type: {coverage_type}\n"
            f"Remaining Coverage Limit: {coverage_limit}\n"
            f"Deductible: {deductible}\n"
            f"Policy Exclusions: {exclusions}\n"
            f"Claim Loss Type: {loss_type}\n"
            f"Cause of Loss: {cause_of_loss}\n"
            f"Estimated Loss Amount: {loss_amount}"
        )
        response = client.chat.completions.create(
            model=AZURE_OPENAI_CHAT_DEPLOYMENT,
            messages=[{"role": "user", "content": prompt}],
            temperature=0.0,
            response_format={"type": "json_object"},
        )
        llm_result = json.loads(response.choices[0].message.content)
    except Exception as e:
        log.warning("LLM coverage check failed: %s", e)
        net_payable = max(0.0, loss_amount - deductible)
        if coverage_limit:
            net_payable = min(net_payable, coverage_limit)
        llm_result = {
            "coverage_verdict": "Needs Investigation",
            "exclusion_triggered": False,
            "exclusion_details": "",
            "net_payable": net_payable,
            "coverage_notes": "Automated LLM check failed; manual review needed",
        }

    conn2 = get_db_connection()
    try:
        cur2 = conn2.cursor()
        cur2.execute(
            f"""
            INSERT INTO {coverage_tbl}
              (claim_number, policy_number, coverage_verdict, exclusion_triggered,
               exclusion_details, net_payable, coverage_notes, verified_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            ON CONFLICT (claim_number) DO UPDATE SET
              coverage_verdict = EXCLUDED.coverage_verdict,
              exclusion_triggered = EXCLUDED.exclusion_triggered,
              exclusion_details = EXCLUDED.exclusion_details,
              net_payable = EXCLUDED.net_payable,
              coverage_notes = EXCLUDED.coverage_notes,
              verified_at = EXCLUDED.verified_at
            """,
            (
                claim_id, str(policy_number),
                llm_result.get("coverage_verdict"),
                llm_result.get("exclusion_triggered", False),
                llm_result.get("exclusion_details"),
                llm_result.get("net_payable"),
                llm_result.get("coverage_notes"),
                datetime.now(ZoneInfo("UTC")).isoformat(),
            ),
        )
        conn2.commit()
    except Exception as e:
        conn2.rollback()
        log.warning("Could not write %s: %s", coverage_tbl, e)
    finally:
        conn2.close()

    return {
        "claim_number": claim_id,
        "policy_number": str(policy_number),
        "coverage_type": coverage_type,
        "remaining_coverage_limit": coverage_limit,
        "deductible": deductible,
        "loss_amount": loss_amount,
        "exclusions": exclusions,
        **llm_result,
    }


# ── Payment Tracking ──────────────────────────────────────────────────────────

def record_claim_payment(
    claim_id: str,
    amount_paid: float,
    lob: str = "Homeowners",
    approved_by: str = None,
    notes: str = None,
) -> dict:
    """
    Record an approved claim payment and reduce the policy's remaining_coverage_limit.
    Routes to motor or HO tables based on lob.
    """
    claims_tbl = _claims_table(lob)
    policy_tbl = _policy_table(lob)

    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute(f"SELECT * FROM {claims_tbl} WHERE claim_number = %s", (claim_id,))
        claim = row_to_dict(cur.fetchone())
    finally:
        conn.close()

    if not claim:
        return {"error": f"Claim {claim_id} not found in {claims_tbl}"}

    policy_number = claim.get("policy_number")
    if not policy_number:
        return {"error": "No policy_number on claim"}

    conn2 = get_db_connection()
    try:
        cur2 = conn2.cursor()
        cur2.execute(
            f"SELECT coverage_limit, remaining_coverage_limit FROM {policy_tbl} WHERE policy_number = %s",
            (policy_number,),
        )
        policy = row_to_dict(cur2.fetchone())
    finally:
        conn2.close()

    if not policy:
        return {"error": f"Policy {policy_number} not found in {policy_tbl} — run save_policy_details first"}

    coverage_before = float(
        policy.get("remaining_coverage_limit") or policy.get("coverage_limit") or 0
    )
    coverage_after = max(0.0, coverage_before - amount_paid)

    payment_id = f"PAY-{datetime.now().strftime('%Y%m%d%H%M%S')}-{random.randint(1000, 9999)}"
    payment_date = datetime.now(ZoneInfo("UTC")).isoformat()

    conn3 = get_db_connection()
    try:
        cur3 = conn3.cursor()
        cur3.execute(
            """
            INSERT INTO claim_payments (
                payment_id, claim_number, policy_number, amount_paid, payment_date,
                approved_by, payment_status, coverage_before, coverage_after, notes
            ) VALUES (%s,%s,%s,%s,%s,%s,'Released',%s,%s,%s)
            """,
            (
                payment_id, claim_id, policy_number, amount_paid, payment_date,
                approved_by, coverage_before, coverage_after, notes,
            ),
        )
        cur3.execute(
            f"UPDATE {policy_tbl} SET remaining_coverage_limit = %s WHERE policy_number = %s",
            (coverage_after, policy_number),
        )
        cur3.execute(
            f"UPDATE {claims_tbl} SET status = 'Settled' WHERE claim_number = %s",
            (claim_id,),
        )
        conn3.commit()
    except Exception:
        conn3.rollback()
        raise
    finally:
        conn3.close()

    return {
        "payment_id": payment_id,
        "claim_number": claim_id,
        "policy_number": policy_number,
        "amount_paid": amount_paid,
        "coverage_before": coverage_before,
        "coverage_after": coverage_after,
        "payment_status": "Released",
        "payment_date": payment_date,
    }


def get_claim_details(claim_id: str, lob: str = "Homeowners") -> dict:
    """Fetch claim details from claims or motor_fnol_submissions based on lob."""
    claims_tbl = _claims_table(lob)
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute(f"SELECT * FROM {claims_tbl} WHERE claim_number = %s", (claim_id,))
        claim = row_to_dict(cur.fetchone())
        if not claim:
            return {"found": False, "claim_id": claim_id, "error": f"Claim '{claim_id}' not found in {claims_tbl}"}
        return {"found": True, "claim": claim}
    finally:
        conn.close()
 
  
  
  
  



from pydantic import BaseModel, Field
from typing import Optional


class GetClaimDetailsRequest(BaseModel):
    claim_number: str = Field(..., description="Claim number, e.g. CLM-2024-1003")
    lob: str = Field("Homeowners", description="Line of business: 'Homeowners' or 'Motor'")


class GwSearchPolicyRequest(BaseModel):
    policy_number: str = Field(..., description="Policy number to look up, e.g. '9802322834'")
    lob: str = Field("Homeowners", description="Line of business: 'Homeowners' or 'Motor'")


class GwReportLossRequest(BaseModel):
    policy_number: str = Field(..., description="Policy number the loss is reported against")
    claim_number: str = Field(..., description="Local claim number, e.g. CLM-2026-1234")
    loss_type: str = Field(..., description="Type of loss, e.g. 'Water Damage', 'Fire'")
    loss_date: str = Field(..., description="Date of loss in YYYY-MM-DD format")
    loss_description: str = Field(..., description="Free-text description of what happened")
    loss_location: Optional[str] = Field(None, description="Address or area where loss occurred")
    policyholder_name: str = Field(..., description="Name of the insured policyholder")
    estimated_amount: Optional[float] = Field(None, description="Policyholder's estimated loss amount")
    lob: str = Field("Homeowners", description="Line of business: 'Homeowners' or 'Motor'")


class SavePolicyDetailsRequest(BaseModel):
    policy_number: str = Field(..., description="Policy number to fetch from Guidewire (HO) or local table (Motor)")
    lob: str = Field("Homeowners", description="Line of business: 'Homeowners' or 'Motor'")


class RecordClaimPaymentRequest(BaseModel):
    claim_number: str = Field(..., description="Claim number (e.g. CLM-2026-1001) for which payment is released")
    amount_paid: float = Field(..., description="Amount paid out for this claim")
    approved_by: Optional[str] = Field(None, description="Name or ID of the adjuster who approved the payment")
    notes: Optional[str] = Field(None, description="Optional notes about the payment")
    lob: str = Field("Homeowners", description="Line of business: 'Homeowners' or 'Motor'")





"""
server.py — Policy Coverage Verification Agent
───────────────────────────────────────────────
LangGraph agent that verifies whether a claim's reported loss falls within
the linked policy's coverage terms, deductible, limit, and exclusions.

Port: 8007
MCP : http://localhost:8000/api/v1/policy_coverage/mcp

Run:
    py -3 server.py
"""

import json
import logging
import os
import sys
import time
import traceback
from datetime import datetime, timedelta
from typing import Annotated, TypedDict

import uvicorn
from dotenv import load_dotenv, find_dotenv
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from langchain_core.messages import AIMessage, SystemMessage
from langchain_mcp_adapters.client import MultiServerMCPClient
from langchain_openai.chat_models import AzureChatOpenAI
from langgraph.graph import END, START, StateGraph
from langgraph.graph.message import add_messages
from langgraph.prebuilt import ToolNode

load_dotenv(find_dotenv())

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
    stream=sys.stdout,
    force=True,
)
logger = logging.getLogger("policy_coverage_agent")

PHOENIX_API_KEY = os.getenv("PHOENIX_API_KEY", "")
PHOENIX_ENDPOINT = os.getenv("PHOENIX_ENDPOINT", "")
MCP_URL = os.getenv("MCP_URL", "http://localhost:8000/api/v1/policy_coverage/mcp")
AGENT_PORT = int(os.getenv("AGENT_PORT", "8007"))

config_mcp_server = {
    "policy_coverage_mcp": {
        "url": MCP_URL,
        "transport": "streamable_http",
        "timeout": timedelta(seconds=120),
        "sse_read_timeout": timedelta(seconds=600),
    }
}

app = FastAPI(title="Policy Coverage Verification Agent")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class State(TypedDict):
    messages: Annotated[list, add_messages]


def router(state: State):
    last = state["messages"][-1]
    if isinstance(last, AIMessage) and getattr(last, "tool_calls", None):
        return "tools"
    if isinstance(last, AIMessage) and last.content:
        if "Continue" in last.content:
            return "tools"
        if "End" in last.content:
            return "End"
    return "End"


# _FALLBACK_PROMPT = """
# You are the Policy Coverage Verification Agent for an insurance claims platform,
# assisting a Policyholder.

# ─── STEP 0 — Determine whether a tool call is needed ───────────────────────
# Only call tools when the policyholder is asking about coverage status or
# verification for a SPECIFIC claim.

# If the message is a general question (e.g. "What does deductible mean?",
# "How does coverage work?") — answer it from your knowledge WITHOUT calling
# any tools, then end with "End".

# ─── STEP 1 — Extract the claim number ──────────────────────────────────────
# Before calling any tool, identify the claim number from the CURRENT message
# only. Do NOT use claim numbers from earlier in the conversation.

# If no claim number is present in the current message, ask:
#   "Could you please share your claim number so I can check the coverage?"
# Do not call any tool until the policyholder provides it.

# ─── STEP 2 — Check for an existing verification result ─────────────────────
# Call get_coverage_verification_result with the claim number.
# - If a result already exists, use it to answer the policyholder directly.
#   Do NOT call verify_coverage again unless they explicitly ask for a recheck.
# - If no result exists, proceed to Step 3.

# ─── STEP 3 — Ensure policy is in the local database ────────────────────────
# Call get_policy_details with the policy number linked to the claim.
# - If policy details exist locally, proceed directly to Step 4.
# - If not found locally:
#     a. Call gw_search_policy to find the policy in Guidewire.
#     b. Call save_policy_details to persist it locally.

# ─── STEP 4 — Run coverage verification ─────────────────────────────────────
# Call verify_coverage with the claim number.

# ─── STEP 5 — Explain the result in plain language ──────────────────────────
# Tell the policyholder:
# - Whether their loss is Covered, Partially Covered, or Not Covered.
# - Any exclusions that apply and why, in plain terms.
# - The deductible that applies to their claim.
# - The estimated net payable amount after the deductible.
# - Recommended next steps.

# ─── RULES ───────────────────────────────────────────────────────────────────
# - NEVER show internal IDs (gw_policy_id, claim_id integers, etc.).
# - NEVER expose remaining_coverage_limit as a raw number — describe it in
#   context (e.g. "Your remaining coverage for this period is $X").
# - NEVER assume or guess a claim number. Always take it from the current message.
# - When you have completed the full response, end with "End".
# """




_FALLBACK_PROMPT = """
You are the Policy Coverage Verification Agent for an insurance claims platform,
assisting a Policyholder.

─── STEP 0 — Determine whether a tool call is needed ───────────────────────
Only call tools when the policyholder is asking about coverage status or
verification for a SPECIFIC claim.

If the message is a general question (e.g. "What does deductible mean?",
"How does coverage work?") — answer it from your knowledge WITHOUT calling
any tools, then end with "End".

─── STEP 1 — Extract the claim number ──────────────────────────────────────
Before calling any tool, identify the claim number from the CURRENT message
only. Do NOT use claim numbers from earlier in the conversation.

If no claim number is present in the current message, ask:
  "Could you please share your claim number so I can check the coverage?"
Do not call any tool until the policyholder provides it.

─── STEP 2 — Check for an existing verification result ─────────────────────
Call get_coverage_verification_result with the claim number.
- If a result already exists, use it to answer the policyholder directly.
  Do NOT call verify_coverage again unless they explicitly ask for a recheck.
- If no result exists, proceed to Step 3.

─── STEP 3 — Retrieve the linked policy ─────────────────────────────
Call get_claim_details using the claim number.
If the claim is not found:
Explain that the claim does not exist and stop.
Otherwise:
Read the policy_number returned by get_claim_details.
Do not guess or invent a policy number.
Proceed to Step 4.

─── STEP 4 — Ensure policy is available locally ─────────────────────
Call get_policy_details using the policy_number returned from
get_claim_details.
If the policy exists locally:
Proceed to Step 5.
Otherwise:
1. Call gw_search_policy(policy_number)
2. Call save_policy_details(policy_number)
3. Call get_policy_details(policy_number) again
Proceed to Step 5.

─── STEP 5 — Explain the result in plain language ──────────────────────────
Run verify_coverage(claim_number)
 

─── RULES ───────────────────────────────────────────────────────────────────
- NEVER show internal IDs (gw_policy_id, claim_id integers, etc.).
- NEVER expose remaining_coverage_limit as a raw number — describe it in
  context (e.g. "Your remaining coverage for this period is $X").
- NEVER assume or guess a claim number. Always take it from the current message.
- When you have completed the full response, end with "End".
"""


def load_prompt() -> str:
    if not PHOENIX_ENDPOINT:
        raise RuntimeError("Phoenix not configured")
    from phoenix.client import Client
    client = Client(base_url=PHOENIX_ENDPOINT, api_key=PHOENIX_API_KEY)
    prompt = client.prompts.get(name="policy_coverage_agent", label="production")
    prompt_set = prompt._template["messages"]
    system_msg = next(
        (item["content"][0]["text"] for item in prompt_set if item.get("role") == "system"), None
    )
    if not system_msg:
        raise ValueError("System prompt is empty or missing in Phoenix")
    return system_msg


def create_graph(model, tools, prompt):
    graph_builder = StateGraph(State)
    llm_with_tools = model.bind_tools(tools)

    async def agent_node(state: State):
        all_messages = [SystemMessage(content=prompt)] + state["messages"]
        # message = await llm_with_tools.ainvoke(all_messages)
        message = await llm_with_tools.ainvoke(all_messages)
        logger.info("=" * 80)
        logger.info("LLM Response")
        logger.info("Content: %s", message.content)
        if getattr(message, "tool_calls", None):
            logger.info("Tool Calls:")
        for tool in message.tool_calls:
            logger.info(
                    "Tool=%s Args=%s",
                    tool.get("name"),
                    tool.get("args"),
                )
        logger.info("=" * 80)
        return {"messages": [message]}
        # return {"messages": [message]}

    graph_builder.add_node("agent", agent_node)
    graph_builder.add_node("tools", ToolNode(tools=tools))
    graph_builder.add_edge(START, "agent")
    graph_builder.add_conditional_edges("agent", router, {"tools": "tools", "End": END})
    graph_builder.add_edge("tools", "agent")
    return graph_builder.compile()


async def get_tools():
    client = MultiServerMCPClient(config_mcp_server)
    tools = await client.get_tools()
    logger.info("Tools loaded from MCP: %s", [t.name for t in tools])
    return tools


async def stream_graph(graph, initial_state, config):
    async for event in graph.astream_events(initial_state, config=config, version="v2"):
        kind = event.get("event", "")
        if kind == "on_chat_model_stream":
            chunk = event["data"].get("chunk")
            if chunk and hasattr(chunk, "content") and chunk.content:
                yield f"data: {chunk.content}\n\n"
        # elif kind == "on_tool_start":
        #     yield f"data: [Tool: {event.get('name', 'unknown_tool')}] Starting...\n\n"
        elif kind == "on_tool_start":
            logger.info(
                "TOOL START: %s | INPUT=%s",
                event.get("name"),
                event["data"].get("input"),
            )
            yield f"data: [Tool: {event.get('name')}] Starting...\n\n"
        # elif kind == "on_tool_end":
        #     yield f"data: [Tool: {event.get('name', 'unknown_tool')}] Done\n\n"

        elif kind == "on_tool_end":
            logger.info(

                    "TOOL END: %s | OUTPUT=%s",

                    event.get("name"),

                    event["data"].get("output"),

                )

            yield f"data: [Tool: {event.get('name')}] Done\n\n"

 



@app.post("/chat")
async def chat_stream(request: Request):
    load_dotenv(find_dotenv())
    tools = await get_tools()

    model = AzureChatOpenAI(
        api_key=os.getenv("AZURE_OPENAI_API_KEY"),
        api_version=os.getenv("AZURE_OPENAI_API_VERSION"),
        azure_deployment=os.getenv("AZURE_OPENAI_CHAT_DEPLOYMENT"),
        azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT"),
    )

    try:
        system_prompt = load_prompt()
    except Exception as e:
        logger.warning("Phoenix prompt load failed (%s) — using fallback prompt", e)
        system_prompt = _FALLBACK_PROMPT

    body = await request.json()
    history = body.get("history", [])
    user_message = body.get("message", "Verify policy coverage for this claim")

    initial_messages = history + [user_message] if history else [user_message]
    graph = create_graph(model=model, tools=tools, prompt=system_prompt)

    async def generate():
        start = time.time()
        last_event_at = start
        last_tool = None
        try:
            async for event in stream_graph(
                graph=graph,
                initial_state={"messages": initial_messages},
                config={"recursion_limit": 250},
            ):
                last_event_at = time.time()
                if isinstance(event, str) and event.startswith("data: [Tool:"):
                    try:
                        last_tool = event.split("[Tool:", 1)[1].split("]", 1)[0]
                    except Exception:
                        pass
                yield event
        except BaseException as e:
            elapsed = time.time() - start
            since_last = time.time() - last_event_at
            err = {
                "exception_class": type(e).__name__,
                "message": str(e),
                "elapsed_total_seconds": round(elapsed, 2),
                "seconds_since_last_event": round(since_last, 2),
                "last_tool_invoked": last_tool,
                "traceback": traceback.format_exc(),
                "timestamp_utc": datetime.utcnow().isoformat(),
            }
            logger.error("AGENT_ERROR %s", json.dumps(err, default=str))
            try:
                yield f"data: [AGENT_ERROR] {json.dumps(err, default=str)}\n\n"
            except Exception:
                pass
            import asyncio
            if isinstance(e, asyncio.CancelledError):
                raise

    return StreamingResponse(generate(), media_type="text/event-stream")


@app.get("/health")
async def health():
    return {"status": "healthy", "agent": "policy_coverage_agent"}


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=AGENT_PORT)


