from loguru import logger
from langchain_core.runnables import RunnableConfig
from baml_client.async_client import b as async_b
from baml_client.type_builder import TypeBuilder
from app.services.context_engine import build_context, format_tool_results
from app.services import schema_service
from app.agents.tools.registry import tool_registry

async def executor_node(state: dict, config: RunnableConfig) -> dict:
    """Node 2 (Execution): Select tool for the current step."""
    if not state.get("plan") or not state.get("current_step"):
        stages = list(state.get("stages", []))
        if stages:
            deps = stages[0].get("departments", [])
            if deps:
                deps.pop(0)
            if not deps:
                stages.pop(0)
        return {
            "tool_name": "chat_response",
            "response": "No plan found or already finished.",
            "stages": stages,
        }

    tb = TypeBuilder()
    await schema_service.sync_type_builder(tb)
    collector = config.get("configurable", {}).get("collector")
    baml_opts = {"tb": tb}
    if collector:
        baml_opts["collector"] = collector

    context, _ = await build_context(
        user_info=state.get("user_info"),
        include_db_state=True,
        messages=state.get("messages", []),
        previous_tool_results=state.get("previous_tool_results", [])
    )

    allowed_tools_list = state.get("allowed_tools")
    if not allowed_tools_list:
        allowed_tools_list = tool_registry.get_tool_names()

    plan = state["plan"]
    current_step_idx = state["current_step"]
    
    step_description = "Unknown Step"
    if plan and plan.steps:
        for s in plan.steps:
            if str(s.step) == str(current_step_idx):
                step_description = s.description
                break

    res = await async_b.Executor(
        input={
            "context": context,
            "step_description": step_description,
            "allowed_tools": allowed_tools_list,
        },
        baml_options=baml_opts,
    )

    reasoning = res.thought or ""
    tool_name = "chat_response"
    tool_data = None

    if res.tool_call:
        model_dict = res.tool_call.model_dump(exclude_none=True)
        if model_dict:
            tool_name = list(model_dict.keys())[0]
            tool_data = model_dict[tool_name]
            logger.info(f"DEBUG [exec]: Step '{state['current_step']}' -> Reasoning: {reasoning} | Tool '{tool_name}'")
    else:
        logger.info(f"DEBUG [exec]: No tool call for step '{state['current_step']}'. Reasoning: {reasoning}")

    stages = list(state.get("stages", []))
    if tool_name == "chat_response":
        if stages:
            deps = stages[0].get("departments", [])
            if deps:
                deps.pop(0)
            if not deps:
                stages.pop(0)

    return {
        "reasoning": reasoning,
        "tool_name": tool_name,
        "tool_data": tool_data,
        "stages": stages,
    }

async def execute_tool_node(state: dict, config: RunnableConfig) -> dict:
    tool_name = state.get("tool_name")
    if not tool_name:
        return {"tool_result": "No tool"}

    data = state.get("tool_data", {})

    if tool_name == "chat_response":
        return {}

    tool_def = tool_registry.get_tool(tool_name)
    if not tool_def:
        tool_result = f"Error: No tool registered for '{tool_name}'"
        tool_history = list(state.get("tool_history", []))
        tool_history.append({"tool_name": tool_name, "tool_input": [data], "tool_output": tool_result})
        return {"tool_history": tool_history}

    try:
        logger.info(f"DEBUG [execute_tool]: Executing tool '{tool_name}' with data: {data}")
        # Inject user_id from context/session (mocked for now as "current_user")
        data["user_id"] = state.get("user_id")
        result = await tool_def.func(**data)

        if isinstance(result, list):
            formatted_list = [r.model_dump() if hasattr(r, "model_dump") else r for r in result]
            tool_result = format_tool_results(
                "search",
                tool_name.split("_", 1)[1] if "_" in tool_name else "items",
                formatted_list,
            )
        elif hasattr(result, "model_dump"):
            action_type = "updated" if tool_name.startswith("update") else "deleted" if tool_name.startswith("delete") else "created"
            entity_type = tool_name.split("_", 1)[1] if "_" in tool_name else "item"
            tool_result = format_tool_results(action_type, entity_type, result.model_dump())
        elif isinstance(result, bool) and tool_name.startswith("delete"):
            tool_result = "Deleted successfully." if result else "Not found or failed to delete."
        else:
            tool_result = str(result)
    except Exception as e:
        logger.error(f"ERROR executing tool {tool_name}: {e}")
        tool_result = f"Tool Error: {str(e)}"

    new_messages = list(state.get("messages", []))

    # Note: build_context call might need adjustment if it modifies state
    # but here it's used for processed_msgs (ignored mostly)

    tool_history = list(state.get("tool_history", []))
    stringified_data = {str(k): str(v) for k, v in data.items()}
    tool_history.append({
        "tool_name": tool_name,
        "tool_input": [stringified_data],
        "tool_output": tool_result
    })

    return {
        "tool_history": tool_history,
        "messages": new_messages,
    }
