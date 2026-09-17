Critical Gap 1 — PolicyCoverageVerificationAgent server has no LOB awareness:
The PolicyCoverageVerificationAgent/server.py has only a single _FALLBACK_PROMPT with no lob parameter in its /chat endpoint:
# Current — no lob
body = await request.json()
user_message = body.get("message", "...")
But the handler.py functions all require lob to route correctly. Since the agent server never passes lob to its tools, the tools default to lob="Homeowners" even for Motor claims. The agent needs to be updated like VoiceTextIntakeAgent was: accept lob in the request body, pick the right prompt, and the system prompt must instruct the LLM to pass lob= in every tool call.
Gap 2 — Motor prompt missing from PolicyCoverageVerificationAgent:
There's only one _FALLBACK_PROMPT (Homeowners-style: looks up claim → policy → verify_coverage). A Motor-specific prompt would need to handle Motor claim numbers coming from motor_fnol_submissions and route to motor_coverage_verification_results. The Motor-specific tool steps and LOB-aware tool calls need to be spelled out.
