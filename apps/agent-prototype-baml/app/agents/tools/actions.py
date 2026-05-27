"""
Tool Actions — Decorated tool functions for the hierarchical agent.

These are automatically registered with the ToolRegistry when imported.
Each function uses the @tool decorator to define its name, description,
and parameter schema (inferred from type hints).
"""

import json
import uuid
from datetime import datetime
from typing import Annotated, Optional

from pydantic import Field

from app.agents.tools.registry import tool
from app.tools.sqlite_tool import get_sqlite_tool


# ══════════════════════════════════════════════════════════════════════
# TASK TOOLS
# ══════════════════════════════════════════════════════════════════════

@tool("create_task", "Create a new task for the user")
async def create_task(
    user_id: Annotated[str, Field(description="The user's unique ID")],
    title: Annotated[str, Field(description="Title of the task")],
    description: Annotated[Optional[str], Field(description="Optional description")] = None,
    due_date: Annotated[Optional[str], Field(description="Due date in ISO format (e.g. 2026-03-10T09:00:00)")] = None,
    priority: Annotated[str, Field(description="Priority: CRITICAL, HIGH, MEDIUM, or LOW")] = "MEDIUM",
    is_completed: Annotated[bool, Field(description="Completion status: true or false")] = False,
) -> dict:
    """Create a new task in the database."""
    db = get_sqlite_tool()
    data = {
        "id": str(uuid.uuid4()),
        "user_id": user_id,
        "title": title,
        "is_completed": 1 if is_completed else 0,
        "priority": priority,
        "created_at": datetime.now().isoformat(),
        "updated_at": datetime.now().isoformat(),
    }
    if description:
        data["description"] = description
    if due_date:
        data["due_date"] = due_date
    return db.insert("tasks", data)


@tool("search_tasks", "Search for tasks by keyword, status, or priority. If all filters are null, returns all tasks.")
async def search_tasks(
    user_id: Annotated[str, Field(description="The user's unique ID")],
    keyword: Annotated[Optional[str], Field(description="Search by task title (partial match)")] = None,
    is_completed: Annotated[Optional[bool], Field(description="Filter by completion status")] = None,
    priority: Annotated[Optional[str], Field(description="Filter by priority: CRITICAL, HIGH, MEDIUM, LOW")] = None,
) -> dict:
    """Search tasks in the database."""
    db = get_sqlite_tool()
    params = {"user_id": user_id}
    if keyword:
        params["title"] = keyword
    if is_completed is not None:
        params["is_completed"] = 1 if is_completed else 0
    if priority:
        params["priority"] = priority

    # Use search_params for partial matching on title, match_params for exact
    search_params = {}
    match_params = {"user_id": user_id}
    if keyword:
        search_params["title"] = keyword
    if is_completed is not None:
        match_params["is_completed"] = 1 if is_completed else 0
    if priority:
        match_params["priority"] = priority

    return db.select("tasks", match_params=match_params, search_params=search_params if search_params else None)


@tool("get_task_by_id", "Retrieve a specific task by its UUID")
async def get_task_by_id(
    user_id: Annotated[str, Field(description="The user's unique ID")],
    task_id: Annotated[str, Field(description="The UUID of the task")],
) -> dict:
    """Get a single task by ID."""
    db = get_sqlite_tool()
    results = db.select("tasks", match_params={"id": task_id, "user_id": user_id})
    if results.get("status") == "success" and results.get("data"):
        return {"status": "success", "data": results["data"][0]}
    return {"status": "error", "message": "Task not found"}


@tool("update_task", "Update an existing task")
async def update_task(
    user_id: Annotated[str, Field(description="The user's unique ID")],
    task_id: Annotated[str, Field(description="The UUID of the task to update")],
    title: Annotated[Optional[str], Field(description="New title")] = None,
    description: Annotated[Optional[str], Field(description="New description")] = None,
    due_date: Annotated[Optional[str], Field(description="New due date in ISO format")] = None,
    is_completed: Annotated[Optional[bool], Field(description="New completion status")] = None,
    priority: Annotated[Optional[str], Field(description="New priority: CRITICAL, HIGH, MEDIUM, LOW")] = None,
) -> dict:
    """Update an existing task in the database."""
    db = get_sqlite_tool()
    data = {"updated_at": datetime.now().isoformat()}
    if title:
        data["title"] = title
    if description:
        data["description"] = description
    if due_date:
        data["due_date"] = due_date
    if is_completed is not None:
        data["is_completed"] = 1 if is_completed else 0
    if priority:
        data["priority"] = priority
    return db.update("tasks", match_params={"id": task_id, "user_id": user_id}, data=data)


@tool("delete_task", "Delete a task")
async def delete_task(
    user_id: Annotated[str, Field(description="The user's unique ID")],
    task_id: Annotated[str, Field(description="The UUID of the task to delete")],
) -> dict:
    """Delete a task from the database."""
    db = get_sqlite_tool()
    return db.delete("tasks", match_params={"id": task_id, "user_id": user_id})


# ══════════════════════════════════════════════════════════════════════
# EVENT / CALENDAR TOOLS
# ══════════════════════════════════════════════════════════════════════

@tool("create_event", "Create a new calendar event")
async def create_event(
    user_id: Annotated[str, Field(description="The user's unique ID")],
    title: Annotated[str, Field(description="Title of the event")],
    start_time: Annotated[str, Field(description="Start time in ISO format (e.g. 2026-03-10T14:00:00)")],
    end_time: Annotated[str, Field(description="End time in ISO format (e.g. 2026-03-10T15:00:00)")],
    description: Annotated[Optional[str], Field(description="Optional description")] = None,
    rrule: Annotated[Optional[str], Field(description="Recurrence rule in iCalendar format")] = None,
) -> dict:
    """Create a new calendar event."""
    db = get_sqlite_tool()
    data = {
        "id": str(uuid.uuid4()),
        "user_id": user_id,
        "title": title,
        "start_time": start_time,
        "end_time": end_time,
        "created_at": datetime.now().isoformat(),
        "updated_at": datetime.now().isoformat(),
    }
    if description:
        data["description"] = description
    if rrule:
        data["rrule"] = rrule
    return db.insert("events", data)


@tool("search_events", "Search calendar events by title or time range. If all filters are null, returns all upcoming events.")
async def search_events(
    user_id: Annotated[str, Field(description="The user's unique ID")],
    title: Annotated[Optional[str], Field(description="Search by event title (partial match)")] = None,
    start_time: Annotated[Optional[str], Field(description="Filter events starting after this ISO datetime")] = None,
) -> dict:
    """Search calendar events."""
    db = get_sqlite_tool()
    match_params = {"user_id": user_id}
    search_params = {}
    if title:
        search_params["title"] = title
    if start_time:
        search_params["start_time"] = start_time
    return db.select("events", match_params=match_params, search_params=search_params if search_params else None)


@tool("get_event_by_id", "Retrieve a specific calendar event by its UUID")
async def get_event_by_id(
    user_id: Annotated[str, Field(description="The user's unique ID")],
    event_id: Annotated[str, Field(description="The UUID of the event")],
) -> dict:
    """Get a single event by ID."""
    db = get_sqlite_tool()
    results = db.select("events", match_params={"id": event_id, "user_id": user_id})
    if results.get("status") == "success" and results.get("data"):
        return {"status": "success", "data": results["data"][0]}
    return {"status": "error", "message": "Event not found"}


@tool("update_event", "Update an existing calendar event")
async def update_event(
    user_id: Annotated[str, Field(description="The user's unique ID")],
    event_id: Annotated[str, Field(description="The UUID of the event to update")],
    title: Annotated[Optional[str], Field(description="New title")] = None,
    description: Annotated[Optional[str], Field(description="New description")] = None,
    start_time: Annotated[Optional[str], Field(description="New start time in ISO format")] = None,
    end_time: Annotated[Optional[str], Field(description="New end time in ISO format")] = None,
) -> dict:
    """Update an existing calendar event."""
    db = get_sqlite_tool()
    data = {"updated_at": datetime.now().isoformat()}
    if title:
        data["title"] = title
    if description:
        data["description"] = description
    if start_time:
        data["start_time"] = start_time
    if end_time:
        data["end_time"] = end_time
    return db.update("events", match_params={"id": event_id, "user_id": user_id}, data=data)


@tool("delete_event", "Delete a calendar event")
async def delete_event(
    user_id: Annotated[str, Field(description="The user's unique ID")],
    event_id: Annotated[str, Field(description="The UUID of the event to delete")],
) -> dict:
    """Delete a calendar event."""
    db = get_sqlite_tool()
    return db.delete("events", match_params={"id": event_id, "user_id": user_id})


# ══════════════════════════════════════════════════════════════════════
# GOAL TOOLS
# ══════════════════════════════════════════════════════════════════════

@tool("create_goal", "Create a new goal for the user")
async def create_goal(
    user_id: Annotated[str, Field(description="The user's unique ID")],
    title: Annotated[str, Field(description="Title of the goal")],
    description: Annotated[Optional[str], Field(description="Optional description")] = None,
    start_date: Annotated[Optional[str], Field(description="Start date in ISO format")] = None,
    end_date: Annotated[Optional[str], Field(description="End date in ISO format")] = None,
) -> dict:
    """Create a new goal."""
    db = get_sqlite_tool()
    data = {
        "id": str(uuid.uuid4()),
        "user_id": user_id,
        "title": title,
        "status": "ACTIVE",
        "created_at": datetime.now().isoformat(),
        "updated_at": datetime.now().isoformat(),
    }
    if description:
        data["description"] = description
    if start_date:
        data["start_date"] = start_date
    if end_date:
        data["end_date"] = end_date
    return db.insert("goals", data)


@tool("search_goals", "Search goals by title or status. If all filters are null, returns all goals.")
async def search_goals(
    user_id: Annotated[str, Field(description="The user's unique ID")],
    title: Annotated[Optional[str], Field(description="Search by goal title (partial match)")] = None,
    status: Annotated[Optional[str], Field(description="Filter by status: ACTIVE, COMPLETED, ARCHIVED")] = None,
) -> dict:
    """Search goals."""
    db = get_sqlite_tool()
    match_params = {"user_id": user_id}
    search_params = {}
    if title:
        search_params["title"] = title
    if status:
        match_params["status"] = status
    return db.select("goals", match_params=match_params, search_params=search_params if search_params else None)


@tool("get_goal_by_id", "Retrieve a specific goal by its UUID")
async def get_goal_by_id(
    user_id: Annotated[str, Field(description="The user's unique ID")],
    goal_id: Annotated[str, Field(description="The UUID of the goal")],
) -> dict:
    """Get a single goal by ID."""
    db = get_sqlite_tool()
    results = db.select("goals", match_params={"id": goal_id, "user_id": user_id})
    if results.get("status") == "success" and results.get("data"):
        return {"status": "success", "data": results["data"][0]}
    return {"status": "error", "message": "Goal not found"}


# ══════════════════════════════════════════════════════════════════════
# ACTION CARD QUERY TOOLS
# ══════════════════════════════════════════════════════════════════════

@tool("get_dashboard_stats", "Get an overview of user's task/goal stats including counts and per-goal progress. Use for INSIGHT action cards.")
async def get_dashboard_stats(
    user_id: Annotated[str, Field(description="The user's unique ID")],
) -> dict:
    """Aggregate dashboard stats: tasks done/overdue/on_track + per-goal progress."""
    db = get_sqlite_tool()
    conn = db.conn
    now = datetime.now().isoformat()

    try:
        # Task counts
        tasks_done = conn.execute(
            "SELECT COUNT(*) as cnt FROM tasks WHERE user_id = ? AND is_completed = 1",
            (user_id,)
        ).fetchone()["cnt"]

        tasks_overdue = conn.execute(
            "SELECT COUNT(*) as cnt FROM tasks WHERE user_id = ? AND is_completed = 0 AND due_date IS NOT NULL AND due_date < ?",
            (user_id, now)
        ).fetchone()["cnt"]

        tasks_total = conn.execute(
            "SELECT COUNT(*) as cnt FROM tasks WHERE user_id = ? AND is_completed = 0",
            (user_id,)
        ).fetchone()["cnt"]

        tasks_on_track = max(0, tasks_total - tasks_overdue)

        # Per-goal progress
        goals = conn.execute(
            "SELECT id, title, status FROM goals WHERE user_id = ?",
            (user_id,)
        ).fetchall()

        goal_progress = []
        warnings = []
        for g in goals:
            total = conn.execute(
                "SELECT COUNT(*) as cnt FROM tasks WHERE user_id = ? AND description LIKE ?",
                (user_id, f"%{g['title']}%")
            ).fetchone()["cnt"]
            done = conn.execute(
                "SELECT COUNT(*) as cnt FROM tasks WHERE user_id = ? AND description LIKE ? AND is_completed = 1",
                (user_id, f"%{g['title']}%")
            ).fetchone()["cnt"]

            pct = done / total if total > 0 else 0.0
            status = "on_track"
            if pct < 0.3 and total > 0:
                status = "at_risk"
                warnings.append(f"Goal '{g['title']}' is at risk — only {int(pct*100)}% completed.")
            elif pct < 0.6 and total > 0:
                status = "behind"

            goal_progress.append({
                "goal_title": g["title"],
                "progress_pct": round(pct, 2),
                "status": status,
            })

        return {
            "status": "success",
            "data": {
                "tasks_done": tasks_done,
                "tasks_overdue": tasks_overdue,
                "tasks_on_track": tasks_on_track,
                "goal_progress": goal_progress,
                "warnings": warnings,
            }
        }
    except Exception as e:
        return {"status": "error", "message": f"Dashboard stats error: {str(e)}"}


@tool("get_today_focus", "Get the top 3 highest priority tasks due today or soon. Use for FOCUS action cards.")
async def get_today_focus(
    user_id: Annotated[str, Field(description="The user's unique ID")],
) -> dict:
    """Get top 3 priority tasks for today's focus."""
    db = get_sqlite_tool()
    conn = db.conn
    today = datetime.now().strftime("%Y-%m-%d")

    try:
        # Priority order: CRITICAL > HIGH > MEDIUM > LOW
        rows = conn.execute(
            """
            SELECT id, title, priority, due_date, is_completed, description
            FROM tasks
            WHERE user_id = ? AND is_completed = 0
            ORDER BY
                CASE priority
                    WHEN 'CRITICAL' THEN 1
                    WHEN 'HIGH' THEN 2
                    WHEN 'MEDIUM' THEN 3
                    WHEN 'LOW' THEN 4
                    ELSE 5
                END,
                CASE WHEN due_date IS NOT NULL AND due_date <= ? THEN 0 ELSE 1 END,
                due_date ASC
            LIMIT 3
            """,
            (user_id, today + "T23:59:59")
        ).fetchall()

        tasks = []
        for r in rows:
            # Estimate minutes based on priority
            est = {"CRITICAL": 60, "HIGH": 45, "MEDIUM": 30, "LOW": 15}.get(r.get("priority", "MEDIUM"), 30)
            tasks.append({
                "task_id": r["id"],
                "title": r["title"],
                "goal_tag": None,  # Could be enriched later
                "estimated_minutes": est,
                "is_completed": bool(r["is_completed"]),
            })

        return {
            "status": "success",
            "data": {
                "date": today,
                "tasks": tasks,
            }
        }
    except Exception as e:
        return {"status": "error", "message": f"Today focus error: {str(e)}"}


@tool("get_overdue_tasks", "Get all tasks that are past their due date. Use for RESCHEDULE action cards.")
async def get_overdue_tasks(
    user_id: Annotated[str, Field(description="The user's unique ID")],
) -> dict:
    """Get all overdue (incomplete + past due_date) tasks."""
    db = get_sqlite_tool()
    conn = db.conn
    now = datetime.now().isoformat()

    try:
        rows = conn.execute(
            """
            SELECT id, title, due_date, priority
            FROM tasks
            WHERE user_id = ? AND is_completed = 0 AND due_date IS NOT NULL AND due_date < ?
            ORDER BY due_date ASC
            """,
            (user_id, now)
        ).fetchall()

        overdue = []
        for r in rows:
            # Suggest new date: original + 3 days from now
            from datetime import timedelta
            suggested = (datetime.now() + timedelta(days=3)).strftime("%Y-%m-%dT%H:%M:%S")
            overdue.append({
                "task_id": r["id"],
                "title": r["title"],
                "original_due": r["due_date"],
                "suggested_due": suggested,
            })

        return {
            "status": "success",
            "data": {
                "overdue_tasks": overdue,
            }
        }
    except Exception as e:
        return {"status": "error", "message": f"Overdue tasks error: {str(e)}"}


@tool("get_weekly_summary", "Get a summary of the past week's activity. Use for REFLECTION action cards.")
async def get_weekly_summary(
    user_id: Annotated[str, Field(description="The user's unique ID")],
) -> dict:
    """Get weekly summary stats for reflection."""
    db = get_sqlite_tool()
    conn = db.conn

    try:
        from datetime import timedelta
        now = datetime.now()
        week_ago = (now - timedelta(days=7)).isoformat()

        # Tasks completed this week
        completed_this_week = conn.execute(
            "SELECT COUNT(*) as cnt FROM tasks WHERE user_id = ? AND is_completed = 1 AND updated_at >= ?",
            (user_id, week_ago)
        ).fetchone()["cnt"]

        # Tasks created this week
        created_this_week = conn.execute(
            "SELECT COUNT(*) as cnt FROM tasks WHERE user_id = ? AND created_at >= ?",
            (user_id, week_ago)
        ).fetchone()["cnt"]

        # Events this week
        events_this_week = conn.execute(
            "SELECT COUNT(*) as cnt FROM events WHERE user_id = ? AND start_time >= ?",
            (user_id, week_ago)
        ).fetchone()["cnt"]

        # Total still pending
        pending_total = conn.execute(
            "SELECT COUNT(*) as cnt FROM tasks WHERE user_id = ? AND is_completed = 0",
            (user_id,)
        ).fetchone()["cnt"]

        return {
            "status": "success",
            "data": {
                "week_start": week_ago,
                "week_end": now.isoformat(),
                "tasks_completed": completed_this_week,
                "tasks_created": created_this_week,
                "events_attended": events_this_week,
                "tasks_still_pending": pending_total,
            }
        }
    except Exception as e:
        return {"status": "error", "message": f"Weekly summary error: {str(e)}"}
