from datetime import datetime
from typing import List, Optional
from pydantic import Field
from app.schemas.base import BaseSchema

class ToolCall(BaseSchema):
    name: str
    arguments: dict[str, str] = Field(default_factory=dict)

class AgentStep(BaseSchema):
    id: str
    summary: str
    tool_calls: List[ToolCall] = Field(default_factory=list)
    completed_at: Optional[datetime] = None

class PlanBase(BaseSchema):
    goal: str
    status: str = "draft"
    steps: List[AgentStep] = Field(default_factory=list)

class PlanCreate(PlanBase):
    id: str

class Plan(PlanBase):
    id: str
    created_at: datetime

