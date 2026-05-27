"""
Test workflow for experimenting with the Agent pipeline locally.
Uses SQLiteCRUDTool instead of Supabase so no network is required.

Usage:
    cd apps/agent-service
    env PYTHONPATH=. python -m app.tools.test_workflow

This script simulates the full chat workflow:
  1. Orchestrator → detect intent
  2. TaskManager / EventManager → extract structured data
  3. SQLite CRUD tool → persist locally
  4. Responsor → generate natural language response
"""

import asyncio
import json
import sys
import os

# Ensure project root is on the path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", ".."))

# Load .env so GEMINI_API_KEY etc. are available
from dotenv import load_dotenv
load_dotenv(override=True)

from datetime import datetime
from app.tools.sqlite_tool import get_sqlite_tool, SQLiteCRUDTool
from app.tools.seed_db import seed, DB_PATH, TEST_USER_ID

# BAML client
from baml_client.async_client import b as baml_client
from baml_client.types import Messages, UserIntent


# ── Helper ──────────────────────────────────────────────────────────
def print_section(title: str):
    print(f"\n{'='*60}")
    print(f"  {title}")
    print(f"{'='*60}")


def print_db_state(tool: SQLiteCRUDTool):
    """Print a snapshot of all tables."""
    for table in ["goals", "tasks", "events"]:
        res = tool.select(table, match_params={"user_id": TEST_USER_ID})
        rows = res.get("data", [])
        print(f"\n📋 {table.upper()} ({len(rows)} records):")
        for r in rows:
            if table == "goals":
                print(f"   • [{r.get('status','?')}] {r['title']} (id: {r['id'][:8]}...)")
            elif table == "tasks":
                goal_tag = f" → Goal {r['goal_id'][:8]}..." if r.get("goal_id") else ""
                print(f"   • [{r.get('status','?')}] {r['title']} | {r.get('priority','?')}{goal_tag}")
            elif table == "events":
                print(f"   • {r['title']} | {r.get('start_time','')} → {r.get('end_time','')}")


# ── Core workflow (mirrors routes.py logic) ─────────────────────────
async def run_agent_query(query: str, tool: SQLiteCRUDTool, history: list[Messages] = None):
    """Run a single user query through the full agent pipeline."""
    if history is None:
        history = []

    current_time = datetime.now().isoformat()

    # Step 1: Orchestrator → detect intent
    print_section(f"Query: \"{query}\"")
    intent = await baml_client.Orchestrator(
        query=query,
        context=f"current_time: {current_time}",
        messages=history,
    )
    print(f"🧠 Intent detected: {intent}")

    # Step 2: Tool execution based on intent
    tool_context = ""
    pending_action = None

    if intent == UserIntent.SCHEDULE_TASK:
        operations = await baml_client.TaskManager(
            request=query, context=f"current_time: {current_time}"
        )
        print(f"🔧 TaskManager returned {len(operations)} operation(s)")

        exec_results = []
        for op in operations:
            action_name = op.action.name if hasattr(op.action, "name") else str(op.action)
            print(f"   Action: {action_name}")

            if action_name == "CREATE" and op.task:
                data = {
                    "id": str(__import__("uuid").uuid4()),
                    "user_id": TEST_USER_ID,
                    "title": op.task.title,
                    "description": op.task.description,
                    "due_date": op.task.due_date,
                    "status": op.task.status.name if hasattr(op.task.status, "name") else str(op.task.status),
                    "priority": op.task.priority.name if hasattr(op.task.priority, "name") else str(op.task.priority) if hasattr(op.task.priority, "name") else op.task.priority,
                    "created_at": current_time,
                    "updated_at": current_time,
                }
                pending_action = {"action": "CREATE_TASK", "data": data}
                exec_results.append(f"Đã tạo bản nháp Task: '{op.task.title}'")

            elif action_name == "READ":
                # Search tasks
                results = tool.select("tasks", search_params={"title": query})
                exec_results.append(f"Tìm thấy {len(results.get('data', []))} task(s)")

        tool_context = "\nTOOL EXECUTION RESULT:\n" + "\n".join(exec_results) if exec_results else ""

    elif intent == UserIntent.SCHEDULE_EVENT:
        operations = await baml_client.EventManager(
            request=query, context=f"current_time: {current_time}"
        )
        print(f"🔧 EventManager returned {len(operations)} operation(s)")

        exec_results = []
        for op in operations:
            action_name = op.action.name if hasattr(op.action, "name") else str(op.action)
            if action_name == "CREATE" and op.event:
                data = {
                    "id": str(__import__("uuid").uuid4()),
                    "user_id": TEST_USER_ID,
                    "title": op.event.title,
                    "description": op.event.description,
                    "start_time": op.event.start_time,
                    "end_time": op.event.end_time,
                    "created_at": current_time,
                    "updated_at": current_time,
                }
                pending_action = {"action": "CREATE_EVENT", "data": data}
                exec_results.append(f"Đã tạo bản nháp Event: '{op.event.title}'")

        tool_context = "\nTOOL EXECUTION RESULT:\n" + "\n".join(exec_results) if exec_results else ""

    elif intent == UserIntent.SEARCH_CALENDAR:
        # Simple search across tasks and events
        task_results = tool.select("tasks", match_params={"user_id": TEST_USER_ID})
        event_results = tool.select("events", match_params={"user_id": TEST_USER_ID})
        tasks = task_results.get("data", [])
        events = event_results.get("data", [])

        search_text = "Tasks:\n"
        for t in tasks:
            search_text += f"  - {t['title']} (Due: {t.get('due_date', 'N/A')}, Status: {t.get('status', 'N/A')})\n"
        search_text += "Events:\n"
        for e in events:
            search_text += f"  - {e['title']} (Start: {e.get('start_time', 'N/A')})\n"

        tool_context = f"\nSEARCH RESULTS:\n{search_text}"

    # Step 3: Generate response
    context = f"current_time: {current_time}"
    if tool_context:
        context += tool_context

    response = await baml_client.Responsor(
        query=query, context=context, messages=history
    )
    print(f"\n💬 AI Response:\n{response}")

    # Step 4: Execute pending action (auto-confirm for testing)
    if pending_action:
        print(f"\n📦 Pending Action: {json.dumps(pending_action, indent=2, ensure_ascii=False)}")
        action = pending_action["action"]
        data = pending_action["data"]

        # Auto-execute for testing
        if action == "CREATE_TASK":
            result = tool.insert("tasks", data)
            print(f"   ✅ Task inserted: {result['status']}")
        elif action == "CREATE_EVENT":
            result = tool.insert("events", data)
            print(f"   ✅ Event inserted: {result['status']}")

    return response


# ── Main ────────────────────────────────────────────────────────────
async def main():
    # 1. Seed the database
    print_section("Seeding Database")
    seed(DB_PATH)

    # 2. Get the tool
    tool = get_sqlite_tool(DB_PATH)

    # 3. Show initial state
    print_section("Initial Database State")
    print_db_state(tool)

    # 4. Run test queries
    test_queries = [
        "Tạo task: Viết unit test cho GoalManager, ưu tiên cao, hạn chót ngày mai",
        "Lịch tuần này của tôi thế nào?",
        "Đặt lịch họp review code lúc 3h chiều mai",
    ]

    for q in test_queries:
        await run_agent_query(q, tool)

    # 5. Show final state
    print_section("Final Database State")
    print_db_state(tool)

    tool.close()


if __name__ == "__main__":
    asyncio.run(main())
