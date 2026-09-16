I had a fire incident at 9 AM while I was at home. The incident occurred in the kitchen and caused damage to the flooring and cabinets. This happened today. It happened all of a sudden, and the damage was serious. I am very stressed.
Thankyouforreachingout,andI'mverysorrytohearaboutthefireinyourhome.Iunderstandthisisastressfulsituation,andI'mheretohelpyouthroughtheclaimsprocess.Toproceed,couldyoupleaseprovideyourpolicynumber?Thiswillhelpmelocateyourpolicyandstartyourclaimrightaway.
4061807702
[Tool: get_fnol_by_policy] Starting...[Tool: get_fnol_by_policy] Done[Tool: create_fnol_submission] Starting...[Tool: create_fnol_submission] Done[Tool: get_mandatory_fields] Starting...[Tool: get_mandatory_fields] Done[Tool: extract_fnol_fields_from_text] Starting...[Tool: extract_fnol_fields_from_text] Done[Tool: log_question_answer] Starting...[Tool: log_question_answer] DoneIhavecapturedmostofthedetailsaboutyourfireincident.Couldyoupleaseprovidemoreinformationaboutwhatcausedthefire?Forexample,wasitduetoanappliancemalfunction,cookingaccident,electricalissue,orsomethingelse?Thiswillhelpmeaccuratelycompleteyourclaim.
electrical
[Tool: extract_fnol_fields_from_text] Starting...[Tool: log_question_answer] Starting...[Tool: log_question_answer] Done[Tool: extract_fnol_fields_from_text] Done[Tool: update_fnol_submission] Starting...[Tool: save_field_attribution] Starting...[Tool: save_field_attribution] Done[Tool: update_fnol_submission] DoneThankyouforconfirmingthecauseofthefireaselectrical.Ihavemostofyourincidentdetails,butforyourclaimtoproceed,Ineedtoconfirmthefollowing:-Yourlosstype(Isthisincidentbestdescribedasa"Fire"?)-Theexactdateofloss(Didtheincidenthappentoday,asinSeptember,?)Couldyoupleaseconfirmbothofthesedetailsforme?
it happened today
[Tool: extract_fnol_fields_from_text] Starting...[Tool: log_question_answer] Starting...[Tool: log_question_answer] Done[Tool: extract_fnol_fields_from_text] Done[Tool: update_fnol_submission] Starting...[Tool: save_field_attribution] Starting...[Tool: save_field_attribution] Done[Tool: update_fnol_submission] Done[Tool: create_fnol_submission] Starting...[Tool: create_fnol_submission] Done[Tool: update_fnol_submission] Starting...[Tool: get_mandatory_fields] Starting...[Tool: get_mandatory_fields] Done[Tool: update_fnol_submission] Done[Tool: update_fnol_submission] Starting...[Tool: update_fnol_submission] DoneHereisasummaryofyourclaimdetails:-Losstype:Fire-Causeofloss:Electrical-Dateofloss:-09-(today)-Timeofloss:09:00-Areaaffected:Kitchen,includingflooringandcabinets-Propertyoccupancy:Yes,youwereathome-Suddenvs.Gradual:Sudden-Severity:High-Emotionalcontext:YouareverystressedPleaseconfirmthatallofthesedetailsarecorrect,orletmeknowifanychangesareneededbeforeIsubmityourclaim.
yes confirmed
[Tool: update_fnol_submission] Starting...[Tool: update_fnol_submission] Done[Tool: get_fnol_by_policy] Starting...[Tool: get_fnol_by_policy] Done[Tool: update_fnol_submission] Starting...[Tool: update_fnol_submission] Done[Tool: submit_fnol] Starting...[Tool: submit_fnol] DoneYourclaimhasbeensuccessfullysubmitted.Herearethedetails:-Losstype:Fire-Cause:Electrical-Dateofloss:Today(-09-)-Timeofloss:09:00-Areaaffected:Kitchen,flooring,andcabinets-Severity:High-Youconfirmedyouwereathome,thedamagewassudden,andyouareverystressed.Yourassignedclaimnumberis:CLM--023.Aclaimsrepresentativewillcontactyousoontohelpwiththenextsteps.Ifyouneedurgentsupportorfurtherassistance,pleaseletusknow.End
Claim # detected: CLM--023

again it is sayin claim 023 man why is this happening

below was my earlier code it worked absolutely fine for homeowbers


"""
server.py — Voice/Text Intake Agent (Policyholder)
─────────────────────────────────────────────────────
LangGraph-based FastAPI agent that captures FNOL via text or
voice (recorded in browser, transcribed via gpt-4o-transcribe-diarize REST).

Port: 8001
MCP : http://localhost:8000/api/v1/voice_text_intake/mcp

Run:
    py -3 server.py
"""

import asyncio
import json
import logging
import os
import sys
import time
import traceback
from datetime import datetime, timedelta
from typing import Annotated, List, Optional, TypedDict

import httpx
import uvicorn
from dotenv import load_dotenv, find_dotenv
from fastapi import FastAPI, File, Request, UploadFile
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, StreamingResponse
from langchain_core.messages import AIMessage, HumanMessage, SystemMessage
from langchain_mcp_adapters.client import MultiServerMCPClient
from langchain_openai.chat_models import AzureChatOpenAI
from langgraph.graph import END, START, StateGraph
from langgraph.graph.message import add_messages
from langgraph.prebuilt import ToolNode

load_dotenv(find_dotenv())

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
    stream=sys.stdout,
    force=True,
)
logger = logging.getLogger("voice_text_intake_agent")

PHOENIX_API_KEY = os.getenv("PHOENIX_API_KEY", "")
PHOENIX_ENDPOINT = os.getenv("PHOENIX_ENDPOINT", "")
MCP_URL = os.getenv("MCP_URL", "http://localhost:8000/api/v1/voice_text_intake/mcp")
AGENT_PORT = int(os.getenv("AGENT_PORT", "8001"))

WHISPER_ENDPOINT = os.getenv(
    "AZURE_WHISPER_ENDPOINT",
    "https://azureclaimsopenai.openai.azure.com/openai/deployments/gpt-4o-transcribe-diarize/audio/transcriptions?api-version=2025-03-01-preview",
)
WHISPER_API_KEY = os.getenv("AZURE_WHISPER_API_KEY") or os.getenv("AZURE_OPENAI_API_KEY", "")

config_mcp_server = {
    "voice_text_intake_mcp": {
        "url": MCP_URL,
        "transport": "streamable_http",
        "timeout": timedelta(seconds=120),
        "sse_read_timeout": timedelta(seconds=600),
    },
}

app = FastAPI(title="Voice/Text Intake Agent (Policyholder)")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class ChatTurn(BaseModel):
    role: str
    content: str


class ChatRequest(BaseModel):
    message: str = "Start FNOL intake"
    input_type: Optional[str] = None
    history: List[ChatTurn] = []


class State(TypedDict):
    messages: Annotated[list, add_messages]


def router(state: State):
    last = state["messages"][-1]
    if isinstance(last, AIMessage) and getattr(last, "tool_calls", None):
        return "tools"
    if isinstance(last, AIMessage) and last.content:
        if "Continue" in last.content:
            return "tools"
        if "End" in last.content:
            return "End"
    return "End"


_FALLBACK_PROMPT = """
You are the Voice/Text Intake Agent for an insurance claims management platform.

Your role is to capture a First Notice of Loss (FNOL) from a policyholder.
The policyholder's message may be:
  - Typed text
  - A server-transcribed voice recording (input_type="voice_transcript")

Messages may begin with a [POLICY_CONTEXT: ...] tag containing pre-verified policy
details (policy_number, policyholder_name, policyholder_address, status, coverage_type, effective_date).
If this tag is present:
  - DO NOT ask for the policy number, policyholder name, or policyholder address — you already have them.
  - Extract policy_number from the tag and immediately call get_fnol_by_policy.
  - Call create_fnol_submission (or resume the existing draft) then immediately call
    update_fnol_submission to set policy_number, policyholder_name, and policyholder_address
    from the tag values.
  - Call save_field_attribution for each of those three fields with source="guidewire_lookup"
    so the audit trail records they were auto-filled from Guidewire.
  - Proceed directly to collecting loss details — do not ask for any policy information.

Follow this workflow exactly:

1. IDENTIFY THE POLICYHOLDER
   - If [POLICY_CONTEXT:] is present, extract policy_number from it — skip asking.
   - Otherwise ask for their policy number.
   - Call get_fnol_by_policy to check for any existing open FNOL submissions.
   - If an open draft exists, resume it; otherwise call create_fnol_submission.

2. COLLECT LOSS DETAILS (conversational Q&A)
   - Call get_mandatory_fields to retrieve the required field list.
   - For each mandatory field not yet captured, ask the policyholder the
     corresponding inference_question from the mandatory fields list.
   - After each answer, call log_question_answer to persist the exchange.

3. EXTRACT FIELDS FROM THE USER'S MESSAGE
   - Call extract_fnol_fields_from_text directly with the user's message as
     raw_text and the appropriate input_type ("voice_transcript" or "text").
     This automatically saves extraction + inference records.

4. AFTER EXTRACTION
   - Call update_fnol_submission to persist all extracted fields onto the FNOL.
   - Call save_field_attribution with source details for each field.
   - For any mandatory field still missing, ask the policyholder directly.
   - Keep calling log_question_answer for each follow-up exchange.

5. REVIEW & CONFIRM
   - Summarise all captured details back to the policyholder.
   - Ask them to confirm or correct any values.
   - Call update_fnol_submission for any corrections.

6. SUBMIT
   - Before calling submit_fnol, call update_fnol_submission one final time to
     make sure policyholder_name, policyholder_address, and policy_number are set — use
     values from [POLICY_CONTEXT:] if present. Do NOT skip this step even if
     you believe the fields were saved earlier.
   - Then call submit_fnol. This creates the claim record.
   - The tool will return {"claim_number": "CLM-XXXX", "status": "submitted"}.
     This is always a success — do NOT treat it as an error regardless of what
     the fnol record fields contain.
   - Report the assigned claim_number back to the policyholder.

Always be empathetic. The policyholder may be distressed. Keep questions
concise and clear. Do not ask for information you can already infer with
high confidence from prior input.

When you have completed the task, end your response with "End".
"""


def load_prompt() -> str:
    if not PHOENIX_ENDPOINT:
        raise RuntimeError("Phoenix not configured")
    from phoenix.client import Client
    client = Client(base_url=PHOENIX_ENDPOINT, api_key=PHOENIX_API_KEY)
    prompt = client.prompts.get(name="voice_text_intake_agent_policyholder", label="production")
    prompt_set = prompt._template["messages"]
    system_msg = next(
        (item["content"][0]["text"] for item in prompt_set if item.get("role") == "system"),
        None,
    )
    if not system_msg:
        raise ValueError("System prompt is empty or missing in Phoenix")
    return system_msg


def create_graph(model, tools, prompt):
    graph_builder = StateGraph(State)
    llm_with_tools = model.bind_tools(tools)

    async def agent_node(state: State):
        messages = state["messages"]
        all_messages = [SystemMessage(content=prompt)] + messages
        message = await llm_with_tools.ainvoke(all_messages)
        return {"messages": [message]}

    graph_builder.add_node("agent", agent_node)
    graph_builder.add_node("tools", ToolNode(tools=tools))
    graph_builder.add_edge(START, "agent")
    graph_builder.add_conditional_edges("agent", router, {"tools": "tools", "End": END})
    graph_builder.add_edge("tools", "agent")
    return graph_builder.compile()


async def get_tools():
    client = MultiServerMCPClient(config_mcp_server)
    tools = await client.get_tools()
    logger.info("Tools loaded from MCP: %s", [t.name for t in tools])
    return tools


async def stream_graph(graph, initial_state, config):
    async for event in graph.astream_events(initial_state, config=config, version="v2"):
        kind = event.get("event", "")

        if kind == "on_chat_model_stream":
            chunk = event["data"].get("chunk")
            if chunk and hasattr(chunk, "content") and chunk.content:
                yield f"data: {chunk.content}\n\n"

        elif kind == "on_tool_start":
            tool_name = event.get("name", "unknown_tool")
            yield f"data: [Tool: {tool_name}] Starting...\n\n"

        elif kind == "on_tool_end":
            tool_name = event.get("name", "unknown_tool")
            yield f"data: [Tool: {tool_name}] Done\n\n"


# ──────────────────────────────────────────────────────────────────────────────
# POST /transcribe — receive audio blob, call gpt-4o-transcribe-diarize REST
# ──────────────────────────────────────────────────────────────────────────────

def _convert_to_wav_16k(audio_bytes: bytes, src_mime: str) -> bytes:
    """Convert any audio format to WAV 16kHz mono PCM using ffmpeg."""
    import subprocess, tempfile, os
    suffix = ".webm" if "webm" in src_mime else ".ogg" if "ogg" in src_mime else ".mp4" if "mp4" in src_mime else ".audio"
    with tempfile.NamedTemporaryFile(suffix=suffix, delete=False) as src_f:
        src_f.write(audio_bytes)
        src_path = src_f.name
    out_path = src_path + ".wav"
    try:
        result = subprocess.run(
            ["ffmpeg", "-y", "-i", src_path,
             "-ar", "16000", "-ac", "1", "-c:a", "pcm_s16le", out_path],
            capture_output=True, timeout=30,
        )
        if result.returncode != 0:
            logger.warning("ffmpeg conversion failed: %s", result.stderr.decode()[:300])
            return audio_bytes  # fall back to original
        with open(out_path, "rb") as f:
            return f.read()
    finally:
        for p in (src_path, out_path):
            try:
                os.unlink(p)
            except OSError:
                pass


@app.post("/transcribe")
async def transcribe_audio(file: UploadFile = File(...)):
    load_dotenv(find_dotenv())
    audio_bytes = await file.read()
    src_mime = file.content_type or "audio/webm"

    # Convert to WAV 16kHz mono — dramatically improves transcription accuracy
    wav_bytes = await asyncio.get_running_loop().run_in_executor(
        None, _convert_to_wav_16k, audio_bytes, src_mime
    )
    send_bytes = wav_bytes
    send_name = "audio.wav"
    send_mime = "audio/wav"
    logger.info(
        "Transcribe: original %d bytes (%s) → WAV %d bytes",
        len(audio_bytes), src_mime, len(wav_bytes),
    )

    try:
        async with httpx.AsyncClient(timeout=60) as client:
            resp = await client.post(
                WHISPER_ENDPOINT,
                headers={"api-key": WHISPER_API_KEY},
                files={"file": (send_name, send_bytes, send_mime)},
                data={
                    "model": os.getenv("AZURE_WHISPER_DEPLOYMENT", "gpt-4o-transcribe-diarize"),
                    "language": "en",
                    "response_format": "json",
                },
            )
        if resp.status_code != 200:
            logger.error("Transcription API error %s: %s", resp.status_code, resp.text[:400])
            return JSONResponse(
                status_code=502,
                content={"error": f"Transcription failed ({resp.status_code})", "detail": resp.text[:400]},
            )
        data = resp.json()
        transcript = data.get("text", "")
        logger.info("Transcribed → %d chars: %s", len(transcript), transcript[:120])
        return {"transcript": transcript}
    except Exception as e:
        logger.exception("Transcription exception")
        return JSONResponse(status_code=500, content={"error": str(e)})


# ──────────────────────────────────────────────────────────────────────────────
# POST /chat — text or browser-transcribed voice input
# ──────────────────────────────────────────────────────────────────────────────

@app.post("/chat")
async def chat_stream(body: ChatRequest):
    load_dotenv(find_dotenv())

    tools = await get_tools()

    model = AzureChatOpenAI(
        api_key=os.getenv("AZURE_OPENAI_API_KEY"),
        api_version=os.getenv("AZURE_OPENAI_API_VERSION"),
        azure_deployment=os.getenv("AZURE_OPENAI_CHAT_DEPLOYMENT"),
        azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT"),
    )

    try:
        system_prompt = load_prompt()
    except Exception as e:
        logger.warning("Phoenix prompt load failed (%s) — using fallback prompt", e)
        system_prompt = _FALLBACK_PROMPT

    user_message = body.message
    if body.input_type:
        user_message = f"[input_type: {body.input_type}] {user_message}"

    # Rebuild full conversation history from client-supplied turns
    history_messages = []
    for turn in body.history:
        if not turn.content:
            continue
        if turn.role == "user":
            history_messages.append(HumanMessage(content=turn.content))
        elif turn.role == "assistant":
            history_messages.append(AIMessage(content=turn.content))
    history_messages.append(HumanMessage(content=user_message))

    graph = create_graph(model=model, tools=tools, prompt=system_prompt)

    async def generate():
        start = time.time()
        last_event_at = start
        last_tool = None
        try:
            async for event in stream_graph(
                graph=graph,
                initial_state={"messages": history_messages},
                config={"recursion_limit": 250},
            ):
                last_event_at = time.time()
                if isinstance(event, str) and event.startswith("data: [Tool:"):
                    try:
                        last_tool = event.split("[Tool:", 1)[1].split("]", 1)[0]
                    except Exception:
                        pass
                yield event
        except BaseException as e:
            elapsed = time.time() - start
            since_last = time.time() - last_event_at
            err = {
                "exception_class": type(e).__name__,
                "message": str(e),
                "elapsed_total_seconds": round(elapsed, 2),
                "seconds_since_last_event": round(since_last, 2),
                "last_tool_invoked": last_tool,
                "traceback": traceback.format_exc(),
                "timestamp_utc": datetime.utcnow().isoformat(),
            }
            logger.error("AGENT_ERROR %s", json.dumps(err, default=str))
            try:
                yield f"data: [AGENT_ERROR] {json.dumps(err, default=str)}\n\n"
            except Exception:
                pass
            import asyncio
            if isinstance(e, asyncio.CancelledError):
                raise

    return StreamingResponse(generate(), media_type="text/event-stream")


@app.get("/health")
async def health():
    return {"status": "healthy", "agent": "voice_text_intake_agent_policyholder"}


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=AGENT_PORT)



"""
fnol_handler.py
───────────────
DB operations for FNOL submissions, inferences, question log,
field attribution, and voice/text extractions.
Uses psycopg2 with RealDictCursor (Azure PostgreSQL).
"""

import logging
import random
from datetime import datetime, timedelta
from typing import Optional

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "common"))

from db import get_db_connection, row_to_dict  # noqa: E402
from policy_coverage_mcp import guidewire_client  # noqa: E402
from policy_coverage_mcp.handler import LOCAL_ONLY_POLICY_NUMBERS  # noqa: E402
from voice_text_intake_mcp.models import (
    CreateFnolSubmissionRequest,
    UpdateFnolSubmissionRequest,
    SaveVoiceTextExtractionRequest,
    SaveAiInferencesRequest,
    LogQuestionAnswerRequest,
    SaveFieldAttributionRequest,
)

log = logging.getLogger(__name__)


# ──────────────────────────────────────────────────────────────────────────────
# Loss type canonicalization
# ──────────────────────────────────────────────────────────────────────────────
# loss_type must always land in the DB as exactly one of these six values,
# regardless of how the LLM extraction or a human edit phrased it (e.g.
# "Fire damage", "water damage", "break-in" all need to collapse down to the
# canonical spelling below rather than being stored verbatim).
_CANONICAL_LOSS_TYPES = ["Fire", "Waterdamage", "Hurricane", "burglary", "Explosion", "Earthquake"]

_LOSS_TYPE_KEYWORD_MAP = {
    "Fire": ["fire", "burn", "smoke", "arson"],
    "Waterdamage": ["water", "flood", "leak", "pipe", "damp", "moisture"],
    "Hurricane": ["hurricane", "storm", "wind", "hail", "tornado", "cyclone", "typhoon"],
    "burglary": ["burglary", "burglar", "theft", "robbery", "break-in", "break in", "stolen", "intrusion"],
    "Explosion": ["explosion", "explode", "blast", "detonation"],
    "Earthquake": ["earthquake", "seismic", "quake", "tremor"],
}


def _normalize_loss_type(value):
    """
    Maps a freeform loss_type string onto one of _CANONICAL_LOSS_TYPES by
    keyword match. Already-canonical values pass through unchanged. Falls
    back to the trimmed original value if nothing matches, so unrecognized
    input isn't silently discarded.
    """
    if value is None:
        return value
    trimmed = value.strip()
    if trimmed in _CANONICAL_LOSS_TYPES:
        return trimmed
    lowered = trimmed.lower()
    for canonical, keywords in _LOSS_TYPE_KEYWORD_MAP.items():
        if any(keyword in lowered for keyword in keywords):
            return canonical
    log.warning("loss_type %r did not match any canonical category — storing as-is", value)
    return trimmed


# ──────────────────────────────────────────────────────────────────────────────
# FNOL Submissions
# ──────────────────────────────────────────────────────────────────────────────

def cleanup_draft_fnols_for_policy(policy_number: str, conn=None) -> int:
    """
    Delete all draft fnol_submissions for *policy_number* and their child rows.
    Called automatically before creating a new FNOL so reruns and error cases
    don't accumulate orphaned draft data.

    Returns the number of draft submissions removed.
    """
    _own_conn = conn is None
    if _own_conn:
        conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            "SELECT id FROM fnol_submissions WHERE policy_number = %s AND status = 'draft'",
            (policy_number,),
        )
        draft_ids = [r["id"] for r in cur.fetchall()]
        if not draft_ids:
            return 0

        placeholders = ",".join("%s" for _ in draft_ids)
        for child_table in (
            "fnol_ai_inferences",
            "fnol_voice_text_extraction",
            "fnol_mandatory_question_log",
            "fnol_field_attribution",
        ):
            cur.execute(
                f"DELETE FROM {child_table} WHERE fnol_id IN ({placeholders})",
                draft_ids,
            )
        cur.execute(
            f"DELETE FROM fnol_submissions WHERE id IN ({placeholders})",
            draft_ids,
        )
        if _own_conn:
            conn.commit()
        log.info("Cleaned up %d draft FNOL(s) for policy %s", len(draft_ids), policy_number)
        return len(draft_ids)
    except Exception:
        if _own_conn:
            conn.rollback()
        log.exception("cleanup_draft_fnols_for_policy failed for policy %s", policy_number)
        raise
    finally:
        if _own_conn:
            conn.close()


def create_fnol_submission(req: CreateFnolSubmissionRequest) -> dict:
    # Auto-generate fnol_number if the LLM didn't supply one (#6)
    if not req.fnol_number:
        req.fnol_number = f"FNOL-{datetime.now().year}-{random.randint(10000, 99999)}"
    req.loss_type = _normalize_loss_type(req.loss_type)
    conn = get_db_connection()
    try:
        # Wipe any previous draft FNOLs for this policy so reruns start clean.
        cleanup_draft_fnols_for_policy(req.policy_number, conn=conn)
        cur = conn.cursor()
        cur.execute(
            """
            INSERT INTO fnol_submissions (
                fnol_number, policy_number, policyholder_name, policyholder_address,
                policy_effective_date, policy_expiration_date,
                loss_type, loss_type_source, cause_of_loss, cause_of_loss_source,
                date_of_loss, date_of_loss_source, time_of_loss, time_of_loss_source,
                area_affected, area_affected_source, occupancy_at_loss, occupancy_at_loss_source,
                sudden_vs_gradual, emotional_context, severity, urgency_indicator,
                voice_transcript, text_input, overall_confidence, confidence_notes,
                status, created_at, updated_at
            ) VALUES (
                %s,%s,%s,%s,%s,%s,%s,'ai_inferred',%s,'ai_inferred',
                %s,'ai_inferred',%s,'ai_inferred',%s,'ai_inferred',%s,'ai_inferred',
                %s,%s,%s,%s,%s,%s,%s,%s,%s,NOW(),NOW()
            ) RETURNING *
            """,
            (
                req.fnol_number, req.policy_number, req.policyholder_name, req.policyholder_address,
                req.policy_effective_date, req.policy_expiration_date,
                req.loss_type, req.cause_of_loss,
                req.date_of_loss, req.time_of_loss,
                req.area_affected,
                req.occupancy_at_loss,
                req.sudden_vs_gradual, req.emotional_context, req.severity, req.urgency_indicator,
                req.voice_transcript, req.text_input, req.overall_confidence, req.confidence_notes,
                req.status or "draft",
            ),
        )
        result = cur.fetchone()
        conn.commit()
        return row_to_dict(result)
    except Exception:
        conn.rollback()
        log.exception("create_fnol_submission failed")
        raise
    finally:
        conn.close()


def get_fnol_submission_by_id(fnol_id: int) -> Optional[dict]:
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute("SELECT * FROM fnol_submissions WHERE id = %s", (fnol_id,))
        return row_to_dict(cur.fetchone())
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def get_fnol_submission_by_policy(policy_number: str) -> list:
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            "SELECT * FROM fnol_submissions WHERE policy_number = %s ORDER BY created_at DESC",
            (policy_number,),
        )
        return row_to_dict(cur.fetchall())
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


# ──────────────────────────────────────────────────────────────────────────────
# Overall Confidence — cumulative, not per-turn
# ──────────────────────────────────────────────────────────────────────────────
# The LLM's raw per-extraction "overall_confidence" only ever reflects a
# single turn's isolated message (e.g. a bare "yes" answering an occupancy
# question legitimately extracts almost nothing on its own), so trusting it
# directly makes the score collapse toward 0 as the conversation progresses
# even though the cumulative record is well-populated. Recomputed here from
# the CURRENT full record every time any field changes.
_MANDATORY_CONFIDENCE_FIELDS = {
    "loss_type", "cause_of_loss", "date_of_loss", "time_of_loss",
    "area_affected", "occupancy_at_loss", "sudden_vs_gradual", "severity",
}
_OPTIONAL_CONFIDENCE_FIELDS = {"emotional_context", "urgency_indicator"}
_MANDATORY_CONF_WEIGHT = 3.0
_OPTIONAL_CONF_WEIGHT = 1.0
# A value the policyholder explicitly confirmed, or a human edited, carries no
# ambiguity at all — there's nothing more certain than the source stating it
# directly, so it's scored as full confidence regardless of extraction history.
_DEFINITIVE_SOURCES = {"customer_confirmed", "human_edited"}
# A field can hold a value with no confidence on file (e.g. it was set via a
# direct update_fnol_submission call rather than extract_fnol_fields_from_text,
# and its source isn't one of the definitive ones above) — treat as reasonably
# but not fully confident rather than penalizing it as if it were unrated/missing.
_UNRATED_VALUE_CONFIDENCE = 75.0


def _compute_overall_confidence(fnol_id: int, current_row: dict, incoming: dict) -> int:
    """
    Weighted average confidence across the loss-detail fields, reflecting the
    FULL current record (existing DB row merged with this update) — not a
    single turn's isolated extraction. Mandatory fields are weighted 3x.
    """
    merged = {**current_row, **incoming}

    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            """
            SELECT DISTINCT ON (field_name) field_name, confidence
            FROM fnol_ai_inferences
            WHERE fnol_id = %s
            ORDER BY field_name, id DESC
            """,
            (fnol_id,),
        )
        latest_confidence = {
            r["field_name"]: r["confidence"] for r in cur.fetchall() if r.get("confidence") is not None
        }
    except Exception:
        conn.rollback()
        latest_confidence = {}
    finally:
        conn.close()

    total_weight = 0.0
    weighted_sum = 0.0
    weighted_fields = (
        [(f, _MANDATORY_CONF_WEIGHT) for f in _MANDATORY_CONFIDENCE_FIELDS]
        + [(f, _OPTIONAL_CONF_WEIGHT) for f in _OPTIONAL_CONFIDENCE_FIELDS]
    )
    for field_name, weight in weighted_fields:
        value = merged.get(field_name)
        source = merged.get(f"{field_name}_source")
        if value is None or (isinstance(value, str) and not value.strip()):
            field_conf = 0.0
        elif source in _DEFINITIVE_SOURCES:
            field_conf = 100.0
        elif field_name in latest_confidence:
            field_conf = float(latest_confidence[field_name])
        else:
            field_conf = _UNRATED_VALUE_CONFIDENCE
        total_weight += weight
        weighted_sum += weight * field_conf

    if total_weight == 0.0:
        return 0
    return int(round(weighted_sum / total_weight))


_UPDATABLE_COLUMNS = {
    "policy_number", "policyholder_name", "policyholder_address",
    "loss_type", "loss_type_source",
    "cause_of_loss", "cause_of_loss_source",
    "date_of_loss", "date_of_loss_source",
    "time_of_loss", "time_of_loss_source",
    "area_affected", "area_affected_source",
    "occupancy_at_loss", "occupancy_at_loss_source",
    "sudden_vs_gradual", "sudden_vs_gradual_source",
    "emotional_context", "emotional_context_source",
    "severity", "severity_source",
    "urgency_indicator", "urgency_indicator_source",
    "voice_transcript", "text_input", "overall_confidence",
    "confidence_notes", "status", "estimated_cost",
}


def update_fnol_submission(fnol_id: int, req: UpdateFnolSubmissionRequest) -> Optional[dict]:
    raw = req.model_dump(exclude_none=True)
    # Whitelist: only allow known columns to reach the dynamic SQL (#5)
    fields = {k: v for k, v in raw.items() if k in _UPDATABLE_COLUMNS}
    if not fields:
        return get_fnol_submission_by_id(fnol_id)

    if "loss_type" in fields:
        fields["loss_type"] = _normalize_loss_type(fields["loss_type"])

    # overall_confidence is derived, not settable — always recompute it from
    # the cumulative record rather than trusting a caller-supplied value (e.g.
    # a single turn's raw LLM self-report), so it reflects the whole FNOL's
    # current state on every field change regardless of which code path
    # triggered it (extraction auto-persist or a direct orchestrator update).
    current = get_fnol_submission_by_id(fnol_id) or {}
    fields["overall_confidence"] = _compute_overall_confidence(fnol_id, current, fields)

    set_clauses = ", ".join(f"{k} = %s" for k in fields)
    values = list(fields.values()) + [fnol_id]

    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            f"UPDATE fnol_submissions SET {set_clauses}, updated_at = NOW() WHERE id = %s RETURNING *",
            values,
        )
        result = cur.fetchone()
        conn.commit()
        return row_to_dict(result)
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


# ── Guidewire ClaimCenter — Claim Creation ────────────────────────────────────
# Hardcoded per the ClaimCenter sandbox contract — this PoC always reports as
# the same jurisdiction/reporter/contact regardless of the actual claim.
_GW_JURISDICTION_CODE = "IL"
_GW_REPORTER_FIRST_NAME = "Ken"
_GW_REPORTER_LAST_NAME = "Darion"


def _to_gw_loss_datetime(date_of_loss, time_of_loss) -> str:
    """
    Combines fnol_submissions' date_of_loss ("YYYY-MM-DD") and time_of_loss
    ("HH:MM") text columns into the ISO-8601 UTC datetime ClaimCenter requires
    for lossDate (e.g. "2026-01-18T00:30:00.000Z"). Defaults to midnight if
    time_of_loss is missing/unparsable.

    ClaimCenter rejects a lossDate that isn't strictly before its own clock
    (server runs in UTC, matching datetime.utcnow() here). A same-day loss
    reported with a time_of_loss that hasn't happened yet in UTC (e.g. the
    policyholder describes the loss as "this morning" but files well before
    that time today) would otherwise get rejected outright, so it's clamped
    a few minutes into the past instead of failing the whole submission.
    """
    if not date_of_loss:
        raise ValueError("date_of_loss is required to create a Guidewire claim")
    date_part = str(date_of_loss).strip()[:10]
    time_part = "00:00"
    candidate = str(time_of_loss).strip()[:5] if time_of_loss else ""
    if len(candidate) == 5 and candidate[2] == ":":
        time_part = candidate
    try:
        dt = datetime.strptime(f"{date_part} {time_part}", "%Y-%m-%d %H:%M")
    except ValueError as exc:
        raise ValueError(
            f"date_of_loss={date_of_loss!r} / time_of_loss={time_of_loss!r} "
            f"not in the expected format: {exc}"
        )

    now_utc = datetime.utcnow()
    if dt >= now_utc:
        log.warning(
            "lossDate %s is not before the current UTC time %s — clamping so "
            "Guidewire's date constraint doesn't reject the claim",
            dt.isoformat(), now_utc.isoformat(),
        )
        dt = now_utc - timedelta(minutes=5)

    return dt.strftime("%Y-%m-%dT%H:%M:%S.000Z")


def _build_guidewire_claim_payload(fnol: dict, policy_row: dict) -> dict:
    policy_row = policy_row or {}
    return {
        "data": {
            "attributes": {
                "policyNumber": fnol.get("policy_number"),
                "lossDate": _to_gw_loss_datetime(fnol.get("date_of_loss"), fnol.get("time_of_loss")),
                "description": fnol.get("cause_of_loss") or "Reported via FNOL intake",
                "jurisdiction": {"code": _GW_JURISDICTION_CODE},
                "lossCause": {"code": (fnol.get("loss_type") or "").strip().lower() or "other"},
                "lossLocation": {
                    "addressLine1": fnol.get("policyholder_address") or "",
                    "city": policy_row.get("city") or "",
                    "country": policy_row.get("country") or "US",
                    "postalCode": policy_row.get("postal_code") or "",
                    "state": {"code": _GW_JURISDICTION_CODE},
                },
                "reportedByType": {"code": "self"},
                "howReported": {"code": "phone"},
                "reporter": {"refid": "reporterId"},
                "mainContactType": {"code": "self"},
            }
        },
        "included": {
            "ClaimContact": [
                {
                    "attributes": {
                        "contactSubtype": "Person",
                        "firstName": _GW_REPORTER_FIRST_NAME,
                        "lastName": _GW_REPORTER_LAST_NAME,
                    },
                    "method": "post",
                    "refid": "reporterId",
                    "uri": "/claim/v1/claims/this/contacts",
                }
            ]
        },
    }


def _create_claim_in_guidewire(fnol: dict, policy_row: dict) -> str:
    """
    Drafts then submits a claim in Guidewire ClaimCenter for this FNOL.
    Returns the FINAL claim number from the /submit response — the draft
    response's claimNumber is a placeholder and is intentionally ignored.
    """
    payload = _build_guidewire_claim_payload(fnol, policy_row)
    draft = guidewire_client.create_claim(payload)
    draft_claim_id = (draft.get("data") or {}).get("attributes", {}).get("id")
    if not draft_claim_id:
        raise ValueError(f"Guidewire claim draft response missing id: {draft}")

    submitted = guidewire_client.submit_claim(draft_claim_id)
    claim_number = (submitted.get("data") or {}).get("attributes", {}).get("claimNumber")
    if not claim_number:
        raise ValueError(f"Guidewire claim submit response missing claimNumber: {submitted}")
    return claim_number


def submit_fnol(fnol_id: int) -> dict:
    """
    Marks an FNOL as submitted, sets submitted_at timestamp, and creates
    claims / claims_master / claim_journey_master records if none exist
    for the policy yet. The claim_number is issued by Guidewire ClaimCenter
    (draft + submit) rather than generated locally — if either ClaimCenter
    call fails, the FNOL is left unsubmitted so the user can retry.
    """
    conn = get_db_connection()
    try:
        cur = conn.cursor()

        cur.execute("SELECT * FROM fnol_submissions WHERE id = %s", (fnol_id,))
        fnol = row_to_dict(cur.fetchone())   # use row_to_dict consistently (#3)
        if not fnol:
            raise ValueError(f"FNOL with id={fnol_id} not found")

        pd_row = {}
        claim_number = None
        if fnol.get("policy_number"):
            cur.execute(
                "SELECT coverage_limit, deductible, city, country, postal_code "
                "FROM policy_details WHERE policy_number = %s LIMIT 1",
                (fnol["policy_number"],),
            )
            pd_row = cur.fetchone() or {}

            policy_number_trimmed = (fnol["policy_number"] or "").strip()
            if policy_number_trimmed in LOCAL_ONLY_POLICY_NUMBERS:
                # Special-case policies: their GW policy id exists in ClaimCenter sandbox.
                # Talk to Guidewire BEFORE mutating any local state — if this
                # raises, the FNOL stays exactly as it was and submission can be
                # retried from the UI instead of getting stuck half-submitted.
                claim_number = _create_claim_in_guidewire(fnol, pd_row)
            else:
                # PolicyCenter-only policies: ClaimCenter sandbox doesn't know them,
                # so skip the CC call and generate a local claim number instead.
                cur.execute("SELECT COALESCE(MAX(id), 0) + 1 AS next_seq FROM claims")
                next_seq = cur.fetchone()["next_seq"]
                claim_number = f"CLM-{datetime.utcnow().year}-{next_seq:04d}"

        cur.execute(
            """
            UPDATE fnol_submissions
            SET status = 'submitted', submitted_at = NOW(), updated_at = NOW()
            WHERE id = %s
            RETURNING *
            """,
            (fnol_id,),
        )
        updated = row_to_dict(cur.fetchone())

        if claim_number:
            cur.execute(
                """
                INSERT INTO claims (
                    claim_number, policyholder_name, policy_number,
                    loss_type, short_description, severity, estimated_cost, status,
                    date_of_loss, location, ai_confidence, filed_at
                ) VALUES (%s,%s,%s,%s,%s,%s,%s, 'Open', %s,%s,%s, NOW())
                RETURNING id
                """,
                (
                    claim_number,
                    fnol.get("policyholder_name") or "Unknown",
                    fnol["policy_number"],
                    fnol.get("loss_type") or "Unknown",
                    fnol.get("cause_of_loss") or "Reported via FNOL intake",
                    fnol.get("severity") or "Medium",
                    fnol.get("estimated_cost"),
                    fnol.get("date_of_loss"),
                    fnol.get("policyholder_address"),
                    fnol.get("overall_confidence"),
                ),
            )
            claim_id = cur.fetchone()["id"]

            p_coverage_limit = pd_row["coverage_limit"] if pd_row.get("coverage_limit") else 0
            p_deductible = pd_row["deductible"] if pd_row.get("deductible") else 0

            cur.execute(
                """
                INSERT INTO claims_master (
                    claim_number, policyholder_name, policy_number, loss_type,
                    date_of_loss, coverage_limit, deductible, status
                ) VALUES (%s,%s,%s,%s,%s,%s,%s, 'Open')
                """,
                (
                    claim_number,
                    fnol.get("policyholder_name") or "Unknown",
                    fnol["policy_number"],
                    fnol.get("loss_type") or "Unknown",
                    fnol.get("date_of_loss"),
                    p_coverage_limit,
                    p_deductible,
                ),
            )

            cur.execute(
                """
                INSERT INTO claim_journey_master (
                    claim_id, claim_number, current_stage, current_stage_name,
                    sub_status, overall_sla_status
                ) VALUES (%s,%s,1,'Claim Initiated','Under Review','on_track')
                """,
                (claim_id, claim_number),
            )

        conn.commit()
        return {"fnol": updated, "claim_number": claim_number, "status": "submitted"}
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


# ──────────────────────────────────────────────────────────────────────────────
# Mandatory Fields Reference
# ──────────────────────────────────────────────────────────────────────────────

def get_mandatory_fields() -> list:
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute("SELECT * FROM fnol_mandatory_fields ORDER BY display_order")
        return row_to_dict(cur.fetchall())
    finally:
        conn.close()


# ──────────────────────────────────────────────────────────────────────────────
# Voice / Text Extractions
# ──────────────────────────────────────────────────────────────────────────────

def save_voice_text_extraction(req: SaveVoiceTextExtractionRequest) -> dict:
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            """
            INSERT INTO fnol_voice_text_extraction (
                fnol_id, input_type, raw_input, transcribed_text,
                extracted_loss_type, extracted_cause, extracted_area,
                extracted_temporal, sudden_gradual_signal, emotional_context,
                extraction_confidence, created_at
            ) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,NOW())
            RETURNING *
            """,
            (
                req.fnol_id, req.input_type, req.raw_input, req.transcribed_text,
                req.extracted_loss_type, req.extracted_cause, req.extracted_area,
                req.extracted_temporal, req.sudden_gradual_signal, req.emotional_context,
                req.extraction_confidence,
            ),
        )
        result = cur.fetchone()
        conn.commit()
        return row_to_dict(result)
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def get_voice_text_extractions(fnol_id: int) -> list:
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            "SELECT * FROM fnol_voice_text_extraction WHERE fnol_id = %s ORDER BY created_at",
            (fnol_id,),
        )
        return row_to_dict(cur.fetchall())
    finally:
        conn.close()


# ──────────────────────────────────────────────────────────────────────────────
# AI Inferences
# ──────────────────────────────────────────────────────────────────────────────

def save_ai_inferences(req: SaveAiInferencesRequest) -> list:
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        created = []
        for item in req.inferences:
            cur.execute(
                """
                INSERT INTO fnol_ai_inferences (
                    fnol_id, field_name, inferred_value, confidence,
                    source, source_details, customer_confirmed, inferred_at
                ) VALUES (%s,%s,%s,%s,%s,%s,0,NOW())
                RETURNING *
                """,
                (
                    req.fnol_id, item.field_name, item.inferred_value,
                    item.confidence, item.source, item.source_details,
                ),
            )
            created.append(row_to_dict(cur.fetchone()))
        conn.commit()
        return created
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


# ──────────────────────────────────────────────────────────────────────────────
# Mandatory Question Log
# ──────────────────────────────────────────────────────────────────────────────

def log_question_answer(req: LogQuestionAnswerRequest) -> dict:
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        answered_at = datetime.utcnow().isoformat() if req.answer_text else None
        cur.execute(
            """
            INSERT INTO fnol_mandatory_question_log (
                fnol_id, question_text, field_name, answer_text,
                answer_type, was_skipped, question_order,
                asked_at, answered_at
            ) VALUES (%s,%s,%s,%s,%s,%s,%s,NOW(),%s)
            RETURNING *
            """,
            (
                req.fnol_id, req.question_text, req.field_name,
                req.answer_text, req.answer_type, int(req.was_skipped or False),
                req.question_order or 0, answered_at,
            ),
        )
        result = cur.fetchone()
        conn.commit()
        return row_to_dict(result)
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def get_question_log(fnol_id: int) -> list:
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        cur.execute(
            "SELECT * FROM fnol_mandatory_question_log WHERE fnol_id = %s ORDER BY question_order",
            (fnol_id,),
        )
        return row_to_dict(cur.fetchall())
    finally:
        conn.close()


# ──────────────────────────────────────────────────────────────────────────────
# Field Attribution
# ──────────────────────────────────────────────────────────────────────────────

def save_field_attribution(req: SaveFieldAttributionRequest) -> list:
    conn = get_db_connection()
    try:
        cur = conn.cursor()
        created = []
        for item in req.attributions:
            cur.execute(
                """
                INSERT INTO fnol_field_attribution (
                    fnol_id, field_name, field_label, field_value, source,
                    confidence, was_edited, was_confirmed, original_value,
                    edited_value, created_at
                ) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,NOW())
                RETURNING *
                """,
                (
                    req.fnol_id, item.field_name, item.field_label,
                    item.field_value, item.source, item.confidence,
                    int(item.was_edited or False), int(item.was_confirmed or False),
                    item.original_value, item.edited_value,
                ),
            )
            created.append(row_to_dict(cur.fetchone()))
        conn.commit()
        return created
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()








from pydantic import BaseModel, Field, field_validator
from typing import Optional, List, Union


def _coerce_yes_no(v):
    """Normalise bool or truthy/falsy strings from the LLM into 'Yes'/'No'.

    Stored as text rather than 0/1 so it displays consistently with the chat
    summary and so a "No" answer isn't mistaken for a missing value by
    Python truthiness checks (0 is falsy, "No" is not).
    """
    if v is None:
        return None
    if isinstance(v, bool):
        return "Yes" if v else "No"
    if isinstance(v, str):
        return "Yes" if v.strip().lower() in ("true", "yes", "1", "occupied", "y") else "No"
    return "Yes" if v else "No"


class CreateFnolSubmissionRequest(BaseModel):
    fnol_number: Optional[str] = Field(None, description="Unique FNOL identifier, e.g. FNOL-2026-00123. Auto-generated if omitted.")
    policy_number: str
    policyholder_name: Optional[str] = None
    policyholder_address: Optional[str] = None
    policy_effective_date: Optional[str] = None
    policy_expiration_date: Optional[str] = None
    loss_type: Optional[str] = None
    cause_of_loss: Optional[str] = None
    date_of_loss: Optional[str] = None
    time_of_loss: Optional[str] = None
    area_affected: Optional[str] = None
    occupancy_at_loss: Optional[str] = None
    sudden_vs_gradual: Optional[str] = None
    emotional_context: Optional[str] = None
    severity: Optional[str] = None
    urgency_indicator: Optional[str] = None
    voice_transcript: Optional[str] = None
    text_input: Optional[str] = None
    overall_confidence: Optional[int] = None
    confidence_notes: Optional[str] = None
    status: Optional[str] = "draft"

    @field_validator("occupancy_at_loss", mode="before")
    @classmethod
    def parse_occupancy_create(cls, v):
        return _coerce_yes_no(v)


class UpdateFnolSubmissionRequest(BaseModel):
    policy_number: Optional[str] = None
    policyholder_name: Optional[str] = None
    policyholder_address: Optional[str] = None
    loss_type: Optional[str] = None
    loss_type_source: Optional[str] = None
    cause_of_loss: Optional[str] = None
    cause_of_loss_source: Optional[str] = None
    date_of_loss: Optional[str] = None
    date_of_loss_source: Optional[str] = None
    time_of_loss: Optional[str] = None
    time_of_loss_source: Optional[str] = None
    area_affected: Optional[str] = None
    area_affected_source: Optional[str] = None
    occupancy_at_loss: Optional[str] = None
    occupancy_at_loss_source: Optional[str] = None
    sudden_vs_gradual: Optional[str] = None
    sudden_vs_gradual_source: Optional[str] = None
    emotional_context: Optional[str] = None
    emotional_context_source: Optional[str] = None
    severity: Optional[str] = None
    severity_source: Optional[str] = None
    urgency_indicator: Optional[str] = None
    urgency_indicator_source: Optional[str] = None
    voice_transcript: Optional[str] = None
    text_input: Optional[str] = None
    overall_confidence: Optional[int] = None
    confidence_notes: Optional[str] = None
    status: Optional[str] = None
    estimated_cost: Optional[float] = None

    @field_validator("occupancy_at_loss", mode="before")
    @classmethod
    def parse_occupancy_update(cls, v):
        return _coerce_yes_no(v)


class ExtractFnolFieldsRequest(BaseModel):
    raw_text: str = Field(..., description="Voice transcript (from browser STT) or free-text description from the policyholder")
    fnol_id: int = Field(..., description="FNOL submission ID to attach extraction results to")
    input_type: Optional[str] = Field("text", description="'voice_transcript' or 'text'")


class SaveVoiceTextExtractionRequest(BaseModel):
    fnol_id: int
    input_type: str = Field(..., description="'voice_transcript' or 'text'")
    raw_input: Optional[str] = None
    transcribed_text: Optional[str] = None
    extracted_loss_type: Optional[str] = None
    extracted_cause: Optional[str] = None
    extracted_area: Optional[str] = None
    extracted_temporal: Optional[str] = None
    sudden_gradual_signal: Optional[str] = None
    emotional_context: Optional[str] = None
    extraction_confidence: Optional[float] = None


class AiInferenceItem(BaseModel):
    field_name: str
    inferred_value: Optional[str] = None
    confidence: Optional[float] = None
    source: str = Field(..., description="'voice_transcript', 'text_input', 'ai_inferred'")
    source_details: Optional[str] = None


class SaveAiInferencesRequest(BaseModel):
    fnol_id: int
    inferences: List[AiInferenceItem]


class LogQuestionAnswerRequest(BaseModel):
    fnol_id: int
    question_text: str
    field_name: str
    answer_text: Optional[str] = None
    answer_type: Optional[str] = None
    was_skipped: Optional[bool] = False
    question_order: Optional[int] = 0


class FieldAttributionItem(BaseModel):
    field_name: str
    field_label: str
    field_value: Optional[str] = None
    source: str
    confidence: Optional[int] = None
    was_edited: Optional[bool] = False
    was_confirmed: Optional[bool] = False
    original_value: Optional[str] = None
    edited_value: Optional[str] = None


class SaveFieldAttributionRequest(BaseModel):
    fnol_id: int
    attributions: List[FieldAttributionItem]






"""
voice_handler.py
─────────────────
Structured FNOL field extraction via Azure OpenAI chat.

Field Extraction:
  Uses Azure OpenAI (gpt-5.1) to extract structured FNOL fields from
  plain text (typed input or browser-transcribed voice).
"""

import json
import logging
import os
from datetime import datetime

from dotenv import load_dotenv, find_dotenv
from openai import AzureOpenAI

load_dotenv(find_dotenv())

log = logging.getLogger(__name__)

AZURE_OPENAI_ENDPOINT = os.environ.get("AZURE_OPENAI_ENDPOINT", "")
AZURE_OPENAI_API_KEY = os.environ.get("AZURE_OPENAI_API_KEY", "")
AZURE_OPENAI_API_VERSION = os.environ.get("AZURE_OPENAI_API_VERSION", "2025-04-01-preview")
AZURE_OPENAI_CHAT_DEPLOYMENT = os.environ.get("AZURE_OPENAI_CHAT_DEPLOYMENT", "gpt-5.1")


def _get_openai_client() -> AzureOpenAI:
    return AzureOpenAI(
        api_key=AZURE_OPENAI_API_KEY,
        api_version=AZURE_OPENAI_API_VERSION,
        azure_endpoint=AZURE_OPENAI_ENDPOINT,
    )


# ──────────────────────────────────────────────────────────────────────────────
# Structured Field Extraction via LLM
# ──────────────────────────────────────────────────────────────────────────────

_EXTRACTION_SYSTEM_PROMPT = """
You are an insurance claims intake specialist. Your task is to extract structured
First Notice of Loss (FNOL) information from the policyholder's text or voice transcript.

A [TODAY: YYYY-MM-DD] tag is prepended to this prompt at call time — use it to
resolve relative dates ("today", "yesterday", "last Tuesday", "this morning")
into an absolute ISO date. Never guess a date from your own training data;
if the input contains no date reference at all, return null for date_of_loss.

Extract the following fields (return null if not mentioned):
- loss_type       : Type of loss — MUST be exactly one of these six values (pick the closest
                     match, matching case exactly): "Fire", "Waterdamage", "Hurricane",
                     "burglary", "Explosion", "Earthquake"
- cause_of_loss   : Specific cause (e.g. "burst pipe", "electrical fault", "fallen tree")
- date_of_loss    : Date when loss occurred (ISO format YYYY-MM-DD if determinable) — resolve relative to [TODAY:], never guessed
- time_of_loss    : Time of loss (HH:MM 24h if determinable)
- area_affected   : Room or area affected (e.g. "kitchen", "roof", "living room")
- occupancy_at_loss : Whether home was occupied — true/false/null
- sudden_vs_gradual : "Sudden" or "Gradual" based on description
- emotional_context : Policyholder's emotional state (e.g. "distressed", "calm", "urgent")
- severity         : "Low", "Medium", "High", or "Critical"
- urgency_indicator: "routine", "urgent", "emergency"

For each field also provide:
- confidence (0-100): How confident you are in the extracted value
- source_snippet   : The exact text fragment that led to this value

Return ONLY valid JSON in this exact structure:
{
  "fields": {
    "<field_name>": {
      "value": <extracted value or null>,
      "confidence": <0-100>,
      "source_snippet": "<text fragment or null>"
    }
  },
  "overall_confidence": <0-100>,
  "missing_mandatory_fields": ["<field_name>", ...],
  "additional_notes": "<any other relevant observations>"
}
"""


def extract_fnol_fields(raw_text: str) -> dict:
    """
    Uses Azure OpenAI to extract structured FNOL fields from free text
    (either a browser-transcribed voice recording or typed input).

    Returns a dict with the structure described in _EXTRACTION_SYSTEM_PROMPT,
    including the LLM's self-reported overall_confidence as-is.
    """
    client = _get_openai_client()

    # Same [TODAY:] grounding pattern FNOLOrchestrator/server.py uses for its
    # own date resolution — without it, "today"/"yesterday" have nothing to
    # resolve against and the model falls back to guessing a date from its
    # training data (observed as stray/wrong years in date_of_loss).
    today_str = datetime.now().strftime("%Y-%m-%d")
    system_prompt = f"[TODAY: {today_str}]\n\n{_EXTRACTION_SYSTEM_PROMPT}"

    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": f"Policyholder input:\n\n{raw_text}"},
    ]

    response = client.chat.completions.create(
        model=AZURE_OPENAI_CHAT_DEPLOYMENT,
        messages=messages,
        temperature=0.0,
        response_format={"type": "json_object"},
    )

    content = response.choices[0].message.content
    try:
        result = json.loads(content)
    except json.JSONDecodeError:
        log.error("LLM returned non-JSON: %s", content)
        return {"error": "Failed to parse LLM response", "raw": content}

    return result



      

