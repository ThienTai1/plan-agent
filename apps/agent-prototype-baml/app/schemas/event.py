from datetime import datetime
from typing import Optional
from app.schemas.base import BaseSchema

class EventBase(BaseSchema):
    user_id: Optional[str] = None
    title: str
    description: Optional[str] = None
    start_time: datetime
    end_time: datetime
    location: Optional[str] = None

class EventCreate(EventBase):
    id: Optional[str] = None

class Event(EventBase):
    id: str
    created_at: datetime

