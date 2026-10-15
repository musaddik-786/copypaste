"""Deterministic candidate pricing (ADR-003, BR-12).

Uses ONLY verified PAS rating quotes from the snapshot and never invents a price. Output values are
strings (money: exactly 2 dp). Behaviour is identical to ``rules/reference_evaluator`` ``price_candidate``,
except that a missing premium fails closed (returns ``None``) instead of raising.
"""
from __future__ import annotations

from collections.abc import Mapping
from decimal import Decimal
from typing import Any

from sra_pricing.money import fmt, q2, to_decimal

UPSELL = "UPSELL"
CONSOLIDATED = "CONSOLIDATED_INTO_RENEWAL"
SEPARATE_ITEMISED = "SEPARATE_POLICY_ITEMISED"  # IDD Art. 24: cross-sell components shown separately
MONTHS_PER_YEAR = 12
PERCENT = 100


def _policy(ctx: Mapping[str, Any], key: str) -> Any:
    policy = ctx.get("policy")
    return policy.get(key) if isinstance(policy, Mapping) else None


def price_candidate(rule: Mapping[str, Any], ctx: Mapping[str, Any],
                    catalog: Mapping[str, Any]) -> dict[str, str] | None:
    """Price one opportunity rule's product. ``None`` means no verified price (PR-01 disqualifies)."""
    pc = rule["product_code"]
    quote = (ctx.get("pas_quotes") or {}).get(pc)
    if not quote or quote.get("verified") is not True:
        return None
    annual = to_decimal(quote.get("annual_gross"))
    renewal = to_decimal(_policy(ctx, "renewal_premium"))
    expiring = to_decimal(_policy(ctx, "expiring_premium"))
    if annual is None or renewal is None or expiring is None:
        return None  # fail closed

    out = {
        "expiring_premium": fmt(expiring),
        "base_renewal_premium": fmt(renewal),
        "incremental_annual": fmt(annual),
        "incremental_monthly_equiv": fmt(annual / MONTHS_PER_YEAR),  # divide first, round once
        "bundle_discount_pct": "0",
        "bundle_saving_annual": "0.00",
    }
    if rule["type"] == UPSELL:
        out["net_annual_total"] = fmt(renewal + annual)
        out["presentation"] = CONSOLIDATED
        return out

    pct = Decimal(str(catalog["bundle_discounts"]["by_companion_product"].get(pc, 0)))
    saving = q2((renewal + annual) * pct / PERCENT)
    out.update({
        "bundle_discount_pct": str(pct),
        "bundle_saving_annual": str(saving),
        "companion_standalone_annual": fmt(annual),
        "net_annual_total": fmt(renewal + annual - saving),
        "presentation": SEPARATE_ITEMISED,
    })
    return out
