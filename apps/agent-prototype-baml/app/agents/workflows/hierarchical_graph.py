import json
from datetime import datetime
from typing import List, Dict, Any, Optional, TypedDict, Annotated
import uuid

from langgraph.graph import StateGraph, START, END
from langgraph.checkpoint.memory import MemorySaver
from dotenv import load_dotenv

load_dotenv(override=True)

from baml_client.async_client import b as baml_client
from baml_client.types import (
    Messages, Blueprint, Step, ValidationResult, ValidationDecision,
    AgentResponse, OrchestratorResult, Department, StepExecution, Plan
)
from app.agents.workflows.states.hierarchical_state import HierarchicalState, PendingAction, create_initial_state
from app.agents.tools.registry import tool_registry
import app.agents.tools.actions  # Ensure tools are registered
from app.tools.sqlite_tool import get_sqlite_tool
from app.tools.seed_db import TEST_USER_ID

# ══════════════════════════════════════════════════════════════════════
# NODE FUNCTIONS
# ══════════════════════════════════════════════════════════════════════

async def supervisor_node(state: HierarchicalState) -> Dict[str, Any]:
    """Analyze request and identify relevant departments."""
    print("--- 🤖 SUPERVISOR: Analyzing request ---")
    
    current_time_str = f"current_time: {state['current_time']}"
    baml_history = [Messages(role=m.role, content=m.content) for m in state["history"]]
    
    res: OrchestratorResult = await baml_client.Orchestrator(
        query=state["user_message"],
        context=current_time_str,
        messages=baml_history
    )
    
    departments = []
    for stage in res.stages:
        for dept in stage.departments:
            if dept == Department.MANAGEMENT:
                departments.append("MANAGEMENTS")
            elif dept == Department.ANALYTICS:
                departments.append("ANALYST")
    
    print(f"Orchestrator result: {res.stages}, Selected Departments: {departments}")
    
    return {
        "pending_departments": departments
    }

async def specialist_node(state: HierarchicalState) -> Dict[str, Any]:
    """Act as domain expert and create a Blueprint."""
    dept = state["pending_departments"][0]
    print(f"--- 🧑‍💼 SPECIALIST: {dept} ---")
    
    baml_history = [Messages(role=m.role, content=m.content) for m in state["history"]]
    blueprint = None
    
    if dept == "MANAGEMENTS":
        blueprint = await baml_client.ManagementSpecialist(
            input={
                "query": state["user_message"],
                "context": state["current_time"],
                "history": baml_history
            }
        )
    elif dept == "ANALYST":
        blueprint = await baml_client.AnalyticsSpecialist(
            input={
                "query": state["user_message"],
                "context": state["current_time"],
                "history": baml_history
            }
        )
    
    return {
        "current_department": dept,
        "pending_departments": state["pending_departments"][1:],
        "blueprint": blueprint,
        "allowed_tools": [] # Specialist no longer decides tools in new BAML schema
    }

async def planner_node(state: HierarchicalState) -> Dict[str, Any]:
    """Create a detailed plan from the Blueprint."""
    print("--- 📝 PLANNER: Creating plan ---")
    
    # history_str = json.dumps([m.model_dump() for m in state["history"]]) # Removed broken debug line
    plan_obj: Plan = await baml_client.Planner(
        input={
            "context": state["current_time"],
            "specialist_name": state["current_department"],
            "blueprint": state["blueprint"],
            "allowed_tools": state["allowed_tools"],
            "tool_results": [] # Or map from state if available
        }
    )
    plan = plan_obj.steps or []
    
    return {
        "plan": plan,
        "current_step_index": 0
    }

async def executor_node(state: HierarchicalState) -> Dict[str, Any]:
    """Select tool to execute the current step."""
    step = state["plan"][state["current_step_index"]]
    print(f"--- ⚙️ EXECUTOR: Executing step {step.id} ---")
    
    # State string for context
    current_state_str = "\n".join([f"{m['role']}: {m['content']}" for m in state["messages"]])
    
    # If there's feedback from validator, add to context
    if state.get("validation_decision") == ValidationDecision.RETRY:
         # Lấy feedback cuối cùng
         last_feedback = ""
         for m in reversed(state["messages"]):
              if m["role"] == "system" and "[VALIDATION FEEDBACK]" in m["content"]:
                   last_feedback = m["content"]
                   break
         current_state_str += f"\n\n[IMPORTANT - FIX NEEDED]: {last_feedback}"

    tb = tool_registry.build_type_builder(allowed_tools=state["blueprint"].allowed_tools)

    res: StepExecution = await baml_client.Executor(
        input={
            "context": current_state_str,
            "step_description": step.description,
            "allowed_tools": state["allowed_tools"]
        },
        baml_options={"tb": tb}
    )
    
    return {
        "last_execution_result": res.thought if res.thought else None,
        "pending_action": (lambda tc: {
            "type": next((k for k, v in tc.model_dump().items() if v is not None), "unknown"),
            "display": f"Executing tool...",
            "data": next((v for k, v in tc.model_dump().items() if v is not None), {})
        })(res.tool_call) if res.tool_call else None
    }

async def execute_tool_node(state: HierarchicalState) -> Dict[str, Any]:
    """Execute the actual tool (Python) and record the Observation."""
    action = state["pending_action"]
    print(f"--- 🔧 EXECUTE TOOL: {action['type']} ---")
    
    # Log Thought
    messages = list(state["messages"])
    messages.append({"role": "assistant", "content": f"[THOUGHT] Executing {action['type']} with data {json.dumps(action['data'])}"})
    
    # Ensure user_id is passed to tools
    tool_args = action["data"].copy()
    if "user_id" not in tool_args:
        tool_args["user_id"] = state["user_id"]

    # Execute via registry
    print(f"DEBUG: Calling registry for {action['type']}...")
    result_obj = await tool_registry.execute(action["type"], tool_args)
    result_str = json.dumps(result_obj, ensure_ascii=False)
    print(f"DEBUG: Tool result: {result_str[:100]}...")
        
    messages.append({"role": "system", "content": f"[OBSERVATION] {result_str}"})
    
    return {
        "messages": messages,
        "last_execution_result": result_str,
        "pending_action": None
    }

async def client_harness_node(state: HierarchicalState) -> Dict[str, Any]:
    """
    A placeholder node that acts as a breakpoint for client-side tool execution.
    The graph will interrupt before this node, allowing the WebSocket handler
    to send the pending_action to the client.
    """
    print(f"--- 📱 CLIENT HARNESS: Waiting for {state['pending_action']['type']} ---")
    # This node doesn't do anything because we capture the state BEFORE it runs.
    # After client returns results, we update the state and RESUME from here.
    return {}

async def validator_node(state: HierarchicalState) -> Dict[str, Any]:
    """Validate the execution result."""
    print("--- 🧐 VALIDATOR: Validating ---")
    
    step = state["plan"][state["current_step_index"]]
    res: ValidationResult = await baml_client.Validator(
        input={
            "context": state["current_time"],
            "plan": Plan(steps=state["plan"]),
            "current_step": state["current_step_index"],
            "tool_results": [] # Map tool results here
        }
    )
    
    print(f"Decision: {res.decision}")
    
    messages = list(state["messages"])
    new_pending_depts = list(state["pending_departments"])
    if res.decision == ValidationDecision.FINISH:
        if new_pending_depts:
            print(f"DEBUG: Department {new_pending_depts[0]} marked as FINISH. Popping.")
            new_pending_depts.pop(0)
    elif res.decision == ValidationDecision.NEXT_STEP:
        if state["current_step_index"] + 1 >= len(state["plan"]):
            if new_pending_depts:
                print(f"DEBUG: Plan completed for {new_pending_depts[0]}. Popping.")
                new_pending_depts.pop(0)

    print(f"DEBUG: Validation Decision: {res.decision}, Remaining Depts: {new_pending_depts}")

    return {
        "messages": messages,
        "validation_decision": res.decision,
        "pending_departments": new_pending_depts,
        "current_step_index": state["current_step_index"] + 1 if res.decision == ValidationDecision.NEXT_STEP else state["current_step_index"]
    }

async def responsor_node(state: HierarchicalState) -> Dict[str, Any]:
    """Synthesize the final answer."""
    print("--- 💬 RESPONSOR: Generating response ---")
    
    current_time_str = f"current_time: {state['current_time']}"
    baml_history = [Messages(role=m.role, content=m.content) for m in state["history"]]
    
    # Context includes internal messages (THOUGHT/OBSERVATION)
    internal_context = "\n".join([f"{m['role']}: {m['content']}" for m in state["messages"]])
    
    plan_str = None
    if state["plan"]:
         plan_str = "\n".join([f"- {s.description}" for s in state["plan"]])

    ans: AgentResponse = await baml_client.Responsor(
        query=state["user_message"],
        context=f"{current_time_str}\n\nINTERNAL LOGS:\n{internal_context}",
        plan=plan_str,
        tool_history=None,
        validator_reasoning=None,
        messages=baml_history,
    )
    
    # Process blocks into a single final_answer string or structured data
    # For simplicity in this workflow, we'll serialize the blocks
    # so they can be parsed by the stream route.
    import json
    
    blocks_data = []
    for block in ans.blocks:
        block_dict = {
            "type": block.component_type.name.lower(),
        }
        if block.text:
            block_dict["text"] = block.text
        if block.chart_data:
            block_dict["chart_data"] = block.chart_data.model_dump()
        if block.breakdown_data:
            block_dict["breakdown_data"] = block.breakdown_data.model_dump()
        if block.insight_data:
            block_dict["insight_data"] = block.insight_data.model_dump()
        if block.focus_data:
            block_dict["focus_data"] = block.focus_data.model_dump()
        if block.reschedule_data:
            block_dict["reschedule_data"] = block.reschedule_data.model_dump()
        if block.reflection_data:
            block_dict["reflection_data"] = block.reflection_data.model_dump()
            
        blocks_data.append(block_dict)

    print(f"--- ✅ RESPONSOR DONE: {len(blocks_data)} blocks generated ---")
    return {"final_answer": json.dumps(blocks_data)}

# ══════════════════════════════════════════════════════════════════════
# ROUTING FUNCTIONS
# ══════════════════════════════════════════════════════════════════════

def route_supervisor(state: HierarchicalState):
    if state["pending_departments"]:
        return "specialist"
    return "responsor"

def route_specialist(state: HierarchicalState):
    if state["blueprint"]:
        return "planner"
    return "supervisor" # Hoặc End nếu không có blueprint

def route_executor(state: HierarchicalState):
    if state["pending_action"]:
        if state.get("is_pro"):
            return "execute_tool"
        else:
            return "client_harness"
    return "validator"

def route_validator(state: HierarchicalState):
    decision = state["validation_decision"]
    if decision == ValidationDecision.FINISH:
        if state["pending_departments"]:
            return "specialist"
        return "responsor"
    elif decision == ValidationDecision.NEXT_STEP:
        if state["current_step_index"] < len(state["plan"]):
            return "executor"
        else:
            if state["pending_departments"]:
                return "specialist"
            return "responsor"
    elif decision == ValidationDecision.REPLAN:
        return "planner"
    elif decision == ValidationDecision.RETRY:
        return "executor"
    return "responsor"

# ══════════════════════════════════════════════════════════════════════
# BUILD THE GRAPH
# ══════════════════════════════════════════════════════════════════════

def build_hierarchical_graph(interrupt_before: list[str] | None = None):
    workflow = StateGraph(HierarchicalState)
    
    workflow.add_node("supervisor", supervisor_node)
    workflow.add_node("specialist", specialist_node)
    workflow.add_node("planner", planner_node)
    workflow.add_node("executor", executor_node)
    workflow.add_node("execute_tool", execute_tool_node)
    workflow.add_node("client_harness", client_harness_node)
    workflow.add_node("validator", validator_node)
    workflow.add_node("responsor", responsor_node)
    
    workflow.set_entry_point("supervisor")
    
    workflow.add_conditional_edges("supervisor", route_supervisor, {
        "specialist": "specialist",
        "responsor": "responsor",
        END: END
    })
    
    workflow.add_conditional_edges("specialist", route_specialist, {
        "planner": "planner",
        "supervisor": "supervisor"
    })
    
    workflow.add_edge("planner", "executor")
    
    workflow.add_conditional_edges("executor", route_executor, {
        "execute_tool": "execute_tool",
        "client_harness": "client_harness",
        "validator": "validator"
    })
    
    workflow.add_edge("execute_tool", "validator")
    workflow.add_edge("client_harness", "validator")
    
    workflow.add_conditional_edges("validator", route_validator, {
        "specialist": "specialist",
        "executor": "executor",
        "planner": "planner",
        "responsor": "responsor"
    })
    
    workflow.add_edge("responsor", END)
    
    memory = MemorySaver()
    return workflow.compile(checkpointer=memory, interrupt_before=interrupt_before)


if __name__ == "__main__":
    import asyncio
    async def test():
        app = build_hierarchical_graph()
        initial_state = create_initial_state(
            user_message="Create a task to buy milk and check my calendar for tomorrow",
            user_id=TEST_USER_ID,
            current_time=datetime.now().isoformat(),
        )
        config = {"configurable": {"thread_id": "test-1"}}
        async for event in app.astream(initial_state, config=config):
            print(event)
            
    asyncio.run(test())
