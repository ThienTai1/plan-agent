"""
Context Engine — Assembles rich, layered context for every LLM call.

Layers:
1. System  — timestamp, timezone, persona rules
2. User    — profile, preferences (if user_id provided)
4. Tool Results — formatted output from previous CRUD/search operations
5. Memory  — compressed conversation summary for long histories
"""

from datetime import datetime, timezone

from baml_client.types import Messages

from app.models.requests import ChatMessage


# ── Configuration ───────────────────────────────────────────────

# Max recent messages to keep in full before compressing older ones
MAX_RECENT_MESSAGES = 10

# System persona
SYSTEM_PERSONA = "Levigo, a smart AI Assistant for project/task management. Friendly and concise."


# ── Conversion Helpers ──────────────────────────────────────────


def to_baml_messages(messages: list[dict | ChatMessage]) -> list[Messages]:
    """Convert API ChatMessage list to BAML Messages list."""
    res = []
    for m in messages:
        if isinstance(m, dict):
            res.append(Messages(role=m["role"], content=m["content"]))
        else:
            res.append(Messages(role=m.role, content=m.content))
    return res


# ── Layer Builders ──────────────────────────────────────────────


def _build_system_layer() -> str:
    """Layer 1: System — timestamp + persona."""
    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
    return f"""[SYSTEM]
current_time: {now}
persona: {SYSTEM_PERSONA}"""


def _build_user_layer(user_info: str | None = None) -> str:
    """Layer 2: User — profile and preferences (hiding user_id for privacy/context size)."""
    if not user_info:
        return ""

    return f"[USER STATE]\nuser_info: {user_info}"






async def _build_memory_layer(
    messages: list[ChatMessage],
) -> tuple[str, list[ChatMessage]]:
    """
    Layer 5: Memory — compress old messages if history is long.

    Returns:
        (summary_context, trimmed_messages)
        - summary_context: text summary of older messages (or empty)
        - trimmed_messages: recent messages to keep in full
    """
    if len(messages) <= MAX_RECENT_MESSAGES:
        return "", messages

    # Split: older messages → summarize, recent → keep
    recent = messages[-MAX_RECENT_MESSAGES:]

    # For now, just trim without summary to prevent BAML timeout in loops
    return "", recent


# ── Main Context Assembly ───────────────────────────────────────


async def build_context(
    *,
    user_info: str | None = None,
    include_db_state: bool = True,
    messages: list[ChatMessage] | None = None,
    previous_tool_results: list[str] | None = None,
) -> tuple[str, list[ChatMessage]]:
    """
    Assemble all context layers into a single string.

    Returns:
        (context_string, processed_messages)
        - context_string: rich context for BAML function `context` param
        - processed_messages: trimmed/compressed message list
    """
    processed_messages = messages or []

    # Build all layers
    layers = []

    # Layer 1: System (always)
    layers.append(_build_system_layer())

    # Layer 2: User (if available)
    user_layer = _build_user_layer(user_info=user_info)
    if user_layer:
        layers.append(user_layer)

    # Layer 4: Previous Tool Results (Short-term memory)
    if previous_tool_results:
        summary = "[PREVIOUS OPERATION RESULTS]\nThe agent fetched this data in the previous turn. Use it to answer follow-up queries without re-running tools:\n"
        summary += "\n\n".join(previous_tool_results)
        layers.append(summary)



    # Layer 5: Memory compression (if messages are long)
    if processed_messages:
        memory_layer, processed_messages = await _build_memory_layer(processed_messages)
        if memory_layer:
            layers.append(memory_layer)

    context_string = "\n".join(layers)
    return context_string, processed_messages


def format_tool_results(action: str, entity_type: str, data: dict | list | str) -> str:
    """
    Format tool execution results for context injection.

    Examples:
        format_tool_results("created", "task", {"title": "Buy groceries", "due_date": "2026-02-26"})
        format_tool_results("search", "tasks", [{"title": "Buy milk"}, {"title": "Buy eggs"}])
    """
    if isinstance(data, dict):
        details = ", ".join(f"{k}: {v}" for k, v in data.items() if v is not None)
        return f"Action: {action} {entity_type}\nResult: {details}"
    elif isinstance(data, list):
        lines = [f"Action: {action} {entity_type} ({len(data)} results)"]
        for item in data[:10]:  # Cap at 10
            if isinstance(item, dict):
                summary = ", ".join(
                    f"{k}: {v}" for k, v in item.items() if v is not None
                )
                lines.append(f"  - {summary}")
            else:
                lines.append(f"  - {item}")
        return "\n".join(lines)
    else:
        return f"Action: {action} {entity_type}\nResult: {data}"
