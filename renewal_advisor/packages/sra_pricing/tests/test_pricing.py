"""sra_pricing: exact golden figures, money invariants (CLAUDE.md invariant 4) and fail-closed behaviour (BR-12)."""
from __future__ import annotations

from decimal import Decimal
from typing import Any

import pytest
from hypothesis import given
from hypothesis import strategies as st
from sra_pricing import price_candidate, q2

CATALOG: dict[str, Any] = {"bundle_discounts": {"by_companion_product": {"PERSONAL_LIABILITY": 5, "CAR_POLICY": 10}}}
UPSELL = {"product_code": "CAR_NCD_PROTECTION", "type": "UPSELL"}
CROSS = {"product_code": "PERSONAL_LIABILITY", "type": "CROSS_SELL"}
MONEY_FIELDS = ("expiring_premium", "base_renewal_premium", "incremental_annual", "incremental_monthly_equiv",
                "bundle_saving_annual", "net_annual_total", "companion_standalone_annual")


def ctx(product: str, annual: Any, renewal: Any = 515.0, expiring: Any = 490.0, verified: Any = True) -> dict[str, Any]:
    return {"policy": {"renewal_premium": renewal, "expiring_premium": expiring},
            "pas_quotes": {product: {"annual_gross": annual, "verified": verified}}}


def test_cross_sell_matches_golden_bac_10() -> None:
    out = price_candidate(CROSS, ctx("PERSONAL_LIABILITY", 57.0), CATALOG)
    assert out is not None
    assert out["base_renewal_premium"] == "515.00"
    assert out["companion_standalone_annual"] == "57.00"
    assert out["bundle_discount_pct"] == "5"
    assert out["bundle_saving_annual"] == "28.60"
    assert out["net_annual_total"] == "543.40"
    assert out["incremental_monthly_equiv"] == "4.75"
    assert out["presentation"] == "SEPARATE_POLICY_ITEMISED"


def test_cross_sell_rounding_half_up_matches_golden_scn_01() -> None:
    # (445.00 + 62.40) * 5% = 25.37 exactly at 25.37; net 482.03 (the prototype said 25.38).
    out = price_candidate(CROSS, ctx("PERSONAL_LIABILITY", 62.4, renewal=445.0), CATALOG)
    assert out is not None
    assert (out["bundle_saving_annual"], out["net_annual_total"]) == ("25.37", "482.03")


def test_upsell_is_consolidated_without_bundle_saving() -> None:
    out = price_candidate(UPSELL, ctx("CAR_NCD_PROTECTION", 45.6), CATALOG)
    assert out is not None
    assert out["net_annual_total"] == "560.60"
    assert out["bundle_discount_pct"] == "0"
    assert out["bundle_saving_annual"] == "0.00"
    assert out["presentation"] == "CONSOLIDATED_INTO_RENEWAL"
    assert "companion_standalone_annual" not in out


def test_decimal_inputs_give_same_result_as_json_floats() -> None:
    a = price_candidate(CROSS, ctx("PERSONAL_LIABILITY", 62.4, renewal=445.0), CATALOG)
    b = price_candidate(CROSS, ctx("PERSONAL_LIABILITY", Decimal("62.40"), renewal=Decimal("445.00")), CATALOG)
    assert a == b


@pytest.mark.parametrize("verified", [False, None, "true", 1])
def test_unverified_quote_is_never_priced(verified: Any) -> None:
    assert price_candidate(CROSS, ctx("PERSONAL_LIABILITY", 57.0, verified=verified), CATALOG) is None


def test_missing_quote_is_never_priced() -> None:
    assert price_candidate(CROSS, {"policy": {"renewal_premium": 1, "expiring_premium": 1}}, CATALOG) is None


@pytest.mark.parametrize("field", ["renewal", "expiring", "annual"])
def test_missing_premium_fails_closed(field: str) -> None:
    kwargs: dict[str, Any] = {"annual": 57.0, "renewal": 515.0, "expiring": 490.0}
    kwargs[field] = None
    annual = kwargs.pop("annual")
    assert price_candidate(CROSS, ctx("PERSONAL_LIABILITY", annual, **kwargs), CATALOG) is None


def test_exact_half_cent_rounds_up_in_saving_and_monthly() -> None:
    # (90.00 + 10.10) * 5% = 5.005 -> 5.01 (HALF_EVEN would give 5.00); 10.10 / 12 = 0.841666 -> 0.84
    out = price_candidate(CROSS, ctx("PERSONAL_LIABILITY", "10.10", renewal="90.00"), CATALOG)
    assert out is not None
    assert (out["bundle_saving_annual"], out["net_annual_total"]) == ("5.01", "95.09")
    # 12.30 / 12 = 1.025 -> 1.03 (HALF_EVEN would give 1.02)
    up = price_candidate(UPSELL, ctx("CAR_NCD_PROTECTION", "12.30"), CATALOG)
    assert up is not None
    assert up["incremental_monthly_equiv"] == "1.03"


def test_q2_is_round_half_up() -> None:
    assert q2(Decimal("2.345")) == Decimal("2.35")
    assert q2(Decimal("2.344")) == Decimal("2.34")
    assert q2(Decimal("-2.345")) == Decimal("-2.35")


money = st.decimals(min_value="0.01", max_value="5000", places=2)


@given(annual=money, renewal=money, expiring=money,
       product=st.sampled_from(["PERSONAL_LIABILITY", "CAR_POLICY", "UNLISTED_PRODUCT"]),
       kind=st.sampled_from(["UPSELL", "CROSS_SELL"]))
def test_money_invariants(annual: Decimal, renewal: Decimal, expiring: Decimal, product: str, kind: str) -> None:
    out = price_candidate({"product_code": product, "type": kind},
                          ctx(product, annual, renewal=renewal, expiring=expiring), CATALOG)
    assert out is not None
    for f in MONEY_FIELDS:
        if f in out:
            assert isinstance(out[f], str)
            assert Decimal(out[f]) == Decimal(out[f]).quantize(Decimal("0.01"))  # exactly 2 dp
            assert len(out[f].split(".")[1]) == 2
    base, inc = Decimal(out["base_renewal_premium"]), Decimal(out["incremental_annual"])
    companion = Decimal(out.get("companion_standalone_annual", "0"))
    saving, net = Decimal(out["bundle_saving_annual"]), Decimal(out["net_annual_total"])
    if kind == "UPSELL":
        assert net == base + inc and saving == 0
    else:
        # db/001 CHECK net_consistency: net = base + companion - saving
        assert net == base + companion - saving
        assert Decimal("0") <= saving <= base + companion
