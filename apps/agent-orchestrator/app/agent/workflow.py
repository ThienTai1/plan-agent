"""
WORKFLOW.PY - The heart of the Agent system.
This file defines the LangGraph schema, processing nodes, and agent interaction logic.
Uses PostgresSaver for persistent memory on Supabase.
"""
from datetime import datetime
import uuid
from typing import Dict, Any, List, Optional, Literal, AsyncGenerator
import json
import asyncio
from langchain_core.messages import HumanMessage, AIMessage, SystemMessage, ToolMessage, trim_messages
from langchain_core.callbacks.manager import adispatch_custom_event
from langgraph.graph import StateGraph, START, END
from langgraph.checkpoint.postgres.aio import AsyncPostgresSaver
from langgraph.types import interrupt
from psycopg_pool import AsyncConnectionPool
from app.core.db import db_manager

from app.agent.state import HierarchicalState
from app.agent.agents import (
    create_generic_agent,
    create_goal_task_agent,
    create_analytic_agent,
    create_supervisor_agent,
    RoutingDecision
)
from app.config import settings
from loguru import logger


# ══════════════════════════════════════════════════════════════════════
# UTILITIES
# ══════════════════════════════════════════════════════════════════════

def _trim_messages(messages: List[Dict[str, Any]], limit: int = 15) -> List[Dict[str, Any]]:
    """Keep only the last N messages to stay within context limits."""
    if len(messages) <= limit:
        return messages
    logger.info(f"✂️ Trimming history: keeping last {limit} messages.")
    return messages[-limit:]


async def execute_tools_manually(tool_calls: List[Any], tools_map: Dict[str, Any]) -> List[ToolMessage]:
    """Generic tool runner for manual ReAct node loops with error handling."""
    results = []
    last_goal_id = None  # 🚀 Track the most recent Goal ID to handle batch dependencies
    
    for tool_call in tool_calls:
        tool_name, tool_args, tool_id = tool_call["name"], tool_call["args"], tool_call["id"]
        
        # 🔗 Smart Linkage: If this is a task creation and we have a captured Goal ID, link them.
        # This allows the frontend to send a batch without knowing the IDs beforehand.
        if tool_name == "create_task" and not tool_args.get("goal_id") and last_goal_id:
            tool_args["goal_id"] = last_goal_id
            logger.info(f"🔗 Smart Link: Auto-linked task '{tool_args.get('title')}' to parent Goal {last_goal_id}")

        logger.info(f"🛠️ Executing Tool: {tool_name} | tool_id: {tool_id}")
        
        if tool_name in tools_map:
            tool = tools_map[tool_name]
            try:
                # Pass the tool_id to arun so it can be used for sync
                result = await tool.arun(tool_call_id=tool_id, **tool_args)
                
                # 🚀 Transparent Feedback: Dispatch detailed result for UI feedback
                status_icon = "✅" if result.success else "❌"
                if result.success:
                    if tool_name == "create_goal":
                        status_msg = f"✅ Goal '{tool_args.get('title')}' created"
                    elif tool_name == "create_task":
                        status_msg = f"✅ Task '{tool_args.get('title')}' linked"
                    else:
                        status_msg = f"✅ {tool_name.replace('_', ' ').capitalize()} finished"
                else:
                    status_msg = f"❌ Error: {result.error[:50]}..."
                
                await adispatch_custom_event("status_update", {"message": status_msg})

                # 📌 Capture the ID of a newly created Goal to use for subsequent Tasks in this batch
                if result.success and tool_name == "create_goal" and isinstance(result.data, dict):
                    new_id = result.data.get("id")
                    if new_id:
                        last_goal_id = new_id
                        logger.info(f"📌 Pipeline Context: Captured Goal ID {last_goal_id}")

                content = json.dumps(result.data) if result.success else f"Error from tool: {result.error}"
                
                # If result has UI component, dispatch it as a custom event so streamers can see it
                if result.success and isinstance(result.data, dict) and "ui_component" in result.data:
                    ui_data = result.data
                    logger.info(f"🎨 Dispatching UI event: {ui_data['ui_component']}")
                    await adispatch_custom_event(
                        "ui_component_emitted",
                        {"type": ui_data["ui_component"], "data": ui_data.get("data", {})},
                        config={"tags": ["ui_tool"]}
                    )
                
                results.append(ToolMessage(content=content, tool_call_id=tool_id))
            except Exception as e:
                logger.error(f"💥 Tool Execution Error: {str(e)}")
                # Provide the error back to the AI so it can inform the user
                results.append(ToolMessage(content=f"Error occurred while executing {tool_name}: {str(e)}", tool_call_id=tool_id))
        else:
            results.append(ToolMessage(content=f"Error: Tool {tool_name} not found", tool_call_id=tool_id))
    return results


# ══════════════════════════════════════════════════════════════════════
# NODE DEFINITIONS
# ══════════════════════════════════════════════════════════════════════

async def supervisor_node(state: HierarchicalState) -> Dict[str, Any]:
    """Decides which agent to run using structured output."""
    await adispatch_custom_event("status_update", {"message": "🔍 Levigo is analyzing your request..."})
    agent_data = await create_supervisor_agent(state.get("session_id", ""), state.get("user_id", ""))
    llm = agent_data["llm"]
    
    history = _trim_messages(state.get("messages", []))
    
    # AI returns a RoutingDecision object directly thanks to with_structured_output
    decision: RoutingDecision = await llm.ainvoke(
        [SystemMessage(content=agent_data["system_prompt"])] + history
    )
    
    logger.info(f"⚖️ Supervisor Decision: {decision.next_agent} | Reason: {decision.reasoning}")
    
    return {"pending_departments": [decision.next_agent]}


async def goal_task_agent_node(state: HierarchicalState) -> Dict[str, Any]:
    """Specialist Node for Goals and Tasks with configurable iteration limit."""
    await adispatch_custom_event("status_update", {"message": "📋 Consulting planning specialist..."})
    agent_data = await create_goal_task_agent(state.get("session_id", ""), state.get("user_id", ""))
    llm, system_prompt, tools_map = agent_data["llm"], agent_data["system_prompt"], {t.name: t for t in agent_data["tools"]}
    
    history = _trim_messages(state.get("messages", []))
    new_messages = []
    
    # 🔍 Check if we are resuming from a breakdown confirmation
    # If so, we skip the initial tool generation and jump to processing the response
    current_context = [SystemMessage(content=system_prompt)] + history
    
    # Check for the last message in history - if it's the interrupt response, we skip loop
    # Actually, Functional API re-runs the whole node.
    
    # Manual ReAct loop using configurable limit
    for i in range(settings.MAX_TOOL_ITERATIONS):
        logger.info(f"🔄 Agent Iteration {i+1}/{settings.MAX_TOOL_ITERATIONS}")
        response = await llm.ainvoke(current_context + new_messages)
        new_messages.append(response)
        
        if not response.tool_calls:
            break
            
        # Normal ReAct loop: Agent decides when to call tools.
        # We removed the interrupt/approval step for simplicity as requested.
        results = await execute_tools_manually(response.tool_calls, tools_map)
        new_messages.extend(results)

    return {"messages": new_messages}


async def analytic_agent_node(state: HierarchicalState) -> Dict[str, Any]:
    """Specialist Node for data analysis and performance reviews."""
    await adispatch_custom_event("status_update", {"message": "📊 Analyzing productivity data..."})
    agent_data = await create_analytic_agent(state.get("session_id", ""), state.get("user_id", ""))
    llm, system_prompt, tools_map = agent_data["llm"], agent_data["system_prompt"], {t.name: t for t in agent_data["tools"]}
    
    history = _trim_messages(state.get("messages", []))
    new_messages = []
    current_context = [SystemMessage(content=system_prompt)] + history
    
    for i in range(settings.MAX_TOOL_ITERATIONS):
        logger.info(f"📊 Analytic Agent Iteration {i+1}/{settings.MAX_TOOL_ITERATIONS}")
        response = await llm.ainvoke(current_context + new_messages)
        new_messages.append(response)
        
        if not response.tool_calls:
            break
            
        results = await execute_tools_manually(response.tool_calls, tools_map)
        new_messages.extend(results)

    return {"messages": new_messages}


async def generic_agent_node(state: HierarchicalState) -> Dict[str, Any]:
    """Basic Assistant Node."""
    agent_data = await create_generic_agent(state.get("session_id", ""), state.get("user_id", ""))
    llm, system_prompt = agent_data["llm"], agent_data["system_prompt"]
    
    history = _trim_messages(state.get("messages", []))
    response = await llm.ainvoke([SystemMessage(content=system_prompt)] + history)
    
    return {"messages": [response]}


def router_node(state: HierarchicalState) -> Literal["goal_task_agent", "analytic_agent", "generic_agent", "end"]:
    """Routes based on the supervisor's decision."""
    pending = state.get("pending_departments", [])
    if not pending:
        return "end"
    
    next_node = pending.pop(0)
    if next_node == "end":
        return "end"
    
    return next_node


# ══════════════════════════════════════════════════════════════════════
# GRAPH BUILDER
# ══════════════════════════════════════════════════════════════════════

def build_orchestration_graph(checkpointer: Optional[AsyncPostgresSaver] = None):
    graph = StateGraph(HierarchicalState)
    
    # Add Nodes
    graph.add_node("supervisor", supervisor_node)
    graph.add_node("goal_task_agent", goal_task_agent_node)
    graph.add_node("analytic_agent", analytic_agent_node)
    graph.add_node("generic_agent", generic_agent_node)
    
    # Add Edges
    graph.add_edge(START, "supervisor")
    graph.add_conditional_edges("supervisor", router_node, {
        "goal_task_agent": "goal_task_agent",
        "analytic_agent": "analytic_agent",
        "generic_agent": "generic_agent",
        "end": END
    })
    
    # Specialist nodes go to END (or could loop back to supervisor if needed)
    graph.add_edge("goal_task_agent", END)
    graph.add_edge("analytic_agent", END)
    graph.add_edge("generic_agent", END)

    return graph.compile(checkpointer=checkpointer)


# ══════════════════════════════════════════════════════════════════════
# EXECUTORS (DATABASE AWARE)
# ══════════════════════════════════════════════════════════════════════

# Global checkpointer instance to ensure persistent state across requests
_global_checkpointer: Optional[AsyncPostgresSaver] = None

async def get_checkpointer(app_state: Optional[Any] = None) -> Optional[AsyncPostgresSaver]:
    """Get the active checkpointer from app state or return the global singleton (legacy)."""
    if app_state and hasattr(app_state, "checkpointer"):
        return app_state.checkpointer
        
    global _global_checkpointer
    return _global_checkpointer


async def stream_orchestration(query: str, session_id: str, user_id: str, checkpointer: Optional[AsyncPostgresSaver] = None) -> AsyncGenerator[Dict[str, Any], None]:
    """Main streaming executor for the orchestrator."""
    if not checkpointer:
        checkpointer = await get_checkpointer()
        
    graph = build_orchestration_graph(checkpointer)
    
    initial_state = {
        "messages": [HumanMessage(content=query)],
        "session_id": session_id,
        "user_id": user_id,
        "current_time": datetime.now().isoformat(),
        "pending_departments": [],
    }

    config = {"configurable": {"thread_id": session_id}}
    
    # 🎨 Track sent components to avoid duplicates during orchestration
    sent_component_ids = set()

    async for event in graph.astream_events(initial_state, config=config, version="v2"):
        kind = event["event"]
        node_name = event.get("metadata", {}).get("langgraph_node", "")
        
        if kind == "on_chat_model_stream" and node_name != "supervisor":
            content = event["data"].get("chunk", {}).content
            if content: yield {"type": "text", "content": content}
            
        elif kind == "on_tool_end":
            output = event.get("data", {}).get("output")
            # Use run_id or tool_call_id to unique identify this specific tool output
            call_id = event.get("run_id")
            
            if isinstance(output, ToolMessage) and call_id not in sent_component_ids:
                try:
                    content = json.loads(output.content)
                    if isinstance(content, dict) and "ui_component" in content:
                        logger.info(f"🎨 Emitter yielding NEW object: {content['ui_component']}")
                        yield {
                            "type": "object", 
                            "object": {
                                "type": content["ui_component"],
                                "data": content.get("data", {})
                            }
                        }
                        sent_component_ids.add(call_id)
                except:
                    pass
            
        elif kind == "on_custom_event":
            if event.get("name") == "ui_component_emitted":
                ui_data = event.get("data", {})
                # For custom events, we might need a different deduplication key or trust the emitter
                logger.info(f"🎨 Emitter yielding UI component from custom event: {ui_data.get('type')}")
                yield {
                    "type": "object",
                    "object": {
                        "type": ui_data.get("type"),
                        "data": ui_data.get("data", {})
                    }
                }
            elif event.get("name") == "status_update":
                status_data = event.get("data", {})
                yield {
                    "type": "status",
                    "content": status_data.get("message", "")
                }

        elif kind == "on_tool_start":
            tool_name = event.get("name")
            # CRITICAL SYNC: Use the tool_call_id from the event data if available
            # This ensures the frontend receives the EXACT same ID that the tool is waiting for.
            call_id = event.get("data", {}).get("tool_call_id") or event.get("run_id")
            
            logger.info(f"📡 Emitter yielding tool_call | {tool_name} | call_id: {call_id}")
            yield {"type": "tool_call", "tool_name": tool_name, "call_id": call_id}

        elif kind == "on_chat_model_end":
            output = event.get("data", {}).get("output")
            # Handle AI Message usage
            if output and hasattr(output, "usage_metadata") and output.usage_metadata:
                usage = output.usage_metadata
                logger.info(f"💰 Cost Tracker | User {user_id} | In: {usage.get('input_tokens', 0)} | Out: {usage.get('output_tokens', 0)} | Total: {usage.get('total_tokens', 0)}")



async def run_agent_workflow(query: str, session_id: str, user_id: str, checkpointer: Optional[AsyncPostgresSaver] = None) -> Dict[str, Any]:
    """Non-streaming executor for the orchestrator."""
    if not checkpointer:
        checkpointer = await get_checkpointer()
        
    graph = build_orchestration_graph(checkpointer)
    
    initial_state = {
        "messages": [HumanMessage(content=query)],
        "session_id": session_id,
        "user_id": user_id,
        "current_time": datetime.now().isoformat(),
        "pending_departments": [],
    }
    
    config = {"configurable": {"thread_id": session_id}}
    return await graph.ainvoke(initial_state, config=config)
