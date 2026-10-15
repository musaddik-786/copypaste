"""The decision pipeline: ``evaluate(context, catalog, as_of, pricer=...) -> DecisionResult``.

Pure function (ADR-001): no I/O, no clock, no randomness, no LLM. Every business threshold comes from the
rule catalog (ADR-002); this module only encodes the *order* of the stages and filters, which is the same as
in ``rules/reference_evaluator`` (the executable spec, enforced by the contract test).

Stages
  0  Operational window (W-01)                -> NOT_TRIGGERED stops the run
  1  Gatekeepers (GK-*), all evaluated        -> any hit (or missing gatekeeper fact) suppresses the case
  2  Opportunity rules through the filters    -> inactive, LOB, prerequisite holding, EL-01 already covered,
                                                 EL-02 embedded cover, EL-03 cooldown, EL-06 data integrity,
                                                 EL-05 risk quality, referral, qualification, EL-04 target
                                                 market, PR-01 verified price -> ELIGIBLE
  3  Ranking and selection                    -> PRIMARY / ALTERNATIVE (max_recommendations), exclusion groups
"""
from __future__ import annotations

import copy
from collections.abc import Mapping
from datetime import date
from decimal import Decimal
from typing import Any

from sra_rules.dates import months_between
from sra_rules.facts import fact_status, get_path
from sra_rules.hashing import canonical_hash
from sra_rules.jsonlogic import Clause, Logic
from sra_rules.model import Candidate, DecisionResult, Pricer, RuleOutcome

RISK_FILTER_ID = "EL-05"


def _bad_facts(ctx: Mapping[str, Any], required: list[str]) -> list[str]:
    return [f for f in required if fact_status(ctx, f) != "OK"]


def _check_window(ctx: dict[str, Any], catalog: Mapping[str, Any], outcomes: list[RuleOutcome]) -> bool:
    w = catalog["window_rule"]
    lg = Logic(ctx)
    passed = bool(get_path(ctx, "quote", None)) and bool(lg.ev(w["when"]))
    outcomes.append(RuleOutcome(w["id"], "WINDOW", "PASSED" if passed else "NOT_TRIGGERED", clauses=lg.trace))
    return passed


def _run_gatekeepers(ctx: dict[str, Any], catalog: Mapping[str, Any], outcomes: list[RuleOutcome]) -> list[str]:
    """Evaluate every active gatekeeper (complete audit). Returns suppression reasons."""
    reasons: list[str] = []
    for gk in catalog["gatekeepers"]:
        if gk.get("status") != "ACTIVE":
            continue
        bad = _bad_facts(ctx, gk.get("required_facts", []))
        if bad:
            outcomes.append(RuleOutcome(gk["id"], "GATEKEEPER", "SUPPRESS_DATA_INTEGRITY", detail=",".join(bad)))
            reasons.append(f"{gk['id']}:DATA_INTEGRITY")
            continue
        lg = Logic(ctx)
        fired = bool(lg.ev(gk["suppress_when"]))
        outcomes.append(RuleOutcome(gk["id"], "GATEKEEPER", "SUPPRESS" if fired else "PASSED",
                                    detail=gk["reason_code"] if fired else None, clauses=lg.trace))
        if fired:
            reasons.append(f"{gk['id']}:{gk['reason_code']}")
    return reasons


class _OpportunityStage:
    """Runs each opportunity rule through the ordered candidate filters."""

    def __init__(self, ctx: dict[str, Any], catalog: Mapping[str, Any], as_of: date, pricer: Pricer) -> None:
        self.ctx = ctx
        self.catalog = catalog
        self.as_of = as_of
        self.pricer = pricer
        self.active = set(get_path(ctx, "portfolio.active_products", []) or [])
        self.embedded = set(get_path(ctx, "portfolio.embedded_covers", []) or [])
        self.declines: list[Mapping[str, Any]] = get_path(ctx, "history.declines", []) or []
        self.products: Mapping[str, Any] = catalog["products"]
        risk = [f for f in catalog["candidate_filters"] if f["id"] == RISK_FILTER_ID]
        if not risk:
            raise ValueError(f"catalog has no {RISK_FILTER_ID} candidate filter")
        self.risk_filter: Mapping[str, Any] = risk[0]
        self.candidates: list[Candidate] = []
        self.referrals: list[str] = []

    def _cooldown_hit(self, pc: str) -> tuple[Mapping[str, Any], int] | None:
        cls = self.products.get(pc, {}).get("cooldown_class", "COMPANION")  # fail-safe: the longer cooldown
        key = "cooldown_rider_months" if cls == "RIDER" else "cooldown_companion_months"
        limit: int = self.ctx["params"][key]
        for d in self.declines:
            if d["product_code"] == pc and months_between(date.fromisoformat(d["declined_at"]), self.as_of) < limit:
                return d, limit
        return None

    def evaluate(self, r: Mapping[str, Any]) -> tuple[str, str | None, list[Clause]]:
        """Returns (outcome, detail, clauses) for one rule; appends a Candidate when ELIGIBLE."""
        ctx, pc = self.ctx, r["product_code"]
        if r.get("status") != "ACTIVE":
            return "RULE_INACTIVE", r.get("status"), []
        if r["type"] == "UPSELL" and get_path(ctx, "policy.lob") != r["lob"]:
            return "NOT_APPLICABLE", "upsell applies to renewing policy LOB only", []
        if r.get("applies_when_holding") and not set(r["applies_when_holding"]) & self.active:
            return "NOT_APPLICABLE", "prerequisite holding absent", []
        if pc in self.active:                                                   # EL-01
            return "ALREADY_COVERED", None, []
        if pc in self.embedded:                                                 # EL-02
            return "COVERED_BY_ENDORSEMENT", None, []
        hit = self._cooldown_hit(pc)                                            # EL-03
        if hit:
            return "COOLDOWN_ACTIVE", f"declined {hit[0]['declined_at']}, cooldown {hit[1]}m", []
        bad = _bad_facts(ctx, r.get("required_facts", []))                      # EL-06
        if bad:
            return "DATA_INTEGRITY_FAIL", ",".join(f"{f}={fact_status(ctx, f)}" for f in bad), []
        if r.get("risk_class") in self.risk_filter["applies_to_risk_class"]:   # EL-05
            lg = Logic(ctx)
            if lg.ev(self.risk_filter["when_risky"]):
                return "DISQUALIFIED_RISK", None, lg.trace
        if r.get("referral_when"):                                              # underwriting referral
            lg = Logic(ctx)
            if lg.ev(r["referral_when"]):
                self.referrals.append(r["id"])
                return "REFERRAL_REQUIRED", None, lg.trace
        qual = Logic(ctx)                                                       # qualification
        if not qual.ev(r["when"]):
            return "NOT_TRIGGERED", None, qual.trace
        tm = self.products.get(pc, {}).get("target_market")                     # EL-04
        if tm is not None:
            lt = Logic(ctx)
            if not lt.ev(tm):
                return "TARGET_MARKET_MISMATCH", None, lt.trace
        pricing = self.pricer(r, ctx, self.catalog)                             # PR-01
        if pricing is None:
            return "DISQUALIFIED_NO_VERIFIED_PRICE", None, []
        self.candidates.append(Candidate(r["id"], r["type"], pc, r["priority_tier"], r["sequence"],
                                         r.get("exclusion_group"), pricing))
        return "ELIGIBLE", None, qual.trace


def _rank_and_select(candidates: list[Candidate], max_recommendations: int) -> list[Candidate]:
    """BR-08/BR-09: tier, then larger bundle saving, then sequence, then rule id. One per exclusion group."""
    candidates.sort(key=lambda c: (c.priority_tier, -Decimal(c.pricing["bundle_saving_annual"]),
                                   c.sequence, c.rule_id))
    used_groups: set[str] = set()
    picked: list[Candidate] = []
    for c in candidates:
        if c.exclusion_group and c.exclusion_group in used_groups:
            c.selection = "EXCLUDED_BY_GROUP"
            continue
        if len(picked) < max_recommendations:
            c.selection = "PRIMARY" if not picked else "ALTERNATIVE"
            picked.append(c)
            if c.exclusion_group:
                used_groups.add(c.exclusion_group)
    return picked


def evaluate(context: Mapping[str, Any], catalog: Mapping[str, Any], as_of: date, *,
             pricer: Pricer) -> DecisionResult:
    """Decide which upsell / cross-sell (if any) is eligible for one renewal. Never mutates ``context``."""
    ctx: dict[str, Any] = copy.deepcopy(dict(context))
    ctx["params"] = {k: v["value"] for k, v in catalog["parameters"].items()}
    input_hash = canonical_hash(context)
    version: str = catalog["version"]
    outcomes: list[RuleOutcome] = []

    if not _check_window(ctx, catalog, outcomes):
        return DecisionResult("NOT_TRIGGERED", [], None, None, [], outcomes, version, input_hash, [])

    reasons = _run_gatekeepers(ctx, catalog, outcomes)
    if reasons:
        return DecisionResult("SUPPRESSED", reasons, None, None, [], outcomes, version, input_hash, [])

    stage = _OpportunityStage(ctx, catalog, as_of, pricer)
    for r in catalog["rules"]:
        outcome, detail, clauses = stage.evaluate(r)
        outcomes.append(RuleOutcome(r["id"], "OPPORTUNITY", outcome, r["product_code"], detail, clauses))

    picked = _rank_and_select(stage.candidates, catalog["parameters"]["max_recommendations"]["value"])
    return DecisionResult("RECOMMENDATIONS_AVAILABLE" if picked else "NO_OPPORTUNITY", [],
                          picked[0].rule_id if picked else None,
                          picked[1].rule_id if len(picked) > 1 else None,
                          stage.candidates, outcomes, version, input_hash, stage.referrals)
