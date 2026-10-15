"""
Smart Renewal Advisor - REFERENCE decision evaluator (executable specification).

Purpose
-------
This is NOT production code. It is the executable form of the reconciled rule
catalog so that BA, Compliance and Engineering can agree on behaviour, and the
golden tests can run, before the production Decision Service is built.
The production `sra_rules` package must produce identical outcomes for every
golden test (contract test).

Design invariants (mirrored in CLAUDE.md)
-----------------------------------------
* Pure function: evaluate(context, catalog, as_of) -> DecisionResult. No I/O, no clock, no randomness.
* No LLM anywhere in this path. Eligibility, suppression, pricing and ranking are deterministic.
* Every rule produces a trace entry (fired or not), with the clause values that drove it.
* Money is Decimal, rounded ROUND_HALF_UP to 2 dp, only at defined points.
* Missing / unverified required facts => ineligible (Data Integrity Gate). Fail closed.
"""
from __future__ import annotations

import copy
import hashlib
import json
from dataclasses import dataclass, field, asdict
from datetime import date
from decimal import Decimal, ROUND_HALF_UP
from typing import Any

MISSING = object()
TWO_DP = Decimal("0.01")


# --------------------------------------------------------------------------- facts
def get_path(ctx: dict, path: str, default=MISSING):
    cur: Any = ctx
    for part in path.split("."):
        if isinstance(cur, dict) and part in cur:
            cur = cur[part]
        else:
            return default
    return cur


def fact_status(ctx: dict, path: str) -> str:
    """OK | MISSING | UNVERIFIED  (Data Integrity Gate)."""
    v = get_path(ctx, path)
    if v is MISSING or v is None:
        return "MISSING"
    if path in set(ctx.get("unverified_facts", [])):
        return "UNVERIFIED"
    return "OK"


# --------------------------------------------------------------------------- JsonLogic subset with trace
class Logic:
    """Minimal, side-effect free JsonLogic subset: var, ==, !=, <, <=, >, >=, and, or, !, in.
    Records every leaf comparison so the officer UI / audit can show *why*."""

    def __init__(self, ctx: dict):
        self.ctx = ctx
        self.trace: list[dict] = []

    def ev(self, node):
        if not isinstance(node, dict):
            return node
        (op, args), = node.items()
        if op == "var":
            v = get_path(self.ctx, args if isinstance(args, str) else args[0])
            return None if v is MISSING else v
        if op == "and":
            return all(self.ev(a) for a in args)          # short-circuit, like JsonLogic
        if op == "or":
            return any(self.ev(a) for a in args)
        if op == "!":
            return not self.ev(args[0] if isinstance(args, list) else args)
        a, b = (self.ev(x) for x in args)
        if op == "in":
            res = a in (b or [])
        elif op in ("==", "!="):
            res = (a == b) if op == "==" else (a != b)
        else:
            if a is None or b is None:
                res = False                                  # comparisons with unknowns never pass
            else:
                res = {"<": a < b, "<=": a <= b, ">": a > b, ">=": a >= b}[op]
        self.trace.append({"op": op, "left": _label(args[0]), "left_value": a,
                           "right": _label(args[1]), "right_value": b, "result": res})
        return res


def _label(n):
    if isinstance(n, dict) and "var" in n:
        return n["var"]
    return n


# --------------------------------------------------------------------------- result types
@dataclass
class RuleOutcome:
    rule_id: str
    stage: str
    outcome: str
    product_code: str | None = None
    detail: str | None = None
    clauses: list = field(default_factory=list)


@dataclass
class Candidate:
    rule_id: str
    type: str
    product_code: str
    priority_tier: str
    sequence: int
    exclusion_group: str | None
    pricing: dict
    selection: str = "NOT_SELECTED"


@dataclass
class DecisionResult:
    status: str                          # NOT_TRIGGERED | SUPPRESSED | NO_OPPORTUNITY | RECOMMENDATIONS_AVAILABLE
    suppression_reasons: list
    primary: str | None
    alternative: str | None
    candidates: list
    outcomes: list
    catalog_version: str
    input_hash: str
    referrals: list

    def outcome_of(self, rule_id: str) -> str | None:
        for o in self.outcomes:
            if o.rule_id == rule_id:
                return o.outcome
        return None


# --------------------------------------------------------------------------- helpers
def months_between(d1: date, d2: date) -> float:
    """Whole + fractional months from d1 to d2 (d2 >= d1)."""
    m = (d2.year - d1.year) * 12 + (d2.month - d1.month)
    if d2.day < d1.day:
        m -= 1
    return m


def q2(x: Decimal) -> Decimal:
    return x.quantize(TWO_DP, rounding=ROUND_HALF_UP)


def canonical_hash(obj) -> str:
    return hashlib.sha256(json.dumps(obj, sort_keys=True, default=str).encode()).hexdigest()


# --------------------------------------------------------------------------- pricing (deterministic)
def price_candidate(rule: dict, ctx: dict, catalog: dict) -> dict | None:
    """Uses ONLY verified PAS quotes from the snapshot. Never invents a price (BR-12)."""
    pc = rule["product_code"]
    quote = ctx.get("pas_quotes", {}).get(pc)
    if not quote or quote.get("verified") is not True:
        return None
    annual = Decimal(str(quote["annual_gross"]))
    renewal = Decimal(str(get_path(ctx, "policy.renewal_premium")))
    expiring = Decimal(str(get_path(ctx, "policy.expiring_premium")))
    out = {"expiring_premium": str(q2(expiring)), "base_renewal_premium": str(q2(renewal)),
           "incremental_annual": str(q2(annual)), "incremental_monthly_equiv": str(q2(annual / 12)),
           "bundle_discount_pct": "0", "bundle_saving_annual": "0.00"}
    if rule["type"] == "UPSELL":
        out["net_annual_total"] = str(q2(renewal + annual))
        out["presentation"] = "CONSOLIDATED_INTO_RENEWAL"
    else:
        pct = Decimal(str(catalog["bundle_discounts"]["by_companion_product"].get(pc, 0)))
        saving = q2((renewal + annual) * pct / 100)
        out.update({"bundle_discount_pct": str(pct), "bundle_saving_annual": str(saving),
                    "companion_standalone_annual": str(q2(annual)),
                    "net_annual_total": str(q2(renewal + annual - saving)),
                    "presentation": "SEPARATE_POLICY_ITEMISED"})     # IDD Art. 24: show components separately
    return out


# --------------------------------------------------------------------------- main pipeline
def evaluate(context: dict, catalog: dict, as_of: date) -> DecisionResult:
    ctx = copy.deepcopy(context)
    ctx["params"] = {k: v["value"] for k, v in catalog["parameters"].items()}
    outcomes: list[RuleOutcome] = []
    input_hash = canonical_hash(context)
    version = catalog["version"]

    # Stage 0 - operational window (BR-01)
    w = catalog["window_rule"]
    lg = Logic(ctx)
    if not get_path(ctx, "quote", None) or not lg.ev(w["when"]):
        outcomes.append(RuleOutcome(w["id"], "WINDOW", "NOT_TRIGGERED", clauses=lg.trace))
        return DecisionResult("NOT_TRIGGERED", [], None, None, [], outcomes, version, input_hash, [])
    outcomes.append(RuleOutcome(w["id"], "WINDOW", "PASSED", clauses=lg.trace))

    # Stage 1 - gatekeepers: evaluate ALL (complete audit), suppress if ANY fires. Fail closed on bad data.
    reasons = []
    for gk in catalog["gatekeepers"]:
        if gk.get("status") != "ACTIVE":
            continue
        bad = [f for f in gk.get("required_facts", []) if fact_status(ctx, f) != "OK"]
        if bad:
            outcomes.append(RuleOutcome(gk["id"], "GATEKEEPER", "SUPPRESS_DATA_INTEGRITY", detail=",".join(bad)))
            reasons.append(f"{gk['id']}:DATA_INTEGRITY")
            continue
        lg = Logic(ctx)
        fired = lg.ev(gk["suppress_when"])
        outcomes.append(RuleOutcome(gk["id"], "GATEKEEPER", "SUPPRESS" if fired else "PASSED",
                                    detail=gk["reason_code"] if fired else None, clauses=lg.trace))
        if fired:
            reasons.append(f"{gk['id']}:{gk['reason_code']}")
    if reasons:
        return DecisionResult("SUPPRESSED", reasons, None, None, [], outcomes, version, input_hash, [])

    # Stage 2 - opportunity rules through the ordered candidate filters
    active = set(get_path(ctx, "portfolio.active_products", []) or [])
    embedded = set(get_path(ctx, "portfolio.embedded_covers", []) or [])
    declines = get_path(ctx, "history.declines", []) or []
    risk_filter = next(f for f in catalog["candidate_filters"] if f["id"] == "EL-05")
    products = catalog["products"]
    candidates: list[Candidate] = []
    referrals: list[str] = []

    for r in catalog["rules"]:
        pc = r["product_code"]
        def done(outcome, detail=None, clauses=None):
            outcomes.append(RuleOutcome(r["id"], "OPPORTUNITY", outcome, pc, detail, clauses or []))

        if r.get("status") != "ACTIVE":
            done("RULE_INACTIVE", r.get("status")); continue
        if r["type"] == "UPSELL" and get_path(ctx, "policy.lob") != r["lob"]:
            done("NOT_APPLICABLE", "upsell applies to renewing policy LOB only"); continue
        if r.get("applies_when_holding") and not set(r["applies_when_holding"]) & active:
            done("NOT_APPLICABLE", "prerequisite holding absent"); continue
        # EL-01 / EL-02
        if pc in active:
            done("ALREADY_COVERED"); continue
        if pc in embedded:
            done("COVERED_BY_ENDORSEMENT"); continue
        # EL-03 cooldown (6m rider / 12m companion)
        cls = products.get(pc, {}).get("cooldown_class", "COMPANION")   # fail-safe: longer cooldown
        limit = ctx["params"]["cooldown_rider_months" if cls == "RIDER" else "cooldown_companion_months"]
        hit = [d for d in declines if d["product_code"] == pc
               and months_between(date.fromisoformat(d["declined_at"]), as_of) < limit]
        if hit:
            done("COOLDOWN_ACTIVE", f"declined {hit[0]['declined_at']}, cooldown {limit}m"); continue
        # EL-06 data integrity
        bad = [f"{f}={fact_status(ctx, f)}" for f in r.get("required_facts", []) if fact_status(ctx, f) != "OK"]
        if bad:
            done("DATA_INTEGRITY_FAIL", ",".join(bad)); continue
        # EL-05 risk quality gate
        if r.get("risk_class") in risk_filter["applies_to_risk_class"]:
            lg = Logic(ctx)
            if lg.ev(risk_filter["when_risky"]):
                done("DISQUALIFIED_RISK", clauses=lg.trace); continue
        # Underwriting referral (e.g. ZUeRS zone 4) - informational, never a recommendation
        if r.get("referral_when"):
            lg = Logic(ctx)
            if lg.ev(r["referral_when"]):
                referrals.append(r["id"]); done("REFERRAL_REQUIRED", clauses=lg.trace); continue
        # Qualification
        lg = Logic(ctx)
        if not lg.ev(r["when"]):
            done("NOT_TRIGGERED", clauses=lg.trace); continue
        # EL-04 target market (IDD POG)
        tm = products.get(pc, {}).get("target_market")
        if tm is not None:
            lt = Logic(ctx)
            if not lt.ev(tm):
                done("TARGET_MARKET_MISMATCH", clauses=lt.trace); continue
        # PR-01 verified pricing
        pricing = price_candidate(r, ctx, catalog)
        if pricing is None:
            done("DISQUALIFIED_NO_VERIFIED_PRICE"); continue
        done("ELIGIBLE", clauses=lg.trace)
        candidates.append(Candidate(r["id"], r["type"], pc, r["priority_tier"], r["sequence"],
                                    r.get("exclusion_group"), pricing))

    # Stage 3 - ranking & selection (BR-08 / BR-09)
    candidates.sort(key=lambda c: (c.priority_tier, -Decimal(c.pricing["bundle_saving_annual"]), c.sequence, c.rule_id))
    used_groups, picked = set(), []
    for c in candidates:
        if c.exclusion_group and c.exclusion_group in used_groups:
            c.selection = "EXCLUDED_BY_GROUP"; continue
        if len(picked) < catalog["parameters"]["max_recommendations"]["value"]:
            c.selection = "PRIMARY" if not picked else "ALTERNATIVE"
            picked.append(c)
            if c.exclusion_group:
                used_groups.add(c.exclusion_group)
    status = "RECOMMENDATIONS_AVAILABLE" if picked else "NO_OPPORTUNITY"
    return DecisionResult(status, [], picked[0].rule_id if picked else None,
                          picked[1].rule_id if len(picked) > 1 else None,
                          candidates, outcomes, version, input_hash, referrals)


def result_to_dict(res: DecisionResult) -> dict:
    d = asdict(res)
    return d
