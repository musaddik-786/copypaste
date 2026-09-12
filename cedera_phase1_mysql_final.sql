handler.py
def get_treaty_info(treaty_number):
    info = "select * from treaties where treaty_number = treaty_ref"
    return info



main.py

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "common"))

from dotenv import load_dotenv, find_dotenv
load_dotenv(find_dotenv())

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi_mcp import FastApiMCP

from init_db import init_db

# from voice_text_intake_router import router as voice_text_intake_router
# from duplicate_check_router import router as duplicate_check_router
# from segmentation_router import router as segmentation_router
# from claim_status_router import router as claim_status_router
from treaty_router import router as treaty_router
# from feedback_router import router as feedback_router
# from policy_coverage_router import router as policy_coverage_router
from claim_readiness_router import router as claim_readiness_router
# from communication_router import router as communication_router

import uvicorn



app = FastAPI(docs_url="/docs", title = "Cedera")

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

treaty_app = _make_cors_app(
    title = "treaty management agent",
    description="mcp tools for treaty management",
)

treaty_app.include_routers(treaty_router)
FastApiMCP(
    document_submission_app,
    include_operations=[
        "treaty_management_mcp",
    ],
).mount_http()
app.mount("/api/v1/treaty_management_mcp", treaty_app)




treaty_router.py
import logging
from fastapi import APIRouter
from pydantic import BaseModel
from typing import Optional

from claim_readiness_mcp import handler

log = logging.getLogger(__name__)

router = APIRouter()


class TreatyManagement(BaseModel):
    """
    it accepts treaty number
    """
    treaty_numnber: int


@router.post(
    "/treaty_management_mcp",
    operation_id = "treaty_management_mcp"    
)

def get_treaty(req: TreatyManagement):
    """
    returns treaty information from the database
    """
    return handler.get_treaty_info(treaty_number)



