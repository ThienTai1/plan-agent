from loguru import logger
from langchain_core.runnables import RunnableConfig
from baml_client.async_client import b as async_b
from app.services.context_engine import build_context, to_baml_messages

async def supervisor_node(state: dict, config: RunnableConfig) -> dict:
    """Node 0: Supervisor - Analyze intent and route to specific departments."""
    collector = config.get("configurable", {}).get("collector")

    context, processed_msgs = await build_context(
        user_info=state.get("user_info"),
        include_db_state=False,  # Supervisor doesn't need DB state
        messages=state.get("messages", []),
        previous_tool_results=state.get("previous_tool_results", [])
    )
    baml_msgs = to_baml_messages(processed_msgs)

    baml_opts = {}
    if collector:
        baml_opts["collector"] = collector

    res = await async_b.Orchestrator(
        query=state["query"],
        context=context,
        messages=baml_msgs,
        baml_options=baml_opts,
    )

    logger.info(f"Orchestrator response: {res}")

    processed_stages = []
    if res.stages:
        # Sort stages by order to ensure sequential execution
        sorted_stages = sorted(res.stages, key=lambda s: s.order)
        for stage in sorted_stages:
            dept_strs = []
            if hasattr(stage, "departments") and stage.departments:
                for d in stage.departments:
                    dept_str = d.name if hasattr(d, "name") else str(d)
                    dept_strs.append(dept_str)
            
            processed_stages.append({
                "order": stage.order,
                "departments": dept_strs
            })
        logger.info(f"Processed stages: {processed_stages}")

    if not processed_stages or (len(processed_stages) == 1 and "CHAT" in processed_stages[0]["departments"]):
        reply = res.chat_response
        if not reply:
            reply = await async_b.Responsor(
                query=state["query"],
                context=context,
                plan=None,
                tool_history=None,
                validator_reasoning=None,
                messages=baml_msgs,
                baml_options=baml_opts,
            )
        logger.debug(f"DEBUG [supervisor]: Chat-only intent -> {reply}")
        
        reply_dict = reply.model_dump() if hasattr(reply, "model_dump") else reply
        return {"stages": [], "response": reply_dict, "blueprints": [], "advices": []}

    logger.debug(f"DEBUG [supervisor]: Action intent detected -> Plan: {processed_stages}")
    return {"stages": processed_stages, "iterations": state.get("iterations", 0), "blueprints": [], "advices": []}
