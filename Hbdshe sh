from __future__ import annotations

from typing import Any, Optional

from pydantic import BaseModel, ConfigDict


class SaveL1ResultRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    card: dict[str, Any]
    l1: Optional[dict[str, Any]] = None
    evidence: Optional[dict[str, Any]] = None
    similar: Optional[dict[str, Any]] = None
    user: str = "analyst"


class SaveL2ResultRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    l2: dict[str, Any]
    user: str = "analyst"


class SaveL3ResultRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    l3: dict[str, Any]
    run_by: str
    user: str = "analyst"
