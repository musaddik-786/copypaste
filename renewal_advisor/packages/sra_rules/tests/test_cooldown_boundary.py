"""EL-03 cooldown boundary: a decline exactly `limit` months ago no longer blocks; one day later it still does.

Limits come from the catalog (cooldown_rider_months / cooldown_companion_months), never from this test.
Every golden case with a primary recommendation is used, so both RIDER and COMPANION classes are covered.
"""
from __future__ import annotations

import copy
from datetime import date, timedelta
from typing import Any

import pytest
import sra_pricing
import sra_rules
from conftest import AS_OF, CATALOG, GOLDEN_TESTS, REFERENCE, RUN_GOLDEN


def _months_back(d: date, n: int) -> date:
    y, m = divmod(d.year * 12 + d.month - 1 - n, 12)
    return date(y, m + 1, d.day)


def _limit(product_code: str) -> int:
    cls = CATALOG["products"].get(product_code, {}).get("cooldown_class", "COMPANION")
    key = "cooldown_rider_months" if cls == "RIDER" else "cooldown_companion_months"
    value: int = CATALOG["parameters"][key]["value"]
    return value


CASES = []
for t in GOLDEN_TESTS:
    res = sra_rules.evaluate(RUN_GOLDEN.build(t), CATALOG, AS_OF, pricer=sra_pricing.price_candidate)
    if res.primary:
        pc = next(c.product_code for c in res.candidates if c.rule_id == res.primary)
        CASES.append((t, res.primary, pc))


@pytest.mark.parametrize(("test", "rule_id", "product_code"), CASES, ids=[c[0]["id"] for c in CASES])
@pytest.mark.parametrize(("days_inside", "expected"), [(0, "ELIGIBLE"), (1, "COOLDOWN_ACTIVE")])
def test_cooldown_boundary(test: dict[str, Any], rule_id: str, product_code: str,
                           days_inside: int, expected: str) -> None:
    declined_at = _months_back(AS_OF, _limit(product_code)) + timedelta(days=days_inside)
    ctx = copy.deepcopy(RUN_GOLDEN.build(test))
    ctx.setdefault("history", {}).setdefault("declines", []).append(
        {"product_code": product_code, "declined_at": declined_at.isoformat(), "source": "OFFICER_SKIP"})

    res = sra_rules.evaluate(ctx, CATALOG, AS_OF, pricer=sra_pricing.price_candidate)
    assert res.outcome_of(rule_id) == expected
    assert sra_rules.result_to_dict(res) == REFERENCE.result_to_dict(REFERENCE.evaluate(ctx, CATALOG, AS_OF))
