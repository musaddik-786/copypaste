"""Result types of a decision run. Field names are part of the contract with the reference evaluator."""
from __future__ import annotations

from collections.abc import Callable, Mapping
from dataclasses import asdict, dataclass, field
from typing import Any, Literal

DecisionStatus = Literal["NOT_TRIGGERED", "SUPPRESSED", "NO_OPPORTUNITY", "RECOMMENDATIONS_AVAILABLE"]
Selection = Literal["PRIMARY", "ALTERNATIVE", "NOT_SELECTED", "EXCLUDED_BY_GROUP"]

# (rule, context, catalog) -> pricing strings, or None when no verified price exists (PR-01).
Pricer = Callable[[Mapping[str, Any], Mapping[str, Any], Mapping[str, Any]], "dict[str, str] | None"]


@dataclass
class RuleOutcome:
    rule_id: str
    stage: str
    outcome: str
    product_code: str | None = None
    detail: str | None = None
    clauses: list[dict[str, Any]] = field(default_factory=list)


@dataclass
class Candidate:
    rule_id: str
    type: str
    product_code: str
    priority_tier: str
    sequence: int
    exclusion_group: str | None
    pricing: dict[str, str]
    selection: Selection = "NOT_SELECTED"


@dataclass
class DecisionResult:
    status: DecisionStatus
    suppression_reasons: list[str]
    primary: str | None
    alternative: str | None
    candidates: list[Candidate]
    outcomes: list[RuleOutcome]
    catalog_version: str
    input_hash: str
    referrals: list[str]

    def outcome_of(self, rule_id: str) -> str | None:
        for o in self.outcomes:
            if o.rule_id == rule_id:
                return o.outcome
        return None


def result_to_dict(res: DecisionResult) -> dict[str, Any]:
    return asdict(res)
