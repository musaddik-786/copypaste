"""Run the golden decision tests against the reference evaluator.

    python -I rules/reference_evaluator/run_golden.py            # summary
    python -I rules/reference_evaluator/run_golden.py --trace SCN-01   # full trace for one test
Exit code 1 on any failure (use as CI gate).
"""
import copy
import json
import sys
from datetime import date
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
from sra_reference import evaluate, result_to_dict  # noqa: E402

ROOT = HERE.parent
CATALOG = json.loads((ROOT / "rule_catalog.v1.0.json").read_text(encoding="utf-8"))
PERSONAS = json.loads((ROOT / "golden" / "personas.json").read_text(encoding="utf-8"))
SUITE = json.loads((ROOT / "golden" / "golden_tests.json").read_text(encoding="utf-8"))


def set_path(d, path, value):
    parts = path.split(".")
    for p in parts[:-1]:
        d = d.setdefault(p, {})
    d[parts[-1]] = value


def get(d, path):
    for p in path.split("."):
        d = d[p]
    return d


def build(test):
    ctx = copy.deepcopy(PERSONAS[test["base"]])
    for k, v in test.get("set", {}).items():
        set_path(ctx, k, v)
    for k, items in test.get("remove", {}).items():
        lst = get(ctx, k)
        for i in items:
            lst.remove(i)
    return ctx


def check(test, res):
    e, errs = test["expect"], []
    if "status" in e and res.status != e["status"]:
        errs.append(f"status {res.status} != {e['status']}")
    for k in ("primary", "alternative"):
        if k in e and getattr(res, k) != e[k]:
            errs.append(f"{k} {getattr(res, k)} != {e[k]}")
    for s in e.get("suppression_includes", []):
        if s not in res.suppression_reasons:
            errs.append(f"missing suppression {s} (got {res.suppression_reasons})")
    for rid, oc in e.get("outcomes", {}).items():
        got = res.outcome_of(rid)
        if got != oc:
            errs.append(f"{rid} outcome {got} != {oc}")
    cands = {c.rule_id: c for c in res.candidates}
    for rid, fields in e.get("pricing", {}).items():
        if rid not in cands:
            errs.append(f"{rid} not a candidate"); continue
        for f, v in fields.items():
            if cands[rid].pricing.get(f) != v:
                errs.append(f"{rid}.{f} {cands[rid].pricing.get(f)} != {v}")
    for rid, sel in e.get("selection", {}).items():
        if rid not in cands or cands[rid].selection != sel:
            errs.append(f"{rid} selection {cands.get(rid) and cands[rid].selection} != {sel}")
    for rid in e.get("not_selected", []):
        if rid in (res.primary, res.alternative):
            errs.append(f"{rid} must not be selected")
    return errs


def main():
    as_of = date.fromisoformat(SUITE["as_of"])
    trace_id = sys.argv[2] if len(sys.argv) > 2 and sys.argv[1] == "--trace" else None
    failed = 0
    for t in SUITE["tests"]:
        res = evaluate(build(t), CATALOG, as_of)
        errs = check(t, res)
        mark = "PASS" if not errs else "FAIL"
        failed += bool(errs)
        print(f"[{mark}] {t['id']:7} {t['title']}  -> {res.status} primary={res.primary} alt={res.alternative}")
        for er in errs:
            print(f"         ! {er}")
        if trace_id == t["id"]:
            print(json.dumps(result_to_dict(res), indent=2, default=str))
    print(f"\n{len(SUITE['tests']) - failed}/{len(SUITE['tests'])} golden tests passed (catalog {CATALOG['version']})")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
