"""Canonical hashing of the decision input (reproducibility / replay, CTL-12)."""
from __future__ import annotations

import hashlib
import json
from typing import Any


def canonical_hash(obj: Any) -> str:
    """sha256 of sorted-key JSON; identical to the reference evaluator so input hashes are comparable."""
    return hashlib.sha256(json.dumps(obj, sort_keys=True, default=str).encode()).hexdigest()
