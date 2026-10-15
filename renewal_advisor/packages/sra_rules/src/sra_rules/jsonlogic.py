"""Side-effect-free JsonLogic subset with a clause-level trace.

Supported: var, and, or, !, in, ==, !=, <, <=, >, >=. Semantics are those of the reference evaluator
(the executable spec), which deliberately differ from stock JsonLogic in places:

* ``and`` / ``or`` short-circuit and return a bool (not the operand); unevaluated clauses are not traced.
* ``==`` / ``!=`` are Python equality (no type coercion).
* Ordering comparisons with an unknown (None) side are always False - unknowns never pass.
* Only binary operators are traced: {op, left, left_value, right, right_value, result}.
"""
from __future__ import annotations

from collections.abc import Mapping
from typing import Any

from sra_rules.facts import MISSING, get_path

Clause = dict[str, Any]
_ORDERING = {"<", "<=", ">", ">="}
_BINARY = {"in", "==", "!=", *_ORDERING}


def _label(node: Any) -> Any:
    if isinstance(node, Mapping) and "var" in node:
        return node["var"]
    return node


def _compare(op: str, a: Any, b: Any) -> bool:
    if a is None or b is None:
        return False
    if op == "<":
        return bool(a < b)
    if op == "<=":
        return bool(a <= b)
    if op == ">":
        return bool(a > b)
    return bool(a >= b)


class Logic:
    """Evaluates JsonLogic nodes against one context, recording every binary comparison it evaluates."""

    def __init__(self, ctx: Mapping[str, Any]) -> None:
        self.ctx = ctx
        self.trace: list[Clause] = []

    def ev(self, node: Any) -> Any:
        if not isinstance(node, Mapping):
            return node
        if len(node) != 1:
            raise ValueError(f"JsonLogic node must have exactly one operator: {node!r}")
        ((op, args),) = node.items()
        if op == "var":
            v = get_path(self.ctx, args if isinstance(args, str) else args[0])
            return None if v is MISSING else v
        if op == "and":
            return all(self.ev(a) for a in args)
        if op == "or":
            return any(self.ev(a) for a in args)
        if op == "!":
            return not self.ev(args[0] if isinstance(args, list) else args)
        if op not in _BINARY:
            raise ValueError(f"unsupported JsonLogic operator: {op!r}")

        left, right = args
        a, b = self.ev(left), self.ev(right)
        if op == "in":
            res = a in (b or [])
        elif op == "==":
            res = a == b
        elif op == "!=":
            res = a != b
        else:
            res = _compare(op, a, b)
        self.trace.append({"op": op, "left": _label(left), "left_value": a,
                           "right": _label(right), "right_value": b, "result": res})
        return res
