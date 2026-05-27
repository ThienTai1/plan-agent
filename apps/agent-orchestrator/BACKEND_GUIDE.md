# Planning Agent Backend - Complete Documentation

A comprehensive multi-agent backend for goal and task management, built with LangChain, LangGraph, and FastAPI.

## 🏗️ Architecture Overview

### System Design

```
┌─────────────────────────────────────────┐
│         Frontend (Flutter App)          │
│   - Local-first database (PowerSync)    │
│   - Goals, Tasks, Habits, Events        │
└──────────────┬──────────────────────────┘
               │ HTTP/SSE
┌──────────────▼──────────────────────────┐
│      Backend - FastAPI Server           │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │  Supervisor/Orchestrator Agent     │ │
│  │  - Analyzes requests               │ │
│  │  - Routes to specialists           │ │
│  └───────────┬────────────────────────┘ │
│              │                           │
│    ┌─────────┼─────────┬────────────┐   │
│    │         │         │            │   │
│    ▼         ▼         ▼            ▼   │
│  ┌───┐    ┌────────┐ ┌────────┐ ┌────┐ │
│  │TPL│    │Analytics│ Calendar │ │...│ │
│  └─┬─┘    └───┬────┘ └───┬────┘ └──┬─┘ │
│    │          │          │         │   │
│    └──────────┼──────────┼─────────┘   │
│               │  Tools   │             │
│    ┌──────────▼──────────▼────┐        │
│    │  Frontend Tools Library   │        │
│    │  (Call Frontend APIs)     │        │
│    └─────────────────────────┘        │
└─────────────────────────────────────────┘
               │ HTTP
┌──────────────▼──────────────────────────┐
│      Frontend - Tool Executor           │
│  Execute tools on local database        │
└─────────────────────────────────────────┘
```

### Key Components

1. **Supervisor/Orchestrator Agent**
   - Analyzes user queries
   - Routes to appropriate specialist agents
   - Can answer direct questions
   - Coordinates multi-agent workflows

2. **Specialized Agents**
   - **Task Planning Agent**: Goal/task management
   - **Analytics Agent**: Progress analysis & insights
   - **Calendar Agent**: Event scheduling & time management

3. **Frontend Tools**
   - Bridge between backend agents and frontend data
   - Async execution for data operations
   - Real-time data synchronization

4. **API Layer**
   - RESTful endpoints for chat
   - Server-Sent Events (SSE) for streaming responses
   - Real-time tool execution feedback

## 🚀 Getting Started

### Prerequisites

```bash
Python >= 3.11
FastAPI >= 0.115.0
LangChain >= 0.3.14
LangGraph >= 0.2.28
```

### Installation

```bash
# Navigate to backend directory
cd apps/backend

# Create virtual environment
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
# or with uv
uv pip install -r requirements.txt
```

### Environment Configuration

Create a `.env` file:

```env
# LLM Configuration
LLM_PROVIDER=google
LLM_MODEL=gemini-2.0-flash-exp
LLM_API_KEY=your-api-key

# Frontend Configuration
FRONTEND_URL=http://localhost:3000
FRONTEND_API_URL=http://localhost:3000/api

# Database
SUPABASE_URL=your-supabase-url
SUPABASE_KEY=your-supabase-key

# Server
DEBUG=True
LOG_LEVEL=INFO
```

### Running the Server

```bash
# Development with auto-reload
python -m uvicorn app.main:app --host 0.0.0.0 --port 8100 --reload

# Production
python -m uvicorn app.main:app --host 0.0.0.0 --port 8100 --workers 4
```

Visit `http://localhost:8100` to verify it's running.

## 📡 API Endpoints

### Chat Endpoints

#### 1. Streaming Chat (SSE)
```http
POST /v1/v4/chat/stream
Content-Type: application/json

{
  "query": "Create a goal to complete my project by end of month",
  "session_id": "user-session-123"
}
```

**Response**: Server-Sent Events stream

```
data: {"type":"start","session_id":"user-session-123"}
data: {"type":"message","content":"I'll help you create that goal..."}
data: {"type":"tool_call","tool_name":"create_goal","tool_args":{...}}
data: {"type":"done","final_message":"Goal created successfully!"}
```

#### 2. Non-Streaming Chat
```http
POST /v1/v4/chat
Content-Type: application/json

{
  "query": "What's my task completion rate this week?",
  "session_id": "user-session-123"
}
```

**Response**:
```json
{
  "session_id": "user-session-123",
  "messages": [...],
  "pending_action": null,
  "final_answer": "You've completed 12 out of 18 tasks this week..."
}
```

#### 3. Health Check
```http
GET /
```

## 🛠️ Frontend Tools Reference

### Goal Management

```python
# Create a goal
create_goal(
    title: str,
    description: str = None,
    startDate: str = None,
    endDate: str = None,
    phases: list = None
)

# List goals
list_goals(status: str = "active", limit: int = 50)

# Get specific goal
get_goal(goal_id: str)

# Update goal
update_goal(
    goal_id: str,
    title: str = None,
    status: str = None,
    endDate: str = None
)
```

### Task Management

```python
# Create task
create_task(
    title: str,
    goal_id: str = None,
    priority: str = "medium",
    due_date: str = None,
    tags: list = None
)

# List tasks
list_tasks(
    status: str = "all",
    goal_id: str = None,
    priority: str = None,
    limit: int = 50
)

# Update task
update_task(
    task_id: str,
    status: str = None,
    priority: str = None,
    due_date: str = None
)

# Complete task
complete_task(task_id: str)
```

### Habit Tracking

```python
# Create habit
create_habit(
    title: str,
    frequency: str = "daily",
    target_count: int = 1
)

# Log completion
log_habit_completion(habit_id: str, date: str = None)
```

### Calendar Management

```python
# Create event
create_event(
    title: str,
    start_time: str,
    end_time: str,
    description: str = None
)

# Get upcoming events
get_upcoming_events(days: int = 7, limit: int = 20)
```

### Utilities

```python
# Get user context (summary of all data)
get_user_context()

# Search across all entities
search(query: str, entity_type: str = "all")
```

## 🔄 How It Works - User Query Flow

### Example: "Help me create a goal to launch my side project"

1. **Request Reception**
   ```
   POST /v1/v4/chat/stream
   {"query": "Help me create a goal to launch my side project", "session_id": "..."}
   ```

2. **Supervisor Analysis**
   - Supervisor agent analyzes the query
   - Identifies this requires Task Planning agent
   - Routes request accordingly

3. **Task Planning Agent Execution**
   - Receives user query
   - Has access to goal/task tools
   - Creates interactive dialogue:
     - "I'll help you create a goal for your side project"
     - "What's a realistic timeline? (e.g., 3 months)"
     - Uses response to create goal with phases

4. **Frontend Tool Execution**
   - Agent calls `create_goal` tool
   - Frontend Client sends HTTP request to frontend's `/v1/agent/execute-tool`
   - Frontend executes tool on local PowerSync database
   - Response returned to agent with created goal ID

5. **Response Streaming**
   - Agent streams response: "Goal created! I've set up 3 phases..."
   - Can suggest next steps or ask follow-up questions

## 🏭 Extending the System

### Adding a New Tool

1. **Create tool class** in `app/tools/frontend_tools.py`:

```python
class MyNewTool(FrontendTool):
    name = "my_new_tool"
    description = "What this tool does"
    
    async def arun(self, param1: str, param2: int = None, **kwargs) -> ToolResult:
        result = await self.frontend_client.execute_tool(
            tool_name="my_new_tool",
            parameters={"param1": param1, "param2": param2},
            session_id=self.session_id,
            user_id=self.user_id,
        )
        return ToolResult(success=result.success, data=result.data, error=result.error)
```

2. **Register tool** in `create_frontend_tools()`:

```python
"my_new_tool": MyNewTool(session_id, user_id)
```

3. **Add to agent tools**:

```python
# In agent creation
frontend_tools = create_frontend_tools(session_id, user_id)
agent_tools = [frontend_tools["my_new_tool"], ...]
```

### Creating a New Specialized Agent

1. **Define agent** in `app/agent/agents.py`:

```python
async def create_my_agent(session_id: str, user_id: str):
    """Create your specialized agent"""
    llm_service = LLMService()
    model = llm_service.get_model()
    
    frontend_tools = create_frontend_tools(session_id, user_id)
    my_tools = [frontend_tools["tool1"], frontend_tools["tool2"]]
    
    model_with_tools = model.bind_tools(my_tools, tool_choice="auto")
    
    prompt = ChatPromptTemplate.from_messages([
        ("system", "Your agent's instructions..."),
        MessagesPlaceholder(variable_name="messages"),
    ])
    
    async def my_agent(messages: List[Dict[str, Any]]) -> str:
        chain = prompt | model_with_tools
        response = await chain.ainvoke({"messages": messages})
        return response
    
    return my_agent
```

2. **Add to workflow** in `app/agent/workflow.py`:

```python
# Add node
graph.add_node("my_agent", my_agent_node)

# Add routing
graph.add_conditional_edges("supervisor", route_after_supervisor, {...})
```

## 📊 Database Integration

### How Frontend Data is Accessed

1. **Frontend has local PowerSync database**
   - SQLite on local device
   - Syncs to Supabase when online
   - Completely offline-first

2. **Agent makes requests through Frontend APIs**
   - Backend doesn't directly access frontend database
   - Instead, calls frontend's API endpoints
   - Frontend serves data from local cache

3. **Real-time Sync**
   - Frontend auto-syncs with Supabase
   - Agent can query Supabase directly if needed (via services)
   - Ensures data consistency

### Frontend API Contract

Frontend must expose:

```http
POST /v1/agent/execute-tool
{
  "tool_name": "list_tasks",
  "parameters": {"status": "pending"},
  "session_id": "...",
  "user_id": "..."
}

Response:
{
  "success": true,
  "data": [
    {"id": "task1", "title": "Task 1", ...},
    ...
  ]
}
```

## 🔐 Security Considerations

1. **Authentication**
   - Use X-User-Id header for user identification
   - Validate session IDs
   - Implement JWT tokens for API protection

2. **Tool Execution**
   - Frontend validates tool execution requests
   - Backend doesn't have direct database access
   - All operations go through frontend APIs

3. **Rate Limiting**
   - Implement rate limits on chat endpoint
   - Track AI credit usage (for premium features)
   - Queue long-running tasks

## 📈 Monitoring & Logging

The system includes comprehensive logging:

```python
from loguru import logger

logger.info("User query received")
logger.error("Tool execution failed")
logger.debug("Agent state updated")
```

Access logs at: `logs/app.log`

## 🧪 Testing

### Running Tests

```bash
pytest tests/ -v

# With coverage
pytest tests/ --cov=app --cov-report=html
```

### Example Test

```python
async def test_task_planning_agent():
    agent = await create_task_planning_agent("session-1", "user-1")
    messages = [{"role": "user", "content": "Create a task"}]
    response = await agent(messages)
    assert response is not None
```

## 📚 Resources

- [LangChain Documentation](https://python.langchain.com/)
- [LangGraph Documentation](https://langchain-ai.github.io/langgraph/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Frontend Architecture Docs](../frontend/README.md)

## 🐛 Troubleshooting

### Agent not responding

1. Check LLM API key in `.env`
2. Verify frontend URL is correct
3. Check logs: `tail -f logs/app.log`

### Tool execution failing

1. Verify frontend server is running
2. Check tool parameters format
3. Review frontend response headers

### Slow responses

1. Check LLM provider status
2. Monitor token usage
3. Implement caching for frequent queries

## 📝 Contributing

When contributing:

1. Follow existing code structure
2. Add docstrings to functions
3. Create tests for new features
4. Update documentation
5. Use logging for debugging

## 📄 License

[Your License Here]

## 🤝 Support

For issues or questions:
- Create an issue on GitHub
- Check existing documentation
- Review test cases for examples
