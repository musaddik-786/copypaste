"""Smart Renewal Advisor - deterministic decision engine. No I/O, no clock, no LLM (ADR-001)."""
from sra_rules.engine import evaluate
from sra_rules.model import Candidate, DecisionResult, Pricer, RuleOutcome, result_to_dict

__all__ = ["Candidate", "DecisionResult", "Pricer", "RuleOutcome", "evaluate", "result_to_dict"]
