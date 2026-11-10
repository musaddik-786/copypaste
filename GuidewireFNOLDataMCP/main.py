"""
main.py
───────
MCP server entry point for the Guidewire FNOL Data tool — hosts a single
MCP sub-app (port 7740) that fetches FNOL/claim data from Guidewire
ClaimCenter by claim number.

Registered sub-apps:
  /api/v1/fnol_data   — Guidewire FNOL Data Lookup   [gw_get_fnol_data]

Run:
    python main.py
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from dotenv import load_dotenv, find_dotenv
load_dotenv(find_dotenv())

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi_mcp import FastApiMCP

from fnol_data_router import router as fnol_data_router

import uvicorn


app = FastAPI(docs_url="/docs", title="Guidewire FNOL Data MCP Server")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


def _make_cors_app(title: str, description: str = "") -> FastAPI:
    sub = FastAPI(title=title, description=description)
    sub.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_methods=["*"],
        allow_headers=["*"],
    )
    return sub


# ── Sub-app: fnol_data ────────────────────────────────────────────────────────

fnol_data_app = _make_cors_app(
    title="fnol_data_agent_mcps",
    description="MCP tool for fetching FNOL/claim data from Guidewire ClaimCenter by claim number.",
)
fnol_data_app.include_router(fnol_data_router)
FastApiMCP(
    fnol_data_app,
    include_operations=[
        "gw_get_fnol_data",
    ],
).mount_http()
app.mount("/api/v1/fnol_data", fnol_data_app)


# ── Health ──────────────────────────────────────────────────────────────────

@app.get("/health")
def health():
    return {
        "status": "healthy",
        "service": "guidewire_fnol_data_mcp",
        "sub_apps": ["fnol_data"],
    }


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=7740)
