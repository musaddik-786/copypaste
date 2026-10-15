"""Fact access over the decision context and the Data Integrity Gate (CLAUDE.md invariant 5: fail closed)."""
from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Final, Literal


class _Missing:
    __slots__ = ()

    def __repr__(self) -> str:
        return "MISSING"


MISSING: Final = _Missing()

FactStatus = Literal["OK", "MISSING", "UNVERIFIED"]


def get_path(ctx: Mapping[str, Any], path: str, default: Any = MISSING) -> Any:
    """Dot-path lookup through nested mappings; ``default`` if any step is absent."""
    cur: Any = ctx
    for part in path.split("."):
        if isinstance(cur, Mapping) and part in cur:
            cur = cur[part]
        else:
            return default
    return cur


def fact_status(ctx: Mapping[str, Any], path: str) -> FactStatus:
    """OK | MISSING | UNVERIFIED. ``None`` counts as missing; ``False`` and ``0`` are valid facts."""
    v = get_path(ctx, path)
    if v is MISSING or v is None:
        return "MISSING"
    if path in set(ctx.get("unverified_facts", [])):
        return "UNVERIFIED"
    return "OK"
