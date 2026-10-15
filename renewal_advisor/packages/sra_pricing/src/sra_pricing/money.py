"""Money primitives. The ONLY place in the system where money is rounded (CLAUDE.md invariant 4)."""
from __future__ import annotations

from decimal import ROUND_HALF_UP, Decimal
from typing import Any

TWO_DP = Decimal("0.01")


def q2(x: Decimal) -> Decimal:
    """Round to 2 dp, ROUND_HALF_UP."""
    return x.quantize(TWO_DP, rounding=ROUND_HALF_UP)


def to_decimal(x: Any) -> Decimal | None:
    """Exact conversion for money inputs.

    JSON numbers (floats) go through ``str()`` so 45.6 becomes Decimal('45.6'), never the binary
    approximation. ``None`` stays ``None`` so callers can fail closed; booleans are rejected.
    """
    if x is None or isinstance(x, bool):
        return None
    if isinstance(x, Decimal):
        return x
    return Decimal(str(x))


def fmt(x: Decimal) -> str:
    """Wire format for money: string, exactly 2 dp."""
    return str(q2(x))
