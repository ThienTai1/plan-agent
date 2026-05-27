import asyncio
import json
import os
from dotenv import load_dotenv
load_dotenv()
from baml_client.async_client import b
from baml_client.types import PlannerInput, Blueprint

async def test_repro():
    print("--- TESTING PLANNER ---")
    blueprint = Blueprint(
        objective="Create a new task with the title 'Buy milk' scheduled for tomorrow morning.",
        thought="The user wants to create a new task. To prevent duplicates, search for a task with 'Buy milk' first. If not found, create it."
    )
    
    planner_res = await b.Planner(
        input=PlannerInput(
            context="current time: Monday, 03/09/2026",
            specialist_name="MANAGEMENT",
            blueprint=blueprint,
            tool_results=[],
            allowed_tools=["search_tasks", "update_task", "create_task"]
        )
    )
    
    print(f"Plan Reasoning: {planner_res.reasoning}")
    for step in planner_res.steps:
        print(f"Step {step.step}: {step.description}")

    if not planner_res.steps or len(planner_res.steps) < 2:
        print("FAILED: Planner only generated one step.")
        return

    print("\n--- TESTING EXECUTOR (Step 2: Create) ---")
    # Simulate Step 1 (Search) returning 0 results
    context_after_search = """[SYSTEM]
current_time: 2026-03-09 09:00:00 UTC
persona: Smart AI Assistant

[PREVIOUS OPERATION RESULTS]
Action: search tasks (0 results)"""

    executor_res = await b.Executor(
        input={
            "context": context_after_search,
            "step_description": planner_res.steps[1].description,
            "allowed_tools": ["search_tasks", "update_task", "create_task"]
        }
    )
    
    print(f"Executor Thought: {executor_res.thought}")
    if executor_res.tool_call:
        tool_name = list(executor_res.tool_call.model_dump(exclude_none=True).keys())[0]
        print(f"Selected Tool: {tool_name}")
    else:
        print("Selected Tool: NONE (chat_response)")

if __name__ == "__main__":
    asyncio.run(test_repro())
