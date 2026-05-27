"""
STATE.PY - Memory Structure (Memory Schema).
This file defines the data fields that the LangGraph "Brain" will store:
Message lists, user_id, session_id, and pending status.
"""
import operator
from typing import TypedDict, List, Dict, Any, Annotated, Optional
from pydantic import BaseModel, Field

class HierarchicalState(TypedDict):
    """
    Main state for the agent orchestration.
    """
    # Chat history
    messages: Annotated[List[Dict[str, Any]], operator.add]
    
    # Context
    session_id: str
    user_id: str
    current_time: str
    
    # Orchestration control
    pending_departments: Annotated[List[str], operator.add]