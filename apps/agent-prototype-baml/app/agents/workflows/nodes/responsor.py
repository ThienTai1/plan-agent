import json
from loguru import logger
from langchain_core.runnables import RunnableConfig
from baml_client.async_client import b as async_b
from app.services.context_engine import build_context, to_baml_messages

async def responsor_node(state: dict, config: RunnableConfig) -> dict:
    if state.get("final_answer") and not state.get("blueprint"):
        return {}
    
    collector = config.get("configurable", {}).get("collector")
    context, processed_msgs = await build_context(
        user_info=state.get("user_info"),
        include_db_state=False,
        messages=state.get("messages", []),
        previous_tool_results=state.get("previous_tool_results", [])
    )
    baml_msgs = to_baml_messages(processed_msgs)

    plan_obj = state.get("plan")
    plan_str = None
    if plan_obj:
        try:
            plan_str = plan_obj.model_dump_json(indent=2)
        except Exception:
            plan_str = str(plan_obj)

    tool_hist = state.get("tool_history")
    tool_hist_str = None
    if tool_hist:
        try:
            tool_hist_str = json.dumps(tool_hist, ensure_ascii=False, indent=2)
        except Exception:
            tool_hist_str = str(tool_hist)

    logger.info("DEBUG [responsor]: Summarizing final workflow result...")
    response = await async_b.Responsor(
        query=state.get("query", "No query"),
        context=context,
        plan=plan_str,
        tool_history=tool_hist_str,
        validator_reasoning=state.get("validator_reasoning"),
        messages=baml_msgs,
        baml_options={"collector": collector} if collector else {},
    )
    
    response_dict = response.model_dump() if hasattr(response, "model_dump") else response
    return {"final_answer": response_dict}
