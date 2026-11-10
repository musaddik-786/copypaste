# Guidewire FNOL Data MCP

Standalone MCP server exposing a single tool, `gw_get_fnol_data`, that
fetches FNOL/claim data from Guidewire ClaimCenter by claim number.

Mirrors the project layout and conventions used in
`fullJarivs_Motor_LOB/Jarivs_Motor_LOB/PolicyholderAgents/MCP` (FastAPI +
`fastapi-mcp`, one `*_router.py` per sub-app, business logic in
`<tool>_mcp/handler.py`, Guidewire HTTP calls isolated in
`<tool>_mcp/guidewire_client.py`).

## Layout

```
GuidewireFNOLDataMCP/
├── main.py                    # FastAPI app, mounts the fnol_data sub-app on port 7740
├── fnol_data_router.py        # APIRouter — POST /gw_get_fnol_data
├── fnol_data_mcp/
│   ├── models.py               # Pydantic request model
│   ├── handler.py              # Business logic — calls guidewire_client, parses response
│   └── guidewire_client.py     # Raw HTTP call to Guidewire ClaimCenter
├── requirements.txt
├── .env.example                # Copy to .env and fill in real values
└── .env                         # Dummy placeholder — replace with real credentials
```

## Guidewire call

`GET {GW_CC_BASE_URL}/claim/v1/claims`

Filtered via the ClaimCenter Cloud API header-based filter syntax:

```
filter: claimNumber:eq:000-00-004122
```

Other headers (`authorization`, `accept`, `Content-Type`) are sent as
configured in `.env` — the rest (`Host`, `User-Agent`, `Accept-Encoding`,
`Connection`, `Postman-Token`, `Cookie`, duplicate lowercase `accept`) seen
in Postman are either set automatically by the HTTP client or
environment-specific noise, and are not needed here.

## Setup

```bash
cd GuidewireFNOLDataMCP
python3 -m venv venv
source venv/bin/activate   # on Windows: venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env       # then fill in GW_USERNAME / GW_PASSWORD (or GW_AUTHORIZATION) with real credentials
python main.py
```

Server starts on **port 7740**.

- Health check: `GET http://localhost:7740/health`
- Swagger docs for the sub-app: `http://localhost:7740/api/v1/fnol_data/docs`
- MCP endpoint: `http://localhost:7740/api/v1/fnol_data/mcp`

## Tool

### `gw_get_fnol_data`

`POST /api/v1/fnol_data/gw_get_fnol_data`

Request body:

```json
{
  "claim_number": "000-00-004122"
}
```

Response (found):

```json
{
  "found": true,
  "claim_number": "000-00-004122",
  "data": {
    "claim_id": "...",
    "claim_number": "000-00-004122",
    "loss_date": "...",
    "report_date": "...",
    "status": "...",
    "loss_cause": "...",
    "loss_type": "...",
    "loss_description": "...",
    "policy_number": "...",
    "insured_name": "...",
    "loss_location": "...",
    "adjuster": "...",
    "raw": { "...": "full Guidewire response" }
  }
}
```

Response (not found):

```json
{
  "found": false,
  "claim_number": "000-00-004122",
  "message": "No claim found in Guidewire for claim number '000-00-004122'"
}
```

## Environment variables

| Variable | Description |
|---|---|
| `GW_CC_BASE_URL` | Guidewire ClaimCenter REST base URL |
| `GW_USERNAME` / `GW_PASSWORD` | Basic auth credentials — matches Postman's "Authorization" tab > Basic Auth. `requests` builds the `Authorization: Basic ...` header itself. |
| `GW_AUTHORIZATION` | Alternative to username/password: a pre-built `Authorization` header value (e.g. `Basic <base64>` or `Bearer <token>`). Takes priority over `GW_USERNAME`/`GW_PASSWORD` if set. |
| `GW_TIMEOUT_SECONDS` | Request timeout in seconds (default 30) |

## Wiring into the FNOL Orchestrator (optional)

To expose this tool to the existing FNOL Orchestrator
(`Jarvis_claims_agents_v3_copy_new/PolicyholderAgents/FNOLOrchestrator/server.py`),
add an `FNOL_DATA_MCP_URL` env var pointing at
`http://localhost:7740/api/v1/fnol_data/mcp` and wire it up the same way
the other `*_MCP_URL` variables are passed in, per the parent repo's
`CLAUDE.md`. No orchestrator code changes are required beyond consuming
the new tool.
