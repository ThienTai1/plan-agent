from fastapi import APIRouter, HTTPException, Depends, WebSocket, WebSocketDisconnect
from fastapi.responses import StreamingResponse
import json
from datetime import datetime
from app.models.requests import ChatRequest, ChatResponse, ActionExecuteRequest, ActionExecuteResponse, ActionBundleExecuteRequest, ActionBundleExecuteResponse
from app.core.auth import get_current_user_id, get_current_user
from baml_client.async_client import b as baml_client
from baml_client.types import Messages, ValidationDecision, OrchestratorResult, Department
from app.agents.tools.supabase_tool import get_supabase_tool
from app.agents.workflows.hierarchical_graph import build_hierarchical_graph
from app.agents.workflows.states.hierarchical_state import create_initial_state
from app.services.limit_service import check_and_update_limit
import asyncio
from typing import Dict, Any

# Global manager for cross-request coordination (SSE + Harness Resume)
class ResumeManager:
    def __init__(self):
        self.events: Dict[str, asyncio.Event] = {}
        self.results: Dict[str, any] = {}

    def get_event(self, thread_id: str) -> asyncio.Event:
        if thread_id not in self.events:
            self.events[thread_id] = asyncio.Event()
        return self.events[thread_id]

    def set_result(self, thread_id: str, result: any):
        self.results[thread_id] = result
        if thread_id in self.events:
            self.events[thread_id].set()

    def consume_result(self, thread_id: str) -> any:
        res = self.results.pop(thread_id, None)
        if thread_id in self.events:
             self.events[thread_id].clear()
        return res

resume_manager = ResumeManager()

router = APIRouter(prefix="/agent", tags=["agent"])


# ══════════════════════════════════════════════════════════════════════
# V4 UNIFIED: IntentClassifier → CHAT (Responsor) / COMPLEX (LangGraph V3)
# ══════════════════════════════════════════════════════════════════════

async def _process_chat_v4(payload: ChatRequest, user_id: str) -> ChatResponse:
    """
    Non-streaming V4 chat.
    1. IntentClassifier (BAML) → CHAT or COMPLEX
    2. CHAT → Responsor (fast, no tools)
    3. COMPLEX → LangGraph V3 ReAct Agent (multi-step, tools)
    """
    current_time = datetime.now().isoformat()
    
    baml_messages = []
    if payload.history:
        for m in payload.history:
            baml_messages.append(Messages(role=m.role, content=m.content))

    try:
        orchestrator_res: OrchestratorResult = await baml_client.Orchestrator(
            query=payload.query,
            context=f"current_time: {current_time}",
            messages=baml_messages
        )
        
        # Decide if it's CHAT or COMPLEX
        # COMPLEX if any MANAGEMENT or ANALYTICS department is assigned
        is_complex = any(
            dept in [Department.MANAGEMENT, Department.ANALYTICS]
            for stage in orchestrator_res.stages
            for dept in stage.departments
        )
        
        print(f"🎯 Orchestrator stages: {orchestrator_res.stages} | Complex: {is_complex} | User: {user_id}")
        
        if not is_complex:
            # ── CHAT: Simple Responsor ──
            is_first = not payload.history or len(payload.history) == 0
            
            if is_first:
                res = await baml_client.Responsor(
                    query=payload.query,
                    context=f"current_time: {current_time}, user_intent: CHAT",
                    plan=None,
                    tool_history=None,
                    validator_reasoning=None,
                    messages=baml_messages
                )
                title = None # GenerateTitle is removed from BAML
            else:
                res = await baml_client.Responsor(
                    query=payload.query,
                    context=f"current_time: {current_time}, user_intent: CHAT",
                    plan=None,
                    tool_history=None,
                    validator_reasoning=None,
                    messages=baml_messages
                )
                title = None
            
            # Extract text from the first TEXT block and others as pending_actions
            ans_text = ""
            pending_actions = []
            if res and res.blocks:
                for block in res.blocks:
                    if block.component_type.name == "TEXT":
                        if not ans_text:
                            ans_text = block.text or ""
                        else:
                            ans_text += "\n" + (block.text or "")
                    else:
                        block_dict = {
                            "type": block.component_type.name.lower(),
                        }
                        if block.chart_data: block_dict["data"] = block.chart_data.model_dump()
                        elif block.breakdown_data: block_dict["data"] = block.breakdown_data.model_dump()
                        elif block.insight_data: block_dict["data"] = block.insight_data.model_dump()
                        elif block.focus_data: block_dict["data"] = block.focus_data.model_dump()
                        elif block.reschedule_data: block_dict["data"] = block.reschedule_data.model_dump()
                        elif block.reflection_data: block_dict["data"] = block.reflection_data.model_dump()
                        pending_actions.append(block_dict)
            
            return ChatResponse(
                message=ans_text or "Processed.",
                title=title,
                follow_ups=[],
                pending_action=None,
                pending_actions=pending_actions
            )
        
        else:
            # ── COMPLEX: Hierarchical Agent Workflow ──
            app = build_hierarchical_graph()
            
            initial_state = {
                "user_id": user_id,
                "user_message": payload.query,
                "current_time": current_time,
                "history": payload.history if payload.history else [],
                "messages": [],
                "pending_departments": [],
                "current_department": None,
                "blueprint": None,
                "allowed_tools": [],
                "plan": [],
                "current_step_index": 0,
                "pending_action": None,
                "last_execution_result": None,
                "validation_decision": None,
                "final_answer": None,
                "step_count": 0,
                "max_steps": 10
            }
            
            thread_id = f"chat-{user_id}"
            config = {"configurable": {"thread_id": thread_id}}
            final_state = await app.ainvoke(initial_state, config=config)
            
            ans = final_state.get("final_answer") or "Tôi đã chuẩn bị các hành động bên dưới."
            
            # Extract reasoning from internal logs
            internal_logs = final_state.get("messages", [])
            reasoning = "\n".join([m["content"] for m in internal_logs if "[THOUGHT]" in m["content"]])
            
            is_first = not payload.history or len(payload.history) == 0
            title = None
            if is_first:
                title = await baml_client.GenerateTitle(query=payload.query)
            
            # Map plan to pending_actions for the response
            plan = final_state.get("plan", [])
            pending_actions = []
            for s in plan:
                 pending_actions.append({
                     "id": s.id,
                     "display": s.description,
                     "status": "completed" # In non-streaming, they are already done
                 })
            
            # Standardize blocks and extract summary text
            ans_text = ""
            pending_actions = []
            
            if isinstance(ans, dict) and "blocks" in ans:
                for block in ans["blocks"]:
                    comp_type = block.get("component_type", "TEXT")
                    if isinstance(comp_type, dict):
                        comp_type = comp_type.get("name", "TEXT")
                    
                    if comp_type == "TEXT":
                        if not ans_text:
                            ans_text = block.get("text") or ""
                        else:
                            ans_text += "\n" + (block.get("text") or "")
                    else:
                        block_dict = {"type": comp_type.lower()}
                        for key in ["chart_data", "breakdown_data", "insight_data", "focus_data", "reschedule_data", "reflection_data"]:
                            if block.get(key):
                                block_dict["data"] = block[key]
                                break
                        pending_actions.append(block_dict)
            else:
                ans_text = str(ans) if ans else "Tôi đã chuẩn bị các hành động bên dưới."

            return ChatResponse(
                message=ans_text or "Processed.",
                title=title,
                follow_ups=[],
                pending_actions=pending_actions,
                reasoning=reasoning
            )
            
    except Exception as e:
        import traceback
        traceback.print_exc()
        return ChatResponse(message=f"Lỗi khi xử lý AI: {str(e)}")


@router.post("/v4/chat", response_model=ChatResponse)
async def chat_v4(
    payload: ChatRequest,
    user: dict = Depends(get_current_user)
) -> ChatResponse:
    """V4 chat (non-streaming, with auth)."""
    user_id = user["sub"]
    
    # Enforce Daily Limit for Free Users
    allowed = await check_and_update_limit(user_id)
    if not allowed:
        return ChatResponse(
            message="You've reached your AI message limit for now. Upgrade to Pro for unlimited strategist insights!",
            status="limit_reached"
        )
        
    return await _process_chat_v4(payload, user_id)


@router.post("/v4/chat-test", response_model=ChatResponse)
async def chat_v4_test(
    payload: ChatRequest
) -> ChatResponse:
    """V4 chat test (non-streaming, no auth)."""
    return await _process_chat_v4(payload, "00000000-0000-0000-0000-000000000000")


async def _stream_chat_v4(payload: ChatRequest, user_id: str):
    """
    Unified streaming endpoint.
    1. IntentClassifier (BAML) → CHAT or COMPLEX
    2. CHAT → Simple Responsor (fast, no tools)
    3. COMPLEX → LangGraph V3 ReAct Agent (multi-step, tools)
    """
    current_time = datetime.now().isoformat()
    
    baml_messages = []
    if payload.history:
        for m in payload.history:
            baml_messages.append(Messages(role=m.role, content=m.content))

    try:
        orchestrator_res: OrchestratorResult = await baml_client.Orchestrator(
            query=payload.query,
            context=f"current_time: {current_time}",
            messages=baml_messages
        )
        
        is_complex = any(
            dept in [Department.MANAGEMENT, Department.ANALYTICS]
            for stage in orchestrator_res.stages
            for dept in stage.departments
        )
        
        yield f"data: {json.dumps({'type': 'intent', 'content': {'intent': 'COMPLEX' if is_complex else 'CHAT'}})}\n\n"
        
        if not is_complex:
            # ── CHAT: Simple Responsor (fast path) ──
            stream = baml_client.stream.Responsor(
                query=payload.query,
                context=f"current_time: {current_time}, user_intent: CHAT",
                plan=None,
                tool_history=None,
                validator_reasoning=None,
                messages=baml_messages
            )
            
            final_obj = None
            last_total_text = ""
            async for chunk in stream:
                if chunk:
                    # chunk is an AgentResponse (partial or final)
                    final_obj = chunk
                    # Calculate total text across all blocks to send deltas correctly
                    current_total_text = ""
                    if chunk.blocks:
                        for block in chunk.blocks:
                            if block.component_type and block.component_type.name == "TEXT":
                                current_total_text += (block.text or "")
                    
                    delta = current_total_text[len(last_total_text):]
                    if delta:
                        yield f"data: {json.dumps({'type': 'text', 'content': delta})}\n\n"
                    last_total_text = current_total_text
            
            # Generate title for first message
            is_first = payload.history is None or len(payload.history) == 0
            title = None # GenerateTitle is removed from BAML
            
            pending_actions = []
            if final_obj and final_obj.blocks:
                for block in final_obj.blocks:
                    if block.component_type.name != "TEXT":
                        # Convert block to dict for frontend
                        block_dict = {
                            "type": block.component_type.name.lower(),
                        }
                        # Add specific data based on type
                        if block.chart_data: block_dict["data"] = block.chart_data.model_dump()
                        elif block.breakdown_data: block_dict["data"] = block.breakdown_data.model_dump()
                        elif block.insight_data: block_dict["data"] = block.insight_data.model_dump()
                        elif block.focus_data: block_dict["data"] = block.focus_data.model_dump()
                        elif block.reschedule_data: block_dict["data"] = block.reschedule_data.model_dump()
                        elif block.reflection_data: block_dict["data"] = block.reflection_data.model_dump()
                        
                        yield f"data: {json.dumps({'type': 'object', 'content': block_dict})}\n\n"
                        pending_actions.append(block_dict)

            final_meta = {
                "type": "final",
                "title": title if title else None,
                "follow_ups": [],
                "pending_action": None,
                "pending_actions": pending_actions
            }
            yield f"data: {json.dumps(final_meta)}\n\n"
        
        else:
            # ── COMPLEX: Hierarchical Agent Workflow ──
            app = build_hierarchical_graph()
            
            yield f"data: {json.dumps({'type': 'status', 'content': 'Thinking...'})}\n\n"
            
            initial_state = create_initial_state(
                user_message=payload.query,
                user_id=user_id,
                current_time=current_time,
                history=payload.history if payload.history else None,
            )
            
            # Standard config for LangGraph checkpointers
            thread_id = f"chat-{user_id}"
            config = {"configurable": {"thread_id": thread_id}}
            
            # Determine if user is Pro (Pro users execute tools on server, Free users via Harness)
            is_pro = False
            # In a real app, we check user metadata or DB role. For now, we simulate.
            
            final_answer = ""
            
            # Use a stream variable that can be updated for resumption
            current_state = initial_state
            
            while True:
                async for event in app.astream(current_state, config=config, stream_mode="updates"):
                    for node_name, output in event.items():
                        if node_name == "supervisor":
                            depts = output.get("pending_departments")
                            yield f"data: {json.dumps({'type': 'status', 'content': f'Analyzed departments: {depts}'})}\n\n"
                        
                        elif node_name == "specialist":
                            bp = output.get("blueprint")
                            if bp:
                                yield f"data: {json.dumps({'type': 'thought', 'content': f'Strategy: {bp.goal}'})}\n\n"
                        
                        elif node_name == "planner":
                            plan = output.get("plan", [])
                            yield f"data: {json.dumps({'type': 'status', 'content': f'Created plan with {len(plan)} steps.'})}\n\n"
                            # Stream the plan as actions for the app checklist
                            actions = []
                            for s in plan:
                                 actions.append({
                                     "id": s.id,
                                     "display": s.description,
                                     "status": "pending"
                                 })
                            yield f"data: {json.dumps({'type': 'actions', 'actions': actions})}\n\n"
                            
                        elif node_name == "executor":
                            action = output.get("pending_action")
                            if action:
                                 yield f"data: {json.dumps({'type': 'status', 'content': action['display']})}\n\n"
                        
                        elif node_name == "execute_tool":
                            msgs = output.get("messages", [])
                            if msgs:
                                 last_msg = msgs[-1]
                                 if "[OBSERVATION]" in last_msg["content"]:
                                      yield f"data: {json.dumps({'type': 'status', 'content': 'Tool execution completed.'})}\n\n"
                                 
                                 if len(msgs) >= 2:
                                      thought_msg = msgs[-2]
                                      if "[THOUGHT]" in thought_msg["content"]:
                                           yield f"data: {json.dumps({'type': 'thought', 'content': thought_msg['content']})}\n\n"
                        
                        elif node_name == "responsor":
                            if output.get("final_answer"):
                                final_answer = output["final_answer"]

                # Check for interruption (Client-side Tool Call)
                snapshot = await app.aget_state(config)
                if snapshot.next and snapshot.next[0] == "client_harness":
                     pending_action = snapshot.values.get("pending_action")
                     if pending_action:
                          # Yield Tool Call to client
                          yield f"data: {json.dumps({'type': 'tool_call', 'content': pending_action})}\n\n"
                          
                          # WAIT for client to POST result to /harness
                          event = resume_manager.get_event(thread_id)
                          await event.wait()
                          
                          tool_output = resume_manager.consume_result(thread_id)
                          
                          # Prepare to resume
                          messages = list(snapshot.values["messages"])
                          messages.append({"role": "system", "content": f"[OBSERVATION] {tool_output}"})
                          
                          await app.aupdate_state(config, {
                              "last_execution_result": str(tool_output),
                              "messages": messages,
                              "pending_action": None
                          })
                          
                          # Resuming from checkpoint
                          current_state = None
                          continue
                
                break

            accumulated_pending_actions = []

            if isinstance(final_answer, dict) and "blocks" in final_answer:
                blocks = final_answer["blocks"]
                for block in blocks:
                    comp_type = block.get("component_type", "TEXT")
                    if isinstance(comp_type, dict): # BAML enum can sometimes be a dict in model_dump
                        comp_type = comp_type.get("name", "TEXT")
                    
                    if comp_type == "TEXT":
                        yield f"data: {json.dumps({'type': 'text', 'content': block.get('text', '')})}\n\n"
                    else:
                        # It's an action card or chart
                        block_dict = {
                            "type": comp_type.lower(),
                        }
                        # Map specific data keys to generic 'data' key
                        for key in ["chart_data", "breakdown_data", "insight_data", "focus_data", "reschedule_data", "reflection_data"]:
                            if block.get(key):
                                block_dict["data"] = block[key]
                                break
                        
                        yield f"data: {json.dumps({'type': 'object', 'content': block_dict})}\n\n"
                        accumulated_pending_actions.append(block_dict)
            elif final_answer:
                # Fallback if it's just raw text string
                yield f"data: {json.dumps({'type': 'text', 'content': str(final_answer)})}\n\n"
            else:
                yield f"data: {json.dumps({'type': 'text', 'content': 'I have completed your request.'})}\n\n"
            
            is_first = payload.history is None or len(payload.history) == 0
            title = None # GenerateTitle is removed from BAML
            
            final_meta = {
                "type": "final",
                "title": title if title else None,
                "follow_ups": [],
                "pending_action": None,
                "pending_actions": accumulated_pending_actions
            }
            yield f"data: {json.dumps(final_meta)}\n\n"
            
    except Exception as e:
        import traceback
        traceback.print_exc()
        yield f"data: {json.dumps({'type': 'error', 'message': str(e)})}\n\n"


@router.post("/v4/chat/stream")
async def chat_stream_v4(
    payload: ChatRequest,
    user: dict = Depends(get_current_user)
) -> StreamingResponse:
    user_id = user["sub"]
    
    # Enforce Daily Limit for Free Users
    allowed = await check_and_update_limit(user_id)
    if not allowed:
        async def limit_reached_stream():
            yield f"data: {json.dumps({'type': 'error', 'message': 'You have reached your AI message limit for now. Upgrade to Pro for unlimited strategist insights!'})}\n\n"
        
        return StreamingResponse(limit_reached_stream(), media_type="text/event-stream")

    return StreamingResponse(_stream_chat_v4(payload, user_id), media_type="text/event-stream")


@router.post("/v4/chat/stream-test")
async def chat_stream_v4_test(
    payload: ChatRequest
) -> StreamingResponse:
    """Test endpoint for V4 (no auth)."""
    return StreamingResponse(_stream_chat_v4(payload, "00000000-0000-0000-0000-000000000000"), media_type="text/event-stream")


@router.post("/v4/chat/harness")
async def chat_harness_resume(
    payload: Dict[str, Any],
    user: dict = Depends(get_current_user)
) -> Dict[str, str]:
    """Endpoint to receive client-side tool results and resume the SSE stream."""
    user_id = user["sub"]
    thread_id = f"chat-{user_id}"
    result = payload.get("output")
    
    print(f"📥 Received Harness Result for {thread_id}: {result}")
    resume_manager.set_result(thread_id, result)
    
    return {"status": "success", "message": "Result received, resuming stream."}


@router.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok", "service": "agent-service"}

@router.get("/quota-status")
async def quota_status(
    user: dict = Depends(get_current_user)
) -> dict:
    """Returns the current user's message limit status."""
    from app.services.limit_service import get_quota_status
    user_id = user["sub"]
    return await get_quota_status(user_id)



# @router.get
async def _perform_search(params_list: list, user_id: str) -> str:
    """Helper to query Supabase based on BAML search parameters."""
    # This function seems to depend on TaskSearch/EventSearch which are gone.
    # Marking as legacy/broken for now until we define how search works in the new BAML.
    return "Search functionality is temporarily unavailable during refactor."
