"""Readable unit tests for the engine semantics that the contract test enforces implicitly."""
from __future__ import annotations

from datetime import date
from typing import Any

import pytest
from sra_rules.dates import months_between
from sra_rules.facts import MISSING, fact_status, get_path
from sra_rules.jsonlogic import Logic


def test_get_path_and_missing() -> None:
    ctx = {"a": {"b": 0, "c": None}}
    assert get_path(ctx, "a.b") == 0
    assert get_path(ctx, "a.c") is None
    assert get_path(ctx, "a.x") is MISSING
    assert get_path(ctx, "a.b.c", "dflt") == "dflt"


@pytest.mark.parametrize(("ctx", "status"), [
    ({"x": {"y": False}}, "OK"),
    ({"x": {"y": 0}}, "OK"),
    ({"x": {"y": None}}, "MISSING"),
    ({"x": {}}, "MISSING"),
    ({"x": {"y": 1}, "unverified_facts": ["x.y"]}, "UNVERIFIED"),
])
def test_fact_status_fail_closed(ctx: dict[str, Any], status: str) -> None:
    assert fact_status(ctx, "x.y") == status


def test_comparison_with_unknown_never_passes() -> None:
    lg = Logic({"v": None})
    assert lg.ev({">": [{"var": "v"}, 1]}) is False
    assert lg.ev({"<=": [{"var": "missing"}, 1]}) is False


def test_and_or_return_bool_and_short_circuit() -> None:
    lg = Logic({"a": 1, "b": 2})
    assert lg.ev({"and": [{"==": [{"var": "a"}, 2]}, {"==": [{"var": "b"}, 2]}]}) is False
    assert len(lg.trace) == 1  # second clause never evaluated -> not traced
    assert lg.ev({"or": [{"var": "a"}, False]}) is True


def test_trace_records_clause_values() -> None:
    lg = Logic({"vehicle": {"age_years": 7}})
    assert lg.ev({"<=": [{"var": "vehicle.age_years"}, {"var": "params.max_age"}]}) is False
    assert lg.trace == [{"op": "<=", "left": "vehicle.age_years", "left_value": 7,
                         "right": "params.max_age", "right_value": None, "result": False}]


def test_in_with_missing_list() -> None:
    lg = Logic({"p": "X"})
    assert lg.ev({"in": [{"var": "p"}, {"var": "nope"}]}) is False
    assert lg.ev({"in": [{"var": "p"}, ["X", "Y"]]}) is True


def test_unsupported_operator_is_rejected() -> None:
    with pytest.raises(ValueError, match="unsupported"):
        Logic({}).ev({"+": [1, 2]})


@pytest.mark.parametrize(("d1", "d2", "months"), [
    (date(2026, 4, 13), date(2026, 10, 13), 6),
    (date(2026, 4, 14), date(2026, 10, 13), 5),
    (date(2025, 10, 31), date(2026, 10, 13), 11),
])
def test_months_between(d1: date, d2: date, months: int) -> None:
    assert months_between(d1, d2) == months
