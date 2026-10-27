from pydantic import BaseModel, Field


class UpdateClaimDataRequest(BaseModel):
    gw_claim_id: str = Field(
        ...,
        description="Guidewire internal claim ID (e.g. cc:SqTDkFc6t13uqJpTH_Kub) returned by submit_fnol",
    )
