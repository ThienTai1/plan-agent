# OpenRouter Integration Guide

## Overview

Your backend is now configured to use **OpenRouter** for LLM inference via LangGraph's `create_react_agent`. This allows you to use any model available on OpenRouter with your specialized agents.

## What Was Updated

### 1. **Agent Factory** (`app/agent/factory.py`)
- Uses `langchain.agents.create_agent` (from LangChain)
- Actually uses LangGraph's `create_react_agent` under the hood
- Supports OpenRouter models with format: `openrouter:model-name`

### 2. **Agent Definitions** (`app/agent/agents.py`)
- **Task Planning Agent** - Uses create_agent with qwen/qwen-plus
- **Analytics Agent** - Uses create_agent with qwen/qwen-plus
- **Calendar Agent** - Uses create_agent with qwen/qwen-plus
- **Supervisor Agent** - Uses create_agent with qwen/qwen-plus

All agents now use LangGraph's react agent pattern with proper tool binding.

### 3. **Configuration** (`app/config/settings.py`)
- Added `OPENROUTER_API_KEY` setting
- Defaults to `openrouter:qwen/qwen-plus` model
- Automatic fallback to `LLM_API_KEY` if `OPENROUTER_API_KEY` not set

## Setup Instructions

### Step 1: Get OpenRouter API Key

1. Go to [https://openrouter.ai](https://openrouter.ai)
2. Sign up and create account
3. Navigate to "Keys" section
4. Copy your API key (starts with `sk-or-v1-`)

### Step 2: Configure Environment

Create `.env` file in `apps/backend/`:

```env
# Required
OPENROUTER_API_KEY=sk-or-v1-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Optional: Specify custom model
LLM_MODEL=openrouter:qwen/qwen-plus

# Frontend
FRONTEND_URL=http://localhost:3000
```

Or copy from template:
```bash
cp .env.example .env
# Edit .env with your API key
```

### Step 3: Run Backend

```bash
cd apps/backend
python -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"
python -m uvicorn app.main:app --port 8100 --reload
```

## Supported Models

OpenRouter supports 100+ models. Some popular options:

### Fast & Cheap
- `qwen/qwen-plus` - Default, good balance
- `qwen/qwen-turbo` - Faster, cheaper
- `meta-llama/llama-2-7b` - Open source

### High Quality
- `openai/gpt-4` - Best quality
- `openai/gpt-4-turbo` - Fast GPT-4
- `anthropic/claude-3-opus` - Strong reasoning
- `google/gemini-pro` - Google's model

### Budget Friendly
- `mistral/mistral-7b` - Great value
- `mistralai/mistral-medium` - Balanced
- `meta-llama/llama-2-13b` - Larger open model

### Medium Model
- `qwen/qwen-72b`
- `openai/gpt-3.5-turbo`
- `anthropic/claude-2.1`

## Changing Models

### Option 1: Environment Variable

```bash
# In .env
LLM_MODEL=openrouter:openai/gpt-4
```

### Option 2: In Code

Update model in `app/agent/agents.py`:

```python
agent = create_agent(
    model="openrouter:openai/gpt-4",  # Change here
    system_prompt=system_prompt,
    tools=task_tools,
)
```

### Option 3: At Runtime

Update in agent creation where needed:

```python
# Get model from config or parameter
model_name = settings.LLM_MODEL  # from .env
agent = create_agent(
    model=model_name,
    system_prompt=system_prompt,
    tools=task_tools,
)
```

## How It Works

```
User Query
    ↓
Supervisor Agent (qwen/qwen-plus)
    - Routes to specialist
    - Returns: agents_needed, is_direct_answer
    ↓
Task Planning Agent (qwen/qwen-plus)
    - Uses available tools
    - Can call frontend APIs
    - Returns: response with assistant message
    ↓
Response to User
```

### Agent-Tool Flow

1. **Agent receives request** via supervisor routing
2. **Agent analyzes request** and decides which tools to use
3. **Agent calls tools** (e.g., create_goal, list_tasks)
4. **Tools execute** on frontend or backend
5. **Agent gets results** and generates response
6. **Response streamed** back to user

### Tool Execution

Tools are wrapped async functions that:
1. Call frontend APIs via HTTP
2. Execute on local PowerSync database
3. Return results to agent
4. Agent uses results in reasoning

## Performance Tips

### Faster Responses
Use faster models:
```python
# In agents.py
model="openrouter:qwen/qwen-turbo"
# or
model="openrouter:mistral/mistral-7b"
```

### Better Quality
Use stronger models:
```python
model="openrouter:openai/gpt-4"
```

### Lower Cost
Use cheaper models:
```python
model="openrouter:meta-llama/llama-2-7b"
```

## Cost Estimation

OpenRouter uses per-token pricing. Rough estimates:

| Model | Input | Output | Cost/1K tokens |
|-------|-------|--------|---|
| qwen-plus | $0.0002 | $0.0006 | Very low |
| qwen-turbo | $0.0001 | $0.0003 | Very low |
| llama-2-7b | $0.0002 | $0.0002 | Very low |
| gpt-3.5-turbo | $0.0015 | $0.002 | Low |
| gpt-4 | $0.03 | $0.06 | Higher |
| claude-3-opus | $0.015 | $0.075 | Medium |

Check [OpenRouter pricing](https://openrouter.ai/models) for latest rates.

## Debugging

### Check API Key

```bash
# In Python
import os
from app.config import settings

print("API Key:", settings.openrouter_api_key)
print("Model:", settings.LLM_MODEL)
```

### Test Agent Directly

```bash
python scripts/test_agent.py
```

### View Logs

```bash
tail -f logs/app.log
```

### Common Issues

| Issue | Solution |
|-------|----------|
| "Invalid API key" | Check OPENROUTER_API_KEY in .env |
| "Model not found" | Verify model name on openrouter.ai |
| "Rate limited" | Check OpenRouter quota/limits |
| "Timeout" | Increase timeout or use faster model |

## Advanced: Custom Models

### Using Different Models Per Agent

Update `app/agent/agents.py`:

```python
async def create_task_planning_agent(session_id: str, user_id: str):
    # Use fast model for task planning
    agent = create_agent(
        model="openrouter:qwen/qwen-turbo",
        system_prompt=system_prompt,
        tools=task_tools,
    )
    # ...

async def create_analytics_agent(session_id: str, user_id: str):
    # Use more capable model for analysis
    agent = create_agent(
        model="openrouter:openai/gpt-4",
        system_prompt=system_prompt,
        tools=analytics_tools,
    )
    # ...
```

### Load Model from Config

```python
from app.config import settings

agent = create_agent(
    model=settings.LLM_MODEL,
    system_prompt=system_prompt,
    tools=task_tools,
)
```

## Factory Function Details

The `create_agent` function in `app/agent/factory.py`:

```python
def create_agent(model: str, system_prompt: str, tools: Optional[List[Any]] = None):
    # 1. Parses model string (removes "openrouter:" prefix)
    # 2. Creates ChatOpenAI instance configured for OpenRouter
    # 3. Sets up proper headers for OpenRouter
    # 4. Creates LangGraph react agent with tools
    # 5. Returns compiled graph ready for invocation
```

Features:
- ✅ Automatic tool binding
- ✅ Structured output support
- ✅ OpenRouter headers configuration
- ✅ Async/await support
- ✅ Full router configuration

## Testing

### Quick Test

```python
# In Python REPL
from app.agent.factory import create_agent

agent = create_agent(
    model="openrouter:qwen/qwen-plus",
    system_prompt="You are helpful assistant",
    tools=[]
)

result = agent.invoke({
    "messages": [{"role": "user", "content": "What is 2+2?"}]
})

print(result["messages"][-1].content)
```

### Full Integration Test

```bash
# Start backend
python -m uvicorn app.main:app --port 8100 --reload

# In another terminal
curl -X POST http://localhost:8100/v1/v4/chat \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Create a goal to learn Python",
    "session_id": "test-123"
  }'
```

## Troubleshooting

### Backend won't start with OpenRouter config

1. Check `.env` file exists
2. Verify `OPENROUTER_API_KEY` is set
3. Check API key format (starts with `sk-or-v1-`)
4. Verify model name is valid

### Agent times out

1. Try faster model: `qwen/qwen-turbo`
2. Check network connectivity
3. Verify OpenRouter service is up
4. Check API quota hasn't been exceeded

### Tool execution fails

1. Ensure frontend is running on correct port
2. Check `FRONTEND_URL` in `.env`
3. Verify frontend has `/v1/agent/execute-tool` endpoint
4. Check logs for detailed error

## Next Steps

1. ✅ Update to use OpenRouter's `create_agent`  
2. ✅ Configure API key in `.env`
3. 🚀 Run backend: `python -m uvicorn app.main:app --port 8100`
4. 🧪 Test with `curl` requests
5. 🔗 Connect frontend to backend
6. 🚀 Deploy to production

## Resources

- [OpenRouter Docs](https://openrouter.ai/docs)
- [OpenRouter Models](https://openrouter.ai/models)
- [LangGraph Docs](https://langchain-ai.github.io/langgraph/)
- [LangChain Docs](https://python.langchain.com/)

## Summary

Your backend is now configured with OpenRouter via LangGraph's `create_react_agent`. This provides:

✅ Access to 100+ models
✅ Simple model switching
✅ Built-in tool support
✅ Async/await compatibility
✅ Production-ready architecture

Everything is set up and ready to use! 🚀
