from loguru import logger
from langchain_core.runnables import RunnableConfig
from baml_client.async_client import b as async_b
from app.services.context_engine import build_context, to_baml_messages

DEPARTMENT_TOOLS = {
    "MANAGEMENT": [
        "search_tasks", "update_task", "create_task", "delete_task", 
        "search_events", "create_event", "update_event", "delete_event",
        "search_goals", "create_goal",
        "search_projects", "create_project", "update_project", "delete_project"
    ],
    "ANALYTICS": ["search_tasks", "search_events", "search_goals"]
}

async def planner_node(
    state: dict,
    config: RunnableConfig,
) -> dict:
    collector = config.get("configurable", {}).get("collector")

    context, processed_msgs = await build_context(
        user_info=state.get("user_info"),
        include_db_state=False,
        messages=state.get("messages", []),
        previous_tool_results=state.get("previous_tool_results", [])
    )
    baml_msgs = to_baml_messages(processed_msgs)
    
    blueprint = state.get("blueprint")
    if not blueprint:
        return {"error": "No blueprint found in state!"}
    
    stages = state.get("stages", [])
    if stages and stages[0].get("departments"):
        current_dept = " AND ".join(stages[0]["departments"])
    else:
        current_dept = "UNKNOWN"

    allowed_tools_set = set()
    if stages and stages[0].get("departments"):
        logger.info(f"DEBUG [planner]: Found departments info in stage: {stages[0]['departments']}")
        for dept in stages[0]["departments"]:
            # Normalize to uppercase and handle BAML-style enum strings (e.g., 'Department.MANAGEMENT')
            dept_str = str(dept)
            dept_normalized = dept_str.split(".")[-1].upper()
            dept_tools = DEPARTMENT_TOOLS.get(dept_normalized, [])
            if not dept_tools:
                logger.warning(f"WARNING [planner]: No tools found for department: {dept} (normalized: {dept_normalized})")
            allowed_tools_set.update(dept_tools)
    else:
        logger.warning("WARNING [planner]: No stages or departments found in state. Defaulting to search_tasks.")
    
    allowed_tools_list = list(allowed_tools_set) if allowed_tools_set else ["search_tasks"]
    logger.info(f"DEBUG [planner]: Allowed tools for this turn: {allowed_tools_list}")

    res = await async_b.Planner(
        input={
            "context": context,
            "specialist_name": current_dept,
            "blueprint": blueprint,
            "tool_results": state.get("tool_history", []),
            "allowed_tools": allowed_tools_list,
        },
        baml_options={"collector": collector} if collector else {},
    )
    logger.info(f"Planner response: {res}")
    
    return {
        "plan": res,
        "current_step": res.steps[0].step if res.steps else None,
        "tool_history": [],
        "allowed_tools": allowed_tools_list,
        "retry_count": 0,
        "replan_count": 0,
    }
