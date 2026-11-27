"""
handler.py — Orchestrator (state/persistence)
────────────────────────────────────────────────
The Orchestrator Agent's OWN tools -- not a ticket-domain agent's logic.
Lets the LLM-driven orchestrator read a ticket's current run state before
continuing to a later stage, and persist each stage's already-computed
result into fix_runs -- the exact same table/shape app/routers/fix.py and
app/routers/orchestrator.py already use (imported directly, not
duplicated), so GET /api/orchestrator/{ticket_id} keeps working unchanged
regardless of which path wrote the run.
"""
from __future__ import annotations

import sys
from pathlib import Path
from typing import Any, Optional

_ROOT = Path(__file__).resolve().parents[3]
if str(_ROOT) not in sys.path:
    sys.path.insert(0, str(_ROOT))

from app.routers.fix import audit, load_run, save_run  # noqa: E402


def get_ticket_run(ticket_id: str) -> dict:
    """
    Returns the ticket's current orchestrator run state: stage, status,
    run_by, and outputs (whichever of card/l1/evidence/similar/l2/l3/
    decision/resolution have been saved so far). Call this before L2 or L3
    to retrieve the card/evidence/L1 output an earlier stage already saved,
    instead of relying on this conversation's own history.
    """
    return load_run(ticket_id)


def save_l1_result(
    ticket_id: str, card: dict[str, Any],
    l1: Optional[dict[str, Any]] = None, evidence: Optional[dict[str, Any]] = None,
    similar: Optional[dict[str, Any]] = None, user: str = "analyst",
) -> dict:
    """
    Persists the L1 stage's result: the KB Matching Agent's own result for
    `card` (always -- including its matched=false/reason/missing_info/
    candidates shape when nothing matched, so the UI can show *why*, instead
    of silently showing nothing), the L1 checklist and collected evidence
    (only when a card actually matched), and (if gathered) the Similar
    Incident Retrieval result.
    """
    run = load_run(ticket_id)
    if run["status"] == "closed":
        raise ValueError("This ticket is closed.")
    out = run["outputs"]
    out.update(card=card, l1=l1, evidence=evidence)
    if similar is not None:
        out["similar"] = similar
    run.update(stage="l1", status="open", outputs=out, run_by=run.get("run_by"))
    save_run(run)
    audit(ticket_id, "stage_run", user, {"stage": "l1", "source": "ai", "matched": bool(card.get("matched", True))})
    return run


def save_l2_result(ticket_id: str, l2: dict[str, Any], user: str = "analyst") -> dict:
    """Persists the L2 Diagnostic Agent's result (conclusion, needs_data_fix, checks)."""
    run = load_run(ticket_id)
    if run["status"] == "closed":
        raise ValueError("This ticket is closed.")
    out = run["outputs"]
    out["l2"] = l2
    run.update(stage="l2", status="open", outputs=out, run_by=run.get("run_by"))
    save_run(run)
    audit(ticket_id, "stage_run", user, {"stage": "l2", "source": "ai"})
    return run


def save_l3_result(ticket_id: str, l3: dict[str, Any], run_by: str, user: str = "analyst") -> dict:
    """Persists the L3 Remediation Proposal Agent's result (gosu script, guard, requirement).
    run_by is whoever ran L3 -- recorded so Human Approval can enforce no self-approval."""
    run = load_run(ticket_id)
    if run["status"] == "closed":
        raise ValueError("This ticket is closed.")
    out = run["outputs"]
    out["l3"] = l3
    run.update(stage="l3", status="open", outputs=out, run_by=run_by)
    save_run(run)
    audit(ticket_id, "stage_run", user, {"stage": "l3", "source": "ai"})
    return run
