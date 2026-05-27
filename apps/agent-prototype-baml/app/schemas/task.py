from datetime import datetime
from typing import Optional, Dict, Any
from app.schemas.base import BaseSchema

class TaskBase(BaseSchema):
    user_id: Optional[str] = None
    title: str
    description: Optional[str] = None
    due_date: Optional[datetime] = None
    status: str = "PENDING"
    priority: Optional[str] = None
    metadata_json: Dict[str, Any] = Field(default_factory=dict)

class TaskCreate(TaskBase):
    id: Optional[str] = None

class Task(TaskBase):
    id: str
    is_overdue: bool
    created_at: datetime

