"""Calendar helpers. ``as_of`` is always passed in - the engine never reads the clock."""
from __future__ import annotations

from datetime import date


def months_between(d1: date, d2: date) -> int:
    """Whole calendar months from d1 to d2 (a partial month does not count)."""
    m = (d2.year - d1.year) * 12 + (d2.month - d1.month)
    if d2.day < d1.day:
        m -= 1
    return m
