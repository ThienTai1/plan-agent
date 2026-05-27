from pydantic import BaseModel


class PlanCreateRequest(BaseModel):
    query: str


class ChatMessage(BaseModel):
    role: str
    content: str


class Conversation(BaseModel):
    id: str
    messages: list[ChatMessage]


class ChatRequest(BaseModel):
    query: str
    history: list[ChatMessage] = []


class ChatResponse(BaseModel):
    message: str
    title: str | None = None
    follow_ups: list[str] = []
    pending_action: dict | None = None
    pending_actions: list[dict] = []
    reasoning: str | None = None


class ActionExecuteRequest(BaseModel):
    action: str
    data: dict

class ActionExecuteResponse(BaseModel):
    status: str
    message: str
    data: dict | list | None = None
    
class ActionBundleExecuteRequest(BaseModel):
    actions: list[ActionExecuteRequest]

class ActionBundleExecuteResponse(BaseModel):
    status: str
    message: str
    results: list[dict] = []

