"""
SERVER_TOOLS.PY - Tools that execute directly on the Server.
Replaces Frontend Tools for increased speed and reliability.
"""
from enum import Enum
from typing import Any, Dict, List, Optional, Type, Union, Literal
from pydantic import BaseModel, Field
from loguru import logger
from app.tools.base import BaseTool, ToolResult
from app.services.supabase_service import supabase_service

# ══════════════════════════════════════════════════════════════════════
# UI COMPONENT SCHEMAS (Migrated from BAML Client)
# ══════════════════════════════════════════════════════════════════════

class ChartVisualizationType(str, Enum):
    BAR = "BAR"
    LINE = "LINE"
    PIE = "PIE"
    AREA = "AREA"
    RADIAL = "RADIAL"
    SPARKLINE = "SPARKLINE"
    STAT_CARD = "STAT_CARD"
    PROGRESS = "PROGRESS"
    HEATMAP = "HEATMAP"

class ChartConfig(BaseModel):
    type: ChartVisualizationType = Field(description='Preferred visualization type.')
    x_axis_label: Optional[str] = Field(default=None, description='Label for X-axis')
    y_axis_label: Optional[str] = Field(default=None, description='Label for Y-axis')
    show_legend: Optional[bool] = Field(default=None, description='Whether to show the legend.')

class ChartDataPoint(BaseModel):
    x: str = Field(description='The X-axis value (date or category)')
    y: float = Field(description='The Y-axis value')

class ChartSeries(BaseModel):
    label: Optional[str] = Field(default=None, description='Name for the Legend')
    data: List[ChartDataPoint] = Field(description='Data points for this series')

class ChartData(BaseModel):
    title: Optional[str] = Field(default=None, description='Chart title')
    config: ChartConfig = Field(description='Visualization config')
    series: List[ChartSeries] = Field(description='Data series to plot')

class GoalProgressItem(BaseModel):
    goal_title: str
    progress_pct: float = Field(description='0.0 to 1.0')
    status: str = Field(description='on_track, behind, at_risk')

class InsightData(BaseModel):
    tasks_done: int
    tasks_overdue: int
    tasks_on_track: int
    goal_progress: List[GoalProgressItem]
    warnings: List[str]

class Milestone(BaseModel):
    title: str = Field(description="Short title for the phase/milestone")
    tasks: List[str] = Field(description="Specific task names to be created for this phase")

class BreakdownData(BaseModel):
    goal_title: str = Field(description="The overarching goal name")
    milestones: List[Milestone] = Field(description="Phased approach to achieving the goal")

# ══════════════════════════════════════════════════════════════════════
# INPUT SCHEMAS
# ══════════════════════════════════════════════════════════════════════

class CreateGoalInput(BaseModel):
    title: str = Field(description="The clear and concise title of the goal.")
    current_state: Optional[str] = Field(None, description="Detailed explanation/description.")
    target_date: Optional[str] = Field(None, description="Deadline in ISO format (YYYY-MM-DD).")

class UpdateGoalInput(BaseModel):
    goal_id: str = Field(description="The unique ID of the goal to update.")
    title: Optional[str] = Field(None, description="New title for the goal.")
    current_state: Optional[str] = Field(None, description="New description.")
    status: Optional[str] = Field(None, description="New status: 'active' or 'completed'.")

class CreateTaskInput(BaseModel):
    title: str = Field(description="The task name.")
    goal_id: Optional[str] = Field(None, description="Linked goal ID.")
    due_date: Optional[str] = Field(None, description="Optional due date.")

# ══════════════════════════════════════════════════════════════════════
# SERVER SIDE TOOL DEFINITIONS
# ══════════════════════════════════════════════════════════════════════

class ServerSideTool(BaseTool):
    """Base class for tools that execute directly on Supabase via the backend."""
    def __init__(self, user_id: str):
        self.user_id = user_id

class CreateGoalServerTool(ServerSideTool):
    name = "create_goal"
    description = "Create a new major goal directly in the database."
    args_schema = CreateGoalInput

    async def arun(self, **kwargs: Any) -> ToolResult:
        try:
            # Note: The DB uses 'current_state' instead of 'description' based on migration research
            data = {
                "title": kwargs.get("title"),
                "current_state": kwargs.get("current_state"),
                "status": "active"
            }
            if kwargs.get("target_date"):
                data["end_date"] = kwargs.get("target_date")
                
            result = await supabase_service.create_goal(self.user_id, data)
            return ToolResult(success=True, data=result)
        except Exception as e:
            return ToolResult(success=False, error=str(e))

class ListGoalsServerTool(ServerSideTool):
    name = "list_goals"
    description = "List all existing goals for the user."
    
    async def arun(self, **kwargs: Any) -> ToolResult:
        try:
            status = kwargs.get("status", "active")
            result = await supabase_service.list_goals(self.user_id, status)
            return ToolResult(success=True, data=result)
        except Exception as e:
            return ToolResult(success=False, error=str(e))

class CreateTaskServerTool(ServerSideTool):
    name = "create_task"
    description = "Create a new task linked to a goal."
    args_schema = CreateTaskInput

    async def arun(self, **kwargs: Any) -> ToolResult:
        try:
            data = {
                "title": kwargs.get("title"),
                "goal_id": kwargs.get("goal_id"),
                "due_date": kwargs.get("due_date"),
                "status": "todo"
            }
            result = await supabase_service.create_task(self.user_id, data)
            return ToolResult(success=True, data=result)
        except Exception as e:
            return ToolResult(success=False, error=str(e))

class ListTasksServerTool(ServerSideTool):
    name = "list_tasks"
    description = "List tasks for a specific goal or user."

    async def arun(self, **kwargs: Any) -> ToolResult:
        try:
            goal_id = kwargs.get("goal_id")
            result = await supabase_service.list_tasks(self.user_id, goal_id)
            return ToolResult(success=True, data=result)
        except Exception as e:
            return ToolResult(success=False, error=str(e))

class UpdateGoalServerTool(ServerSideTool):
    name = "update_goal"
    description = "Update an existing goal's title, description, or status."
    args_schema = UpdateGoalInput

    async def arun(self, **kwargs: Any) -> ToolResult:
        try:
            goal_id = kwargs.get("goal_id")
            # Filter out None values to only update provided fields
            update_data = {k: v for k, v in kwargs.items() if k != "goal_id" and v is not None}
            result = await supabase_service.update_goal(self.user_id, goal_id, update_data)
            return ToolResult(success=True, data=result)
        except Exception as e:
            return ToolResult(success=False, error=str(e))

class DeleteGoalServerTool(ServerSideTool):
    name = "delete_goal"
    description = "Remove a goal and its associated tasks permanently."
    
    async def arun(self, **kwargs: Any) -> ToolResult:
        try:
            goal_id = kwargs.get("goal_id")
            success = await supabase_service.delete_goal(self.user_id, goal_id)
            return ToolResult(success=success, data={"deleted": success})
        except Exception as e:
            return ToolResult(success=False, error=str(e))

class UpdateTaskServerTool(ServerSideTool):
    name = "update_task"
    description = "Update a task's title, status (todo/completed), or due date."

    async def arun(self, **kwargs: Any) -> ToolResult:
        try:
            task_id = kwargs.get("task_id")
            update_data = {k: v for k, v in kwargs.items() if k != "task_id" and v is not None}
            
            # Map 'done' or 'completed' to proper status if needed
            if "status" in update_data and update_data["status"] in ["done", "completed"]:
                update_data["status"] = "completed"
                update_data["is_completed"] = True
            
            result = await supabase_service.update_task(self.user_id, task_id, update_data)
            return ToolResult(success=True, data=result)
        except Exception as e:
            return ToolResult(success=False, error=str(e))

class DeleteTaskServerTool(ServerSideTool):
    name = "delete_task"
    description = "Remove a specific task."

    async def arun(self, **kwargs: Any) -> ToolResult:
        try:
            task_id = kwargs.get("task_id")
            success = await supabase_service.delete_task(self.user_id, task_id)
            return ToolResult(success=success, data={"deleted": success})
        except Exception as e:
            return ToolResult(success=False, error=str(e))

class GetUserContextServerTool(ServerSideTool):
    name = "get_user_context"
    description = "Get a summary of the user's active goals and pending tasks."

    async def arun(self, **kwargs: Any) -> ToolResult:
        try:
            goals = await supabase_service.list_goals(self.user_id, "active")
            tasks = await supabase_service.list_tasks(self.user_id)
            
            pending_tasks = [t for t in tasks if t.get("status") != "completed"]
            
            summary = (
                f"User has {len(goals)} active goals and {len(pending_tasks)} pending tasks. "
                f"Goals: {', '.join([g['title'] for g in goals])}"
            )
            return ToolResult(success=True, data={"summary": summary, "goals_count": len(goals), "tasks_count": len(pending_tasks)})
        except Exception as e:
            return ToolResult(success=False, error=str(e))

class GetAnalyticsSummaryServerTool(ServerSideTool):
    name = "get_analytics_summary"
    description = "Get a statistical summary of goals and tasks for analysis and review."

    async def arun(self, **kwargs: Any) -> ToolResult:
        try:
            result = await supabase_service.get_analytics_data(self.user_id)
            return ToolResult(success=True, data=result)
        except Exception as e:
            return ToolResult(success=False, error=str(e))

class ProductivityTrendInput(BaseModel):
    days: int = Field(default=14, description="Number of days to look back (default 14)")

class GetProductivityTrendTool(ServerSideTool):
    name = "get_productivity_trend"
    description = "Fetch daily completion counts to visualize progress trends over time."
    args_schema = ProductivityTrendInput

    async def arun(self, **kwargs: Any) -> ToolResult:
        try:
            days = kwargs.get("days", 14)
            result = await supabase_service.get_productivity_trend(self.user_id, days)
            return ToolResult(success=True, data=result)
        except Exception as e:
            return ToolResult(success=False, error=str(e))

class GoalHealthInput(BaseModel):
    goal_id: str = Field(description="The ID of the goal to analyze")

class GetGoalHealthTool(ServerSideTool):
    name = "get_goal_health"
    description = "Get a deep dive into a specific goal's status, including overdue tasks and completion percentage."
    args_schema = GoalHealthInput

    async def arun(self, **kwargs: Any) -> ToolResult:
        try:
            goal_id = kwargs.get("goal_id")
            result = await supabase_service.get_goal_health_metrics(self.user_id, goal_id)
            return ToolResult(success=True, data=result)
        except Exception as e:
            return ToolResult(success=False, error=str(e))

class ShowActionCardInput(BaseModel):
    type: Literal["BREAKDOWN", "CHART", "INSIGHT", "GENERIC"] = Field(
        description="The type of card to show."
    )
    data: Union[BreakdownData, ChartData, InsightData, Dict[str, Any]] = Field(
        description="Data payload for the card. Use BreakdownData for 'BREAKDOWN', ChartData for 'CHART', and InsightData for 'INSIGHT'."
    )

class ShowActionCardServerTool(ServerSideTool):
    name = "show_action_card"
    description = (
        "MANDATORY: Use this tool to display a specialized UI card to the user. "
        "For any new goal proposal, you MUST call this tool with type='BREAKDOWN' "
        "to show the strategic plan before asking for approval. "
        "Also supports 'CHART' for data visualization."
    )
    args_schema = ShowActionCardInput

    async def arun(self, **kwargs: Any) -> ToolResult:
        # This tool doesn't perform DB actions; its result is intercepted by the workflow stream
        # to emit an 'object' fragment to the frontend.
        card_type = kwargs.get("type", "GENERIC").upper()
        card_data = kwargs.get("data", {})
        
        # Robustness: If card_data is a string (due to LLM stringifying JSON), parse it.
        if isinstance(card_data, str) and card_data.strip():
            try:
                import json
                card_data = json.loads(card_data)
                logger.info(f"🧩 Coerced stringified JSON input for {card_type} into dict.")
            except Exception as e:
                logger.warning(f"⚠️ Failed to parse card_data string: {str(e)}")
        
        return ToolResult(
            success=True, 
            data={
                "ui_component": card_type,
                "data": card_data
            }
        )

# Factory function
def create_all_server_tools(user_id: str) -> Dict[str, BaseTool]:
    tools = [
        GetUserContextServerTool(user_id),
        GetAnalyticsSummaryServerTool(user_id),
        GetProductivityTrendTool(user_id),
        GetGoalHealthTool(user_id),
        CreateGoalServerTool(user_id),
        ListGoalsServerTool(user_id),
        UpdateGoalServerTool(user_id),
        DeleteGoalServerTool(user_id),
        CreateTaskServerTool(user_id),
        ListTasksServerTool(user_id),
        UpdateTaskServerTool(user_id),
        DeleteTaskServerTool(user_id),
        ShowActionCardServerTool(user_id),
    ]
    return {t.name: t for t in tools}
