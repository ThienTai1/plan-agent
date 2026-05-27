"""
ROUTES.PY - API Endpoints.
This file defines the API logic:
- /v4/chat/stream: Real-time SSE response stream.
- /v4/chat/tool-result: Endpoint for the Frontend to return Tool execution results to the Backend.
- /v4/chat/complete: Non-streaming (single-shot) response.
"""
import json
import uuid
from typing import Optional, AsyncGenerator, List, Union, Any
from fastapi import APIRouter, Depends, Header, HTTPException
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field

from app.agent.workflow import run_agent_workflow, stream_orchestration
from app.api.deps import get_current_user
from loguru import logger
from fastapi import Request

from app.core.security import limiter, sanitize_input
from app.core.quota import check_and_deduct_quota

# ══════════════════════════════════════════════════════════════════════
# DATA MODELS
# ══════════════════════════════════════════════════════════════════════

class ChatRequest(BaseModel):
    query: str
    session_id: Optional[str] = Field(default_factory=lambda: str(uuid.uuid4()))

class TitleRequest(BaseModel):
    session_id: str

class ChatStreamResponse(BaseModel):
    type: str  # "text", "tool_call", "status", "done"
    content: Optional[str] = None
    tool_name: Optional[str] = None
    call_id: Optional[str] = None


# ══════════════════════════════════════════════════════════════════════
# ROUTER
# ══════════════════════════════════════════════════════════════════════

router = APIRouter()

async def stream_agent_response(query: str, session_id: str, user_id: str, request: Request) -> AsyncGenerator[str, None]:
    """Helper to format SSE stream from orchestration events."""
    try:
        checkpointer = getattr(request.app.state, "checkpointer", None)
        yield f"data: {json.dumps({'type': 'start', 'session_id': session_id})}\n\n"

        async for event in stream_orchestration(query, session_id, user_id, checkpointer=checkpointer):
            e_type = event.get("type")
            
            if e_type in ["text", "status", "object"]:
                yield f"data: {json.dumps({'type': e_type, 'content': event.get('content') or event.get('object')})}\n\n"
            
            elif e_type == "tool_call":
                payload = {
                    "type": "tool_call",
                    "content": {
                        "tool_name": event.get("tool_name"),
                        "call_id": event.get("call_id"),
                        "arguments": event.get("tool_args")
                    }
                }
                yield f"data: {json.dumps(payload)}\n\n"
            
            elif e_type == "final_state":
                messages = event["content"].get("messages", [])
                last_msg = messages[-1].get("content", "") if messages else ""
                yield f"data: {json.dumps({'type': 'done', 'final_message': last_msg})}\n\n"

        yield "data: [DONE]\n\n"

    except Exception:
        logger.exception("💥 Stream error in agent response")
        yield f"data: {json.dumps({'type': 'error', 'message': 'Internal server error during streaming'})}\n\n"
        yield "data: [DONE]\n\n"


class ResumeRequest(BaseModel):
    session_id: str
    response: Any

async def stream_resume_response(response_data: Any, session_id: str, user_id: str, request: Request) -> AsyncGenerator[str, None]:
    """Helper to stream SSE from a resumed graph execution with rich events."""
    try:
        from app.agent.workflow import build_orchestration_graph
        from langgraph.types import Command
        from langchain_core.messages import ToolMessage
        
        yield f"data: {json.dumps({'type': 'start', 'session_id': session_id})}\n\n"
        
        # Fetch shared checkpointer from app state
        checkpointer = getattr(request.app.state, "checkpointer", None)
        
        if not checkpointer:
            logger.error(f"❌ Checkpointer not available in app state for session {session_id}")
            yield f"data: {json.dumps({'error': 'Persistence layer unavailable'})}\n\n"
            return
            
        # 🛡️ Security: Verify thread ownership
        from app.services.supabase_service import supabase_service
        try:
            # Quick ownership check
            thread_check = supabase_service.client.table("threads").select("user_id").eq("id", session_id).maybe_single().execute()
            if not thread_check.data or thread_check.data.get("user_id") != user_id:
                logger.error(f"❌ Security violation: User {user_id} tried to access thread {session_id}")
                yield f"data: {json.dumps({'error': 'Unauthorized access to session'})}\n\n"
                return
        except Exception as e:
            logger.error(f"❌ Error verifying thread ownership: {str(e)}")
            yield f"data: {json.dumps({'error': 'Security verification failed'})}\n\n"
            return

        graph = build_orchestration_graph(checkpointer)
        # 🚀 Use ONLY thread_id for primary lookup (Definitive fix for amnesia)
        config = {"configurable": {"thread_id": session_id}}

        # 🔍 Diagnostic: Check if checkpoint exists before resuming
        state = await checkpointer.aget(config)
        if not state:
            logger.warning(f"🕵️ No existing checkpoint found for thread_id: {session_id}. Persistence may be failing.")
        else:
            logger.info(f"✅ Found existing checkpoint for session {session_id}. Ready to resume.")

        logger.info(f"📡 Resuming session {session_id} for user {user_id}...")
        
        # Use astream_events (v2) for comprehensive streaming feedback (text, status, objects)
        async for event in graph.astream_events(
            Command(resume=response_data), 
            config=config, 
            version="v2"
        ):
            kind = event["event"]
            node_name = event.get("metadata", {}).get("langgraph_node", "")
            
            # Diagnostic logging
            logger.debug(f"📡 Resume Event: {kind} | Node: {node_name}")

            if kind == "on_chat_model_stream" and node_name != "supervisor":
                content = event["data"].get("chunk", {}).content
                if content:
                    yield f"data: {json.dumps({'type': 'text', 'content': content})}\n\n"
            
            elif kind == "on_custom_event":
                name = event.get("name")
                data = event.get("data", {})
                if name == "status_update":
                    yield f"data: {json.dumps({'type': 'status', 'content': data.get('message', '')})}\n\n"
                elif name == "ui_component_emitted":
                    yield f"data: {json.dumps({'type': 'object', 'content': {'type': data.get('type'), 'data': data.get('data', {})}})}\n\n"

            elif kind == "on_tool_end":
                output = event.get("data", {}).get("output")
                if isinstance(output, ToolMessage):
                    try:
                        parsed = json.loads(output.content)
                        if isinstance(parsed, dict) and "ui_component" in parsed:
                            yield f"data: {json.dumps({'type': 'object', 'content': {'type': parsed['ui_component'], 'data': parsed.get('data', {})}})}\n\n"
                    except:
                        pass

        yield "data: [DONE]\n\n"

    except Exception as e:
        logger.exception(f"💥 Resume stream error: {str(e)}")
        yield f"data: {json.dumps({'type': 'error', 'message': str(e)})}\n\n"
        yield "data: [DONE]\n\n"

@router.post("/v4/chat/resume")
@limiter.limit("20/minute")
async def chat_resume(request: Request, body: ResumeRequest, user_id: str = Depends(get_current_user)):
    """Resume an interrupted workflow with user feedback (Streaming)."""
    return StreamingResponse(
        stream_resume_response(body.response, body.session_id, user_id, request),
        media_type="text/event-stream"
    )


class SessionTitleRequest(BaseModel):
    session_id: str
    first_message: Optional[str] = None

@router.post("/v4/chat/session-title")
@limiter.limit("20/minute")
async def chat_session_title(request: Request, body: SessionTitleRequest, user_id: str = Depends(get_current_user)):
    """Generate a title for a session based on the first message."""
    from app.services.title_service import title_service
    title = await title_service.generate_and_update_title(
        body.session_id, 
        first_message=body.first_message
    )
    return {"title": title, "session_id": body.session_id}


@router.post("/v4/chat/stream")
@limiter.limit("20/minute")
async def chat_stream(request: Request, chat_req: ChatRequest, user_id: str = Depends(get_current_user)):
    # 1. Security: Sanitize input to prevent Prompt Injection
    chat_req.query = sanitize_input(chat_req.query)
    
    # 2. Constraints: Check Quota
    await check_and_deduct_quota(user_id)

    return StreamingResponse(
        stream_agent_response(chat_req.query, chat_req.session_id, user_id, request),
        media_type="text/event-stream"
    )

@router.post("/v4/chat/complete")
@limiter.limit("20/minute")
async def chat_complete(request: Request, chat_req: ChatRequest, user_id: str = Depends(get_current_user)):
    """Simple chat endpoint that returns the final response in JSON."""
    
    # 1. Security
    chat_req.query = sanitize_input(chat_req.query)
    
    # 2. Constraints: Check Quota
    await check_and_deduct_quota(user_id)
    
    # Get shared checkpointer
    checkpointer = getattr(request.app.state, "checkpointer", None)
    
    # Run the orchestration
    result = await run_agent_workflow(chat_req.query, chat_req.session_id, user_id, checkpointer=checkpointer)
    
    # Extract the last message content as the answer
    messages = result.get("messages", [])
    answer = ""
    
    if messages:
        last_message = messages[-1]
        # Handle both dict and object formats
        if isinstance(last_message, dict):
            answer = last_message.get("content", "")
        else:
            answer = getattr(last_message, "content", "")

    return {
        "answer": answer,
        "session_id": chat_req.session_id,
        "status": "success"
    }