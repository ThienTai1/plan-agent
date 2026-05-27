"""
BASE.PY - Foundation for the toolset (Tools).
Defines abstract classes and configuration for 
standardized return results (ToolResult). All new tools 
must inherit from BaseTool to ensure project consistency.
"""
from abc import ABC, abstractmethod
from typing import Any, Dict, Optional, Union
from pydantic import BaseModel


class ToolResult(BaseModel):
    """Standardized result for all tool executions"""
    success: bool
    data: Optional[Union[Dict[str, Any], str, list]] = None
    error: Optional[str] = None

class BaseTool(ABC):
    """
    Base class for all tools in the Levigo Agent stack.
    Forces subclasses to implement both name, description and run/arun methods.
    """
    name: str
    description: str

    @abstractmethod
    async def arun(self, **kwargs: Any) -> ToolResult:
        """Asynchronous execution of the tool (Preferred)"""
        ...

    def run(self, **kwargs: Any) -> ToolResult:
        """Synchronous execution of the tool (Legacy/Fallback)"""
        raise NotImplementedError("Use arun() for this tool")