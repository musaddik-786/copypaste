"""
handler.py — Update Claim Data in Guidewire
────────────────────────────────────────────
Fetches claim data from the local DB (claims, policy_details, fnol_submissions)
and PATCHes the corresponding Guidewire ClaimCenter claim with:
  - lossCause   (from claims.loss_type)
  - lossLocation (from policy_details address fields)
  - DwellingIncident with room damages and occupancy
    (from fnol_submissions.area_affected and occupancy_at_loss)

Only Guidewire-allowed enum values are included in the payload; fields whose
DB values cannot be mapped to a valid GW code are silently omitted.
"""

import logging
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "common"))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))

from db import get_db_connection, row_to_dict  # noqa: E402
from policy_coverage_mcp import guidewire_client  # noqa: E402

log = logging.getLogger(__name__)

# ── Allowed GW enum values ─────────────────────────────────────────────────────

VALID_LOSS_CAUSES = {
    "animalcollision", "animal", "bikecollision", "fixedobjcoll", "vehcollision",
    "otherobjcoll", "pedcollision", "trainbuscoll", "loadingdamage", "FallingObject",
    "earthquake", "explosion", "firedamage", "waterdamage", "glassbreakage",
    "vandalism", "rearend", "riotandcivil", "theftentire", "theftparts", "fire",
    "wind", "hail", "mold", "structfailure", "snowice", "burglary", "animal_bite",
    "broken_glass", "electrical_curr", "air_crash", "rail_crash", "water_veh_crash",
    "construction", "errors", "breach", "burn_scald", "caught_in", "cut", "fall",
    "motorvehicle", "strain", "striking", "struck", "rubbed", "miscellaneous",
    "leftcollision", "assault", "med_error", "product", "excess", "rollover",
    "personal_misconduct", "professional_sports", "official_duty", "death",
    "preex_med_condition", "abandonment", "delay", "cancellation",
    "terrorism_hijack", "missed_departure", "documents", "hurricane",
}

VALID_ROOM_TYPES = {"kitchen", "bedroom", "livingroom", "bathroom", "garage", "other"}

# Map common DB loss_type values → GW lossCause codes
LOSS_TYPE_MAP = {
    "water damage": "waterdamage",
    "water_damage": "waterdamage",
    "waterdamage": "waterdamage",
    "fire damage": "firedamage",
    "fire_damage": "firedamage",
    "firedamage": "firedamage",
    "fire": "firedamage",
    "wind/hail": "wind",
    "wind hail": "wind",
    "wind": "wind",
    "hail": "hail",
    "hurricane": "hurricane",
    "vandalism": "vandalism",
    "theft": "theftentire",
    "theft (entire vehicle)": "theftentire",
    "theft (parts)": "theftparts",
    "earthquake": "earthquake",
    "explosion": "explosion",
    "mold": "mold",
    "structural failure": "structfailure",
    "structfailure": "structfailure",
    "glass breakage": "glassbreakage",
    "broken glass": "broken_glass",
    "falling object": "FallingObject",
    "collision": "vehcollision",
    "vehicle collision": "vehcollision",
    "animal collision": "animalcollision",
    "animal": "animal",
    "flood": "waterdamage",
    "snow/ice": "snowice",
    "snow ice": "snowice",
    "burglary": "burglary",
    "electrical": "electrical_curr",
    "riot": "riotandcivil",
}

# Map DB area_affected values → GW roomType codes (case-insensitive)
ROOM_TYPE_MAP = {
    "kitchen": "kitchen",
    "bedroom": "bedroom",
    "living room": "livingroom",
    "livingroom": "livingroom",
    "living_room": "livingroom",
    "bathroom": "bathroom",
    "garage": "garage",
    "other": "other",
    "basement": "other",
    "attic": "other",
    "roof": "other",
    "exterior": "other",
    "yard": "other",
    "laundry": "other",
    "dining room": "other",
    "dining": "other",
    "hallway": "other",
    "office": "other",
    "den": "other",
}

# Full US state name → 2-letter abbreviation
STATE_ABBREVIATIONS = {
    "alabama": "AL", "alaska": "AK", "arizona": "AZ", "arkansas": "AR",
    "california": "CA", "colorado": "CO", "connecticut": "CT", "delaware": "DE",
    "florida": "FL", "georgia": "GA", "hawaii": "HI", "idaho": "ID",
    "illinois": "IL", "indiana": "IN", "iowa": "IA", "kansas": "KS",
    "kentucky": "KY", "louisiana": "LA", "maine": "ME", "maryland": "MD",
    "massachusetts": "MA", "michigan": "MI", "minnesota": "MN", "mississippi": "MS",
    "missouri": "MO", "montana": "MT", "nebraska": "NE", "nevada": "NV",
    "new hampshire": "NH", "new jersey": "NJ", "new mexico": "NM", "new york": "NY",
    "north carolina": "NC", "north dakota": "ND", "ohio": "OH", "oklahoma": "OK",
    "oregon": "OR", "pennsylvania": "PA", "rhode island": "RI", "south carolina": "SC",
    "south dakota": "SD", "tennessee": "TN", "texas": "TX", "utah": "UT",
    "vermont": "VT", "virginia": "VA", "washington": "WA", "west virginia": "WV",
    "wisconsin": "WI", "wyoming": "WY", "district of columbia": "DC",
}


# ── Value mapping helpers ──────────────────────────────────────────────────────

def _map_loss_cause(loss_type: str) -> str | None:
    """
    Map a DB loss_type string to a valid Guidewire lossCause code.
    Returns None if no valid mapping exists.
    """
    if not loss_type:
        return None
    normalized = loss_type.lower().strip()
    # Try direct known mapping first
    code = LOSS_TYPE_MAP.get(normalized)
    if code:
        return code
    # If the value is already a valid GW code (case-sensitive check)
    if loss_type.strip() in VALID_LOSS_CAUSES:
        return loss_type.strip()
    # Case-insensitive fallback against the valid set
    lower_code = normalized.replace(" ", "").replace("_", "").replace("-", "")
    for valid in VALID_LOSS_CAUSES:
        if valid.lower() == lower_code:
            return valid
    return None


def _map_room_type(area: str) -> str | None:
    """Map a single area_affected value to a valid GW roomType code."""
    if not area:
        return None
    normalized = area.lower().strip()
    code = ROOM_TYPE_MAP.get(normalized)
    if code:
        return code
    if normalized in VALID_ROOM_TYPES:
        return normalized
    return None


def _map_state(state: str) -> str | None:
    """Convert a full state name to its 2-letter abbreviation, or pass through if already abbreviated."""
    if not state:
        return None
    trimmed = state.strip()
    if len(trimmed) == 2 and trimmed.upper() == trimmed:
        return trimmed  # already an abbreviation
    return STATE_ABBREVIATIONS.get(trimmed.lower())


def _map_occupancy(occupancy_at_loss: str) -> str | None:
    """
    Map fnol_submissions.occupancy_at_loss to a GW occupancyType code.
    'Yes' → 'occupied', 'No' → 'vacant'.
    Returns None if the value cannot be mapped.
    """
    if not occupancy_at_loss:
        return None
    val = occupancy_at_loss.strip().lower()
    if val in ("yes", "y", "true", "1", "occupied"):
        return "occupied"
    if val in ("no", "n", "false", "0", "vacant"):
        return "vacant"
    if val in ("under construction", "underconstruction", "underconst"):
        return "underConst"
    return None


# ── DB fetch helpers ───────────────────────────────────────────────────────────

def _fetch_claim_data(gw_claim_id: str) -> tuple[dict | None, dict | None, dict | None]:
    """
    Returns (claim_row, policy_row, fnol_row) for the given gw_claim_id (cc:... ID).
    Any of the three may be None if not found.
    """
    conn = get_db_connection()
    try:
        cur = conn.cursor()

        cur.execute("SELECT * FROM claims WHERE gw_claim_id = %s", (gw_claim_id,))
        claim = row_to_dict(cur.fetchone())
        if not claim:
            return None, None, None

        policy = None
        if claim.get("policy_number"):
            cur.execute(
                "SELECT * FROM policy_details WHERE policy_number = %s",
                (claim["policy_number"],),
            )
            policy = row_to_dict(cur.fetchone())

        fnol = None
        if claim.get("policy_number"):
            # Fetch the most-recently submitted FNOL for this policy
            cur.execute(
                """
                SELECT * FROM fnol_submissions
                WHERE policy_number = %s AND status = 'submitted'
                ORDER BY submitted_at DESC
                LIMIT 1
                """,
                (claim["policy_number"],),
            )
            fnol = row_to_dict(cur.fetchone())

        return claim, policy, fnol
    finally:
        conn.close()


# ── Payload builder ────────────────────────────────────────────────────────────

def _build_update_payload(claim: dict, policy: dict, fnol: dict, gw_claim_id: str) -> dict:
    """
    Build the PATCH payload for /claim/v1/claims/{claimId}.
    Only fields that map to valid GW enum codes are included.
    """
    data_attrs: dict = {}
    included: dict = {}

    # ── lossCause ─────────────────────────────────────────────────────────────
    loss_cause_code = _map_loss_cause(claim.get("loss_type") or "")
    if loss_cause_code:
        data_attrs["lossCause"] = {"code": loss_cause_code}

    # ── lossLocation ──────────────────────────────────────────────────────────
    if policy:
        address_line = policy.get("policy_address") or ""
        city = policy.get("city") or ""
        country = policy.get("country") or "US"
        postal_code = policy.get("postal_code") or ""
        state_abbrev = _map_state(policy.get("state") or "")

        loss_location: dict = {}
        if address_line:
            loss_location["addressLine1"] = address_line
        if city:
            loss_location["city"] = city
        if country:
            loss_location["country"] = country
        if postal_code:
            loss_location["postalCode"] = postal_code
        if state_abbrev:
            loss_location["state"] = {"code": state_abbrev}

        if loss_location:
            data_attrs["lossLocation"] = loss_location

    # ── DwellingIncident ──────────────────────────────────────────────────────
    dwelling_attrs: dict = {}

    description = claim.get("short_description") or ""
    if description:
        dwelling_attrs["description"] = description

    dwelling_attrs["yearsInHome"] = 7
    dwelling_attrs["lossParty"] = {"code": "insured"}

    # Room damages from fnol area_affected
    if fnol:
        area_affected_raw = fnol.get("area_affected") or ""
        # area_affected may be a single value or comma-separated list
        raw_areas = [a.strip() for a in area_affected_raw.split(",") if a.strip()]
        room_damages = []
        for area in raw_areas:
            room_code = _map_room_type(area)
            if room_code:
                room_damages.append({
                    "numberOfRooms": 1,
                    "roomType": {"code": room_code},
                })
        if room_damages:
            dwelling_attrs["dwellingRoomDamages"] = room_damages

        # Occupancy type
        occupancy_code = _map_occupancy(fnol.get("occupancy_at_loss") or "")
        if occupancy_code:
            dwelling_attrs["occupancyType"] = {"code": occupancy_code}

    if dwelling_attrs.get("description") or dwelling_attrs.get("dwellingRoomDamages"):
        included["DwellingIncident"] = [
            {
                "attributes": dwelling_attrs,
                "method": "post",
                "uri": f"/claim/v1/claims/{gw_claim_id}/dwelling-incidents",
            }
        ]

    payload: dict = {}
    if data_attrs:
        payload["data"] = {"attributes": data_attrs}
    if included:
        payload["included"] = included

    return payload


# ── Public handler ─────────────────────────────────────────────────────────────

def update_claim_data(gw_claim_id: str) -> dict:
    """
    Accepts the Guidewire internal claim ID (cc:... returned by submit_fnol),
    fetches payload data from the local DB, and PATCHes Guidewire ClaimCenter.

    Returns a dict describing what was sent and the GW response.
    """
    claim, policy, fnol = _fetch_claim_data(gw_claim_id)

    if not claim:
        return {
            "success": False,
            "gw_claim_id": gw_claim_id,
            "error": f"No claim found in local DB with gw_claim_id='{gw_claim_id}'",
        }

    claim_number = claim.get("claim_number")
    payload = _build_update_payload(claim, policy, fnol, gw_claim_id)
    if not payload:
        return {
            "success": False,
            "claim_number": claim_number,
            "gw_claim_id": gw_claim_id,
            "error": "No mappable fields found — nothing to send to Guidewire.",
        }

    log.info("Sending update payload to GW for claim %s (gw_claim_id=%s)", claim_number, gw_claim_id)
    try:
        gw_response = guidewire_client.update_claim_data(gw_claim_id, payload)
        return {
            "success": True,
            "claim_number": claim_number,
            "gw_claim_id": gw_claim_id,
            "payload_sent": payload,
            "gw_response": gw_response,
        }
    except Exception as exc:
        log.exception("Guidewire update_claim_data failed for gw_claim_id=%s", gw_claim_id)
        return {
            "success": False,
            "claim_number": claim_number,
            "gw_claim_id": gw_claim_id,
            "payload_sent": payload,
            "error": str(exc),
        }
