# Quick Start Guide - Planning Agent Backend

Get the backend running in 5 minutes!

## Prerequisites

- Python 3.11+
- pip or uv package manager
- API Key for LLM (Google Gemini recommended)

## 1. Setup Environment

```bash
cd apps/backend

# Create virtual environment
python -m venv .venv

# Activate it
# On macOS/Linux:
source .venv/bin/activate
# On Windows:
.venv\Scripts\activate
```

## 2. Install Dependencies

```bash
# Using pip
pip install -e ".[dev]"

# Or using uv (faster)
uv pip install -e ".[dev]"
```

## 3. Configure Environment

Create `.env` file in `apps/backend/`:

```env
# Required - Get from Google Cloud Console
LLM_API_KEY=YOUR_GOOGLE_GENAI_API_KEY

# Optional - for frontend integration
FRONTEND_URL=http://localhost:3000
FRONTEND_API_URL=http://localhost:3000/api

# Optional - for Supabase
SUPABASE_URL=your-supabase-url
SUPABASE_KEY=your-supabase-key

# Development
DEBUG=True
LOG_LEVEL=INFO
```

## 4. Start the Server

```bash
python -m uvicorn app.main:app --port 8100 --reload
```

Expected output:
```
INFO:     Uvicorn running on http://0.0.0.0:8100
INFO:     Application startup complete
```

## 5. Test It Works

### Health Check
```bash
curl http://localhost:8100/
```

Response:
```json
{
  "status": "ok",
  "service": "Planning Agent Backend",
  "version": "0.1.0"
}
```

### Chat Endpoint
```bash
curl -X POST http://localhost:8100/v1/v4/chat \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Create a goal to learn Python",
    "session_id": "test-session"
  }' \
  -H "X-User-Id: test-user"
```

## 6. Try Interactive Examples

```bash
python examples.py
```

This runs example interactions showing:
- Task planning workflow
- Session management
- Multi-turn conversations
- Tool access

## Common Issues

### Issue: `ModuleNotFoundError: No module named 'app'`
**Solution**: Make sure you're in the `apps/backend` directory and have activated the virtual environment.

### Issue: `LLM_API_KEY not provided`
**Solution**: Set your API key in `.env` file:
```bash
echo "LLM_API_KEY=your-key-here" >> .env
```

### Issue: Port 8100 already in use
**Solution**: Use a different port:
```bash
python -m uvicorn app.main:app --port 8101 --reload
```

### Issue: Connection to frontend fails
**Solution**: Make sure `FRONTEND_URL` in `.env` is correct and frontend is running.

## Next Steps

1. **Read BACKEND_GUIDE.md** - Understand the architecture
2. **Read INTEGRATION_GUIDE.md** - Integrate with your frontend
3. **Review examples.py** - See usage patterns
4. **Check out tools** - See available tools in `app/tools/frontend_tools.py`

## Development Commands

```bash
# Run tests
pytest tests/ -v

# Check code quality
ruff check app/

# Format code
black app/

# View logs
tail -f logs/app.log

# Stop server (Ctrl+C)
```

## Project Structure

```
backend/
├── app/
│   ├── agent/          # Agent definitions
│   │   ├── agents.py       # Specialized agents
│   │   ├── core.py         # Main entry point
│   │   ├── state.py        # State definitions
│   │   ├── workflow.py      # LangGraph workflow
│   │   └── schemas.py      # Data models
│   ├── api/            # FastAPI routes
│   │   ├── routes.py       # Main endpoints
│   │   └── deps.py         # Dependencies
│   ├── services/       # Business logic
│   │   ├── frontend_client.py  # Frontend communication
│   │   ├── session_manager.py  # Session handling
│   │   └── llm.py          # LLM service
│   ├── tools/          # Tool definitions
│   │   ├── frontend_tools.py   # Tools for frontend
│   │   └── base.py         # Base tool class
│   ├── config/         # Configuration
│   │   └── settings.py      # Settings management
│   ├── utils/          # Utilities
│   │   └── helpers.py      # Helper functions
│   └── main.py         # FastAPI app
├── tests/              # Test files
├── examples.py         # Example usage
├── pyproject.toml      # Dependencies
├── BACKEND_GUIDE.md    # Full documentation
├── INTEGRATION_GUIDE.md # Frontend integration
└── .env.example        # Example environment
```

## API Endpoints Overview

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/` | Health check |
| GET | `/health` | Health status |
| POST | `/v1/v4/chat` | Chat (non-streaming) |
| POST | `/v1/v4/chat/stream` | Chat (SSE streaming) |

## Features

✅ Multi-agent orchestration with LangChain + LangGraph
✅ Task planning, analytics, and calendar agents
✅ Streaming responses with Server-Sent Events
✅ Frontend tool execution bridge
✅ Session management
✅ Comprehensive logging
✅ Async/await support
✅ Error handling

## Architecture Highlights

- **Supervisor Agent**: Routes requests to specialists
- **Task Planning Agent**: Manages goals and tasks
- **Analytics Agent**: Analyzes progress and provides insights  
- **Calendar Agent**: Schedules events and manages time

All agents can call tools on the frontend to interact with the local-first database!

## Support

- 📚 Full docs: Read `BACKEND_GUIDE.md`
- 🔗 Integration: Read `INTEGRATION_GUIDE.md`
- 💡 Examples: Run `python examples.py`
- 🐛 Issues: Check troubleshooting section above

---

**You're all set!** Your backend is now running and ready to power your AI-driven planning app. 🚀
