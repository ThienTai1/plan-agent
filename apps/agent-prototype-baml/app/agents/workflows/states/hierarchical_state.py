from typing import List, Dict, Any, Optional, TypedDict
from baml_client.types import Blueprint, Step, ValidationDecision


class PendingAction(TypedDict):
    """Represents a pending tool execution action."""
    type: str
    display: str
    data: Dict[str, Any]


class HierarchicalState(TypedDict):
    """State for the Hierarchical Agent Workflow.
    
    This TypedDict defines the complete schema for data flowing
    through the LangGraph hierarchical agent pipeline.
    """
    
    # Core input
    user_id: str
    user_message: str
    current_time: str
    history: List[Dict[str, str]]

    # Internal message log (includes [THOUGHT] and [OBSERVATION] tags)
    messages: List[Dict[str, str]]

    # Department routing
    pending_departments: List[str]
    current_department: Optional[str]

    # Specialist output
    blueprint: Optional[Blueprint]
    allowed_tools: List[str]

    # Planner output
    plan: List[Step]
    current_step_index: int

    # Executor output
    pending_action: Optional[PendingAction]
    last_execution_result: Optional[str]

    # Validator output
    validation_decision: Optional[ValidationDecision]

    # Final response
    final_answer: Optional[str]

    # Metadata
    is_pro: bool
    step_count: int
    max_steps: int


def create_initial_state(
    user_message: str,
    user_id: str,
    current_time: str,
    is_pro: bool = False,
    history: List[Dict[str, str]] | None = None,
    max_steps: int = 10,
) -> HierarchicalState:
    """Factory function to create a properly typed initial state.
    
    Args:
        user_message: The user's query.
        user_id: The authenticated user's ID.
        current_time: ISO-formatted current timestamp.
        history: Optional chat history (list of {role, content} dicts).
        max_steps: Maximum execution steps before stopping.
        
    Returns:
        A fully initialized HierarchicalState with all fields set.
    """
    return HierarchicalState(
        user_id=user_id,
        user_message=user_message,
        current_time=current_time,
        history=history or [],
        messages=[],
        pending_departments=[],
        current_department=None,
        blueprint=None,
        allowed_tools=[],
        plan=[],
        current_step_index=0,
        pending_action=None,
        last_execution_result=None,
        validation_decision=None,
        final_answer=None,
        is_pro=is_pro,
        step_count=0,
        max_steps=max_steps,
    )
