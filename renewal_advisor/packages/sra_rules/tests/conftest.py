"""Shared fixtures: the executable spec (rules/reference_evaluator) and the golden suite.

The reference evaluator is loaded by file path so that the tests always compare against the
checked-in specification, never a copy.
"""
from __future__ import annotations

import importlib.util
import sys
from datetime import date
from pathlib import Path
from types import ModuleType
from typing import Any

import pytest

REPO = Path(__file__).resolve().parents[3]
REF_DIR = REPO / "rules" / "reference_evaluator"


def _load(name: str, path: Path) -> ModuleType:
    spec = importlib.util.spec_from_file_location(name, path)
    assert spec and spec.loader
    mod = importlib.util.module_from_spec(spec)
    sys.modules[name] = mod
    spec.loader.exec_module(mod)
    return mod


# run_golden imports `sra_reference` from its own directory.
if str(REF_DIR) not in sys.path:
    sys.path.insert(0, str(REF_DIR))
REFERENCE = _load("sra_reference", REF_DIR / "sra_reference.py")
RUN_GOLDEN = _load("run_golden", REF_DIR / "run_golden.py")

CATALOG: dict[str, Any] = RUN_GOLDEN.CATALOG
PERSONAS: dict[str, Any] = RUN_GOLDEN.PERSONAS
SUITE: dict[str, Any] = RUN_GOLDEN.SUITE
AS_OF = date.fromisoformat(SUITE["as_of"])
GOLDEN_TESTS: list[dict[str, Any]] = SUITE["tests"]


@pytest.fixture(scope="session")
def catalog() -> dict[str, Any]:
    return CATALOG


@pytest.fixture(scope="session")
def as_of() -> date:
    return AS_OF
