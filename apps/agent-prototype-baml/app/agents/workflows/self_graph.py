import sys
import asyncio
import json
from pathlib import Path
from dotenv import load_dotenv

# Add project root to sys.path and load .env
root_path = Path(__file__).parent.parent.parent.parent
if str(root_path) not in sys.path:
    sys.path.append(str(root_path))

load_dotenv(root_path / ".env")

from loguru import logger
from typing import TypedDict, Annotated, Any
from langgraph.graph import StateGraph, START, END
from langchain_core.runnables import RunnableConfig

from baml_client.type_builder import TypeBuilder
from baml_client.types import Blueprint, Step

from app.models.requests import ChatMessage
from app.services import schema_service

# Import nodes from modularized files
from app.agents.workflows.nodes.supervisor import supervisor_node
from app.agents.workflows.nodes.specialist import specialist_node, context_synthesizer_node
from app.agents.workflows.nodes.planner import planner_node
from app.agents.workflows.nodes.executor import executor_node, execute_tool_node
from app.agents.workflows.nodes.validator import validator_node
from app.agents.workflows.nodes.responsor import responsor_node


class AgentState(TypedDict):
    thread_id: str | None
    user_info: str | None

    query: str
    messages: list[ChatMessage]
    previous_tool_results: list[str] | None

    # Orchestrator outputs
    stages: list[dict] | None  # Each dict is {"order": int, "departments": list[str]}
    response: str | dict | None

    plan: Any | None
    blueprint: Blueprint | None
    blueprints: list[Blueprint]
    advices: list[str]
    error: str | None

    # Execution outputs
    allowed_tools: list[str] | None
    validator_reasoning: str | None
    validator_decision: str | None
    tool_name: str | None
    tool_data: dict | None
    current_step: int | None
    tool_history: list[dict] | None
    retry_count: int
    replan_count: int
    iterations: int


# ── Routing Logic ───────────────────────────────────────────────

def route_supervisor(state: AgentState) -> str:
    if state.get("iterations", 0) > 12:
        logger.warning("Max iterations reached in route_supervisor. Exiting.")
        return "responsor"
    if state.get("response"):
        return "responsor"
    stages = state.get("stages", [])
    if not stages or not stages[0].get("departments"):
        return "responsor"
    return "specialist"

def route_synthesizer(state: AgentState) -> str:
    if state.get("blueprint"):
        return "planner"
    return "responsor"

def route_executor(state: AgentState) -> str:
    if state.get("iterations", 0) > 12:
        logger.warning("Max iterations reached in route_executor. Exiting.")
        return "responsor"
    tool_name = state.get("tool_name")
    if tool_name == "chat_response" or not state.get("current_step"):
        stages = state.get("stages", [])
        if stages and stages[0].get("departments"):
            return "supervisor"
        return "responsor"
    return "execute_tool"

def route_validator(state: AgentState) -> str:
    decision = state.get("validator_decision", "")
    retries = state.get("retry_count", 0) or 0
    replans = state.get("replan_count", 0) or 0

    if state.get("iterations", 0) > 10:
        logger.info("DEBUG [validator_route]: Global max iterations. Exit.")
        return "responsor"

    if decision == "RETRY" and retries >= 3:
        logger.info(f"DEBUG [route_validator]: Retry limit reached ({retries}). Forcing exit.")
        return "responsor"
    
    if decision == "REPLAN" and replans >= 2:
        logger.info(f"DEBUG [route_validator]: Replan limit reached ({replans}). Forcing exit.")
        return "responsor"

    if decision == "PASS" or decision == "RETRY":
        return "executor"
    elif decision == "REPLAN":
        return "planner"

    stages = state.get("stages", [])
    if stages and stages[0].get("departments"):
        return "supervisor"
    return "responsor"


# ── Graph Assembly ──────────────────────────────────────────────

def create_agent_graph(checkpointer=None, interrupt_before=None):
    builder = StateGraph(AgentState)
    
    # Add nodes
    builder.add_node("supervisor", supervisor_node)
    builder.add_node("specialist", specialist_node)
    builder.add_node("context_synthesizer", context_synthesizer_node)
    builder.add_node("planner", planner_node)
    builder.add_node("executor", executor_node)
    builder.add_node("execute_tool", execute_tool_node)
    builder.add_node("validator", validator_node)
    builder.add_node("responsor", responsor_node)
    
    # Define edges and conditional routing
    builder.add_edge(START, "supervisor")
    builder.add_conditional_edges("supervisor", route_supervisor)
    
    builder.add_edge("specialist", "context_synthesizer")
    builder.add_conditional_edges("context_synthesizer", route_synthesizer)
    
    builder.add_edge("planner", "executor")
    builder.add_conditional_edges("executor", route_executor)
    
    builder.add_edge("execute_tool", "validator")
    builder.add_conditional_edges("validator", route_validator)
    
    builder.add_edge("responsor", END)

    return builder.compile(checkpointer=checkpointer, interrupt_before=interrupt_before)


if __name__ == "__main__":
    async def main():
        # Sync types
        tb = TypeBuilder()
        await schema_service.sync_type_builder(tb)

        # Initial state
        state = {
            "query": "Show me a chart summarizing my completed tasks this week.",
            "messages": [],
            "user_info": "",
            "plan": None,
            "blueprints": [],
            "advices": [],
            "error": None,
            "tool_history": [],
            "retry_count": 0,
            "replan_count": 0,
            "current_step": 0,
            "iterations": 0
        }
        
        agent_graph = create_agent_graph()
        logger.info("--- Starting Graph Execution ---")
        res = await agent_graph.ainvoke(state)

        print("\n\nFINAL RESULT:")
        print(json.dumps(res.get("response"), indent=2, ensure_ascii=False))

    asyncio.run(main())
