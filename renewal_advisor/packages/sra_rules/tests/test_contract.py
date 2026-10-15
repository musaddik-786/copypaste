"""Contract test (CLAUDE.md invariant 3): the production engine must produce exactly the same result as the
reference evaluator for every golden test - not only the fields the golden runner checks, but the full result
(outcomes, details, clause traces, candidates, pricing, selection, referrals, input hash)."""
from __future__ import annotations

from datetime import date
from typing import Any

import pytest
import sra_pricing
import sra_rules
from conftest import CATALOG, GOLDEN_TESTS, REFERENCE, RUN_GOLDEN


def _production(ctx: dict[str, Any], as_of: date) -> sra_rules.DecisionResult:
    return sra_rules.evaluate(ctx, CATALOG, as_of, pricer=sra_pricing.price_candidate)


@pytest.mark.parametrize("test", GOLDEN_TESTS, ids=[t["id"] for t in GOLDEN_TESTS])
def test_golden_expectations_hold_for_production_engine(test: dict[str, Any], as_of: date) -> None:
    res = _production(RUN_GOLDEN.build(test), as_of)
    assert RUN_GOLDEN.check(test, res) == []


@pytest.mark.parametrize("test", GOLDEN_TESTS, ids=[t["id"] for t in GOLDEN_TESTS])
def test_production_result_identical_to_reference(test: dict[str, Any], as_of: date) -> None:
    ctx = RUN_GOLDEN.build(test)
    expected = REFERENCE.result_to_dict(REFERENCE.evaluate(ctx, CATALOG, as_of))
    actual = sra_rules.result_to_dict(_production(ctx, as_of))
    assert actual == expected


def test_suite_size_is_at_least_31() -> None:
    assert len(GOLDEN_TESTS) >= 31


def test_engine_does_not_mutate_its_input(as_of: date) -> None:
    ctx = RUN_GOLDEN.build(GOLDEN_TESTS[0])
    snapshot = repr(ctx)
    _production(ctx, as_of)
    assert repr(ctx) == snapshot
