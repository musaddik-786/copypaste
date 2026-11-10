from pydantic import BaseModel, Field


class GetFnolDataRequest(BaseModel):
    claim_number: str = Field(
        ...,
        description="ClaimCenter claim number to look up, e.g. '000-00-004122'",
    )
