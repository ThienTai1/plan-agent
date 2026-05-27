from loguru import logger
from langchain_core.runnables import RunnableConfig
from baml_client.async_client import b as async_b
from app.services.context_engine import build_context

async def validator_node(state: dict, config: RunnableConfig) -> dict:
    collector = config.get("configurable", {}).get("collector")
    baml_opts = {"collector": collector} if collector else {}

    context, _ = await build_context(
        include_db_state=True,
        messages=state.get("messages", []),
        previous_tool_results=state.get("previous_tool_results", [])
    )

    res = await async_b.Validator(
        input={
            "context": context,
            "plan": state["plan"],
            "current_step": int(state.get("current_step", 1)),
            "tool_results": state.get("tool_history", []),
        },
        baml_options=baml_opts,
    )

    decision = res.decision
    reasoning = res.reasoning
    logger.info(f"DEBUG [validator]: Decision -> {decision}, Reasoning -> {reasoning}")

    current_retries = state.get("retry_count", 0) or 0
    current_replans = state.get("replan_count", 0) or 0

    if decision == "RETRY":
        current_retries += 1
    elif decision == "REPLAN":
        current_replans += 1
        current_retries = 0
    elif decision == "PASS":
        current_retries = 0

    plan = state["plan"]
    new_steps = []
    next_step = None
    found_current = False

    steps = plan.steps or []
    for s in steps:
        if str(s.step) == str(state["current_step"]):
            found_current = True
        elif found_current and next_step is None:
            next_step = s.step
        new_steps.append(s)

    plan.steps = new_steps if plan.steps is not None else None

    stages = list(state.get("stages", []))
    is_terminal = decision in ["AMBIGUOUS", "FAIL"]
    
    if decision == "PASS" and next_step is None:
        is_terminal = True

    if (is_terminal or next_step is None) and stages:
        deps = stages[0].get("departments", [])
        if deps:
            deps.pop(0)
        if not deps:
            if stages:
                stages.pop(0)

    return {
        "validator_decision": decision,
        "validator_reasoning": reasoning,
        "plan": plan,
        "current_step": next_step if decision == "PASS" else (None if is_terminal else state["current_step"]),
        "iterations": state.get("iterations", 0) + 1,
        "retry_count": current_retries,
        "replan_count": current_replans,
        "stages": stages,
    }
