"""Differential property test: random but realistic perturbations of the golden personas must give identical
results from the reference evaluator and the production engine. This catches divergences that the 31 fixed
golden cases do not exercise."""
from __future__ import annotations

import copy
from datetime import date, timedelta
from typing import Any

import sra_pricing
import sra_rules
from conftest import AS_OF, CATALOG, PERSONAS, REFERENCE
from hypothesis import given, settings
from hypothesis import strategies as st

PRODUCTS = sorted(CATALOG["products"])
RULE_PRODUCTS = sorted({r["product_code"] for r in CATALOG["rules"]})
PERSONA_KEYS =sorted(k for k in PERSONAS if not k.startswith("_"))  # skip "_comment"

# (dot-path, strategy) pairs that drive gatekeepers, filters, qualification and pricing.
MUTATIONS: list[tuple[str, st.SearchStrategy[Any]]] = [
    ("quote.status", st.sampled_from(["QUOTED", "WITHDRAWN", "ACCEPTED", None])),
    ("quote.letter_dispatched", st.booleans()),
    ("quote.days_to_letter_due", st.one_of(st.none(), st.integers(-5, 60))),
    ("consent.advisory_renewal", st.sampled_from(["GRANTED", "REVOKED", "UNSPECIFIED", None])),
    ("account.payment_status", st.sampled_from(["CURRENT", "ARREARS", "DEBT_RECOVERY", "DD_RETURNED", None])),
    ("conduct.open_complaint", st.one_of(st.none(), st.booleans())),
    ("conduct.disputed_claim_in_lookback", st.booleans()),
    ("conduct.vulnerability_hold", st.booleans()),
    ("policy.coverage_level", st.sampled_from(["TPL", "PARTIAL", "FULL", None])),
    ("policy.tier", st.sampled_from(["SMART", "COMFORT", "PREMIUM", None])),
    ("vehicle.age_years", st.one_of(st.none(), st.integers(0, 25))),
    ("vehicle.market_value", st.one_of(st.none(), st.integers(0, 90000))),
    ("vehicle.annual_km", st.one_of(st.none(), st.integers(0, 60000))),
    ("motor.bonus_tier", st.one_of(st.none(), st.integers(0, 35))),
    ("claims.at_fault_24m", st.integers(0, 3)),
    ("claims.at_fault_36m", st.integers(0, 4)),
    ("claims.claims_12m", st.integers(0, 3)),
    ("customer.dwelling_type", st.sampled_from(["APARTMENT", "DETACHED", "SEMI_DETACHED", "TERRACED", None])),
    ("customer.occupancy", st.sampled_from(["OWNER_OCCUPIER", "TENANT", "LANDLORD", None])),
    ("customer.has_dependants", st.one_of(st.none(), st.booleans())),
    ("customer.primary_earner", st.one_of(st.none(), st.booleans())),
    ("customer.dog_owner", st.one_of(st.none(), st.booleans())),
    ("customer.household_vehicle_count", st.one_of(st.none(), st.integers(0, 3))),
    ("property.zuers_zone", st.one_of(st.none(), st.integers(1, 4))),
    ("property.backwater_valve_certified", st.one_of(st.none(), st.booleans())),
    ("pet.age_years", st.one_of(st.none(), st.integers(0, 15))),
    ("policy.renewal_premium", st.decimals("100", "2000", places=2).map(float)),
]


def _set(d: dict[str, Any], path: str, value: Any) -> None:
    parts = path.split(".")
    for p in parts[:-1]:
        d = d.setdefault(p, {})
    d[parts[-1]] = value


@st.composite
def contexts(draw: st.DrawFn) -> dict[str, Any]:
    ctx: dict[str, Any] = copy.deepcopy(PERSONAS[draw(st.sampled_from(PERSONA_KEYS))])
    for path, strat in draw(st.lists(st.sampled_from(MUTATIONS), max_size=6, unique_by=lambda m: m[0])):
        _set(ctx, path, draw(strat))
    # verified flag / price of a rating quote
    quotes = ctx.get("pas_quotes") or {}
    if quotes and draw(st.booleans()):
        pc = draw(st.sampled_from(sorted(quotes)))
        quotes[pc]["verified"] = draw(st.booleans())
        quotes[pc]["annual_gross"] = float(draw(st.decimals("1", "900", places=2)))
    # portfolio / declines
    if draw(st.booleans()):
        ctx.setdefault("portfolio", {}).setdefault("active_products", []).append(draw(st.sampled_from(PRODUCTS)))
    if draw(st.booleans()):
        # bias towards the 6 / 12 month cooldown boundaries and towards products that rules actually offer
        days = draw(st.one_of(st.integers(0, 500), st.sampled_from([181, 182, 183, 184, 364, 365, 366])))
        declined_at = AS_OF - timedelta(days=days)
        ctx.setdefault("history", {}).setdefault("declines", []).append(
            {"product_code": draw(st.sampled_from(RULE_PRODUCTS)), "declined_at": declined_at.isoformat(),
             "source": "OFFICER_SKIP"})
    if draw(st.booleans()):
        ctx["unverified_facts"] = draw(st.lists(st.sampled_from([m[0] for m in MUTATIONS]), max_size=3))
    return ctx


@settings(max_examples=400, deadline=None)
@given(ctx=contexts(), shift=st.one_of(st.just(0), st.integers(-400, 400)))
def test_production_matches_reference_on_perturbed_contexts(ctx: dict[str, Any], shift: int) -> None:
    as_of: date = AS_OF + timedelta(days=shift)
    expected = REFERENCE.result_to_dict(REFERENCE.evaluate(ctx, CATALOG, as_of))
    actual = sra_rules.result_to_dict(sra_rules.evaluate(ctx, CATALOG, as_of, pricer=sra_pricing.price_candidate))
    assert actual == expected
