"""
Utility functions for the backend.
"""

from typing import Dict, Any, List, Optional
from datetime import datetime, timedelta
import re
import json
from loguru import logger


def extract_agent_action(text: str) -> Optional[Dict[str, Any]]:
    """
    Extract action from agent response text.
    Looks for patterns like <ACTION: tool_name | params></ACTION>
    """
    pattern = r'<ACTION:\s*(\w+)\s*\|\s*({.*?})\s*</ACTION>'
    matches = re.findall(pattern, text)

    if matches:
        tool_name, params_str = matches[0]
        try:
            params = json.loads(params_str)
            return {"tool": tool_name, "params": params}
        except json.JSONDecodeError:
            logger.warning(f"Failed to parse action params: {params_str}")
            return None

    return None


def format_message(role: str, content: str) -> Dict[str, str]:
    """Format a message to standard structure"""
    return {"role": role, "content": content}


def merge_messages(messages1: List[Dict], messages2: List[Dict]) -> List[Dict]:
    """Merge two message lists"""
    return messages1 + messages2


def get_current_time_str() -> str:
    """Get current time in ISO format"""
    return datetime.now().isoformat()


def get_date_range(
    start_days_ago: int = 0, end_days_ahead: int = 7
) -> tuple[str, str]:
    """
    Get a date range for queries.
    
    Args:
        start_days_ago: How many days in the past to start from
        end_days_ahead: How many days in the future to end at
    
    Returns:
        Tuple of (start_date_iso, end_date_iso)
    """
    start = datetime.now() - timedelta(days=start_days_ago)
    end = datetime.now() + timedelta(days=end_days_ahead)
    return start.isoformat(), end.isoformat()


def extract_json_from_text(text: str) -> Optional[Dict]:
    """
    Extract JSON object from text.
    Handles JSON embedded in natural language.
    """
    # Try to find JSON object
    json_pattern = r'\{(?:[^{}]|(?:\{[^{}]*\}))*\}'
    match = re.search(json_pattern, text)

    if match:
        try:
            return json.loads(match.group())
        except json.JSONDecodeError:
            pass

    return None


def sanitize_tool_params(params: Dict[str, Any]) -> Dict[str, Any]:
    """
    Sanitize tool parameters.
    Remove None values and invalid keys.
    """
    return {k: v for k, v in params.items() if v is not None}


def format_tool_result(
    success: bool, data: Optional[Any] = None, error: Optional[str] = None
) -> Dict[str, Any]:
    """Format tool execution result"""
    result = {"success": success}

    if data is not None:
        result["data"] = data

    if error is not None:
        result["error"] = error

    return result


def estimate_token_count(text: str) -> int:
    """
    Rough estimate of token count.
    Typically 1 token ≈ 4 characters
    """
    return len(text) // 4


def truncate_text(text: str, max_tokens: int = 500, max_chars: int = 2000) -> str:
    """
    Truncate text to max tokens or characters.
    """
    if len(text) > max_chars:
        text = text[:max_chars] + "..."

    if estimate_token_count(text) > max_tokens:
        # Rough truncation
        text = text[: max_tokens * 4] + "..."

    return text


def create_tool_summary(tools: List[str]) -> str:
    """Create a summary description of available tools"""
    tool_list = ", ".join(tools)
    return f"Available tools: {tool_list}"


def parse_priority(priority: Optional[str]) -> str:
    """
    Parse and normalize priority level.
    """
    if not priority:
        return "medium"

    priority = priority.lower().strip()

    if priority in ["critical", "urgent", "high", "important"]:
        return "high"
    elif priority in ["medium", "normal", "standard"]:
        return "medium"
    elif priority in ["low", "minor", "optional"]:
        return "low"

    return "medium"


def parse_status(status: Optional[str]) -> str:
    """
    Parse and normalize status.
    """
    if not status:
        return "pending"

    status = status.lower().strip()

    if status in ["done", "completed", "finished", "closed"]:
        return "completed"
    elif status in ["doing", "in_progress", "in progress", "active"]:
        return "in_progress"
    elif status in ["pending", "todo", "open", "new"]:
        return "pending"

    return "pending"


def should_route_to_analytics(query: str) -> bool:
    """
    Determine if query should route to analytics agent.
    """
    analytics_keywords = [
        "progress",
        "analytics",
        "statistics",
        "trend",
        "how much",
        "how many",
        "performance",
        "insights",
        "chart",
        "graph",
        "data",
        "analysis",
    ]

    query_lower = query.lower()
    return any(keyword in query_lower for keyword in analytics_keywords)


def should_route_to_calendar(query: str) -> bool:
    """
    Determine if query should route to calendar agent.
    """
    calendar_keywords = [
        "calendar",
        "event",
        "meeting",
        "schedule",
        "when",
        "time",
        "date",
        "appointment",
        "block time",
        "reserve",
    ]

    query_lower = query.lower()
    return any(keyword in query_lower for keyword in calendar_keywords)


def should_route_to_tasks(query: str) -> bool:
    """
    Determine if query should route to task planning agent.
    """
    task_keywords = [
        "goal",
        "task",
        "project",
        "deadline",
        "plan",
        "organize",
        "create",
        "schedule",
        "break down",
        "milestone",
    ]

    query_lower = query.lower()
    return any(keyword in query_lower for keyword in task_keywords)


class MessageBuffer:
    """
    Buffer for managing conversation messages.
    """

    def __init__(self, max_messages: int = 50):
        self.max_messages = max_messages
        self.messages: List[Dict[str, str]] = []

    def add_message(self, role: str, content: str):
        """Add message to buffer"""
        self.messages.append({"role": role, "content": content})

        # Trim oldest messages if exceeded max
        if len(self.messages) > self.max_messages:
            self.messages = self.messages[-self.max_messages :]

    def get_messages(self) -> List[Dict[str, str]]:
        """Get all messages"""
        return self.messages

    def get_last_n(self, n: int) -> List[Dict[str, str]]:
        """Get last N messages"""
        return self.messages[-n:] if self.messages else []

    def get_context_summary(self) -> str:
        """Get a summary of recent messages for context"""
        if not self.messages:
            return "No conversation history"

        recent = self.get_last_n(5)
        summary_parts = []

        for msg in recent:
            content = msg["content"][:50]  # Truncate
            summary_parts.append(f"{msg['role']}: {content}...")

        return "\n".join(summary_parts)

    def clear(self):
        """Clear all messages"""
        self.messages = []
