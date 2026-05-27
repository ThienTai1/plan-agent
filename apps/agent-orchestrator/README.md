# 🤖 Planning Agent Backend

A powerful multi-agent AI backend for goal and task management, built with LangChain, LangGraph, and FastAPI.

[![Python 3.11+](https://img.shields.io/badge/python-3.11+-blue.svg)](https://www.python.org/)
[![FastAPI](https://img.shields.io/badge/fastapi-0.115+-green.svg)](https://fastapi.tiangolo.com/)
[![LangChain](https://img.shields.io/badge/langchain-0.3+-orange.svg)](https://langchain.com/)
[![LangGraph](https://img.shields.io/badge/langgraph-0.2+-red.svg)](https://langchain-ai.github.io/langgraph/)

## 🎯 Features

- **🤖 Multi-Agent System**: Specialized agents for tasks, analytics, and calendar management
- **⚡ Real-time Streaming**: Server-Sent Events for smooth, responsive UX
- **🔗 Frontend Integration**: Agents seamlessly call frontend tools via HTTP
- **💾 Local-First Support**: Works with local-first databases (PowerSync, etc.)
- **📚 14+ Tools**: Pre-built tools for goals, tasks, habits, and events
- **🛡️ Session Management**: Per-user session tracking and conversation history
- **📝 Complete Documentation**: 3 comprehensive guides + examples

## 🚀 Quick Start

Get the backend running in 5 minutes:

```bash
# 1. Setup
cd apps/backend
python -m venv .venv
source .venv/bin/activate  # or `.venv\Scripts\activate` on Windows

# 2. Install
pip install -e ".[dev]"

# 3. Configure
echo "LLM_API_KEY=your-google-genai-key" > .env

# 4. Run
python -m uvicorn app.main:app --port 8100 --reload

# 5. Test
curl http://localhost:8100/
python examples.py
```

✅ That's it! Your backend is running!

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| [QUICKSTART.md](QUICKSTART.md) | Get running in 5 minutes |
| [BACKEND_GUIDE.md](BACKEND_GUIDE.md) | Complete architecture reference (400+ lines) |
| [INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md) | Frontend integration step-by-step |
| [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) | What was built and why |
| [FRONTEND_TODO.md](FRONTEND_TODO.md) | What frontend needs to implement |

**👉 Start with QUICKSTART.md to get running!**

## 🏗️ Architecture

```
[User Query]
     ↓
[Supervisor Agent] ← Analyzes & routes
     ↓
    ├→ [Task Planning Agent] ← Goals & Tasks
    ├→ [Analytics Agent] ← Progress & Insights
    └→ [Calendar Agent] ← Events & Scheduling
     ↓
[Frontend Tools] ← Calls frontend APIs
     ↓
[Frontend Database] ← PowerSync/SQLite
```

Every agent has access to tools that execute on the frontend, enabling seamless goal and task management!

## 🛠️ API Endpoints

```
GET  /                      Health check
GET  /health               Health status
POST /v1/v4/chat           Chat (non-streaming)
POST /v1/v4/chat/stream    Chat with SSE streaming
```

All endpoints support natural language queries. The backend handles the complexity!

## 💡 Example Usage

**User asks**: "Help me plan my project launch"

**Backend does**:
1. Supervisor analyzes the query
2. Routes to Task Planning Agent
3. Agent creates structured plan
4. Calls `create_goal` tool
5. Frontend executes on local database
6. Returns result to agent
7. Streams response back to user

All in real-time with streaming responses!

## 🧠 Agents

### Supervisor/Orchestrator
Routes requests to appropriate specialists based on content analysis.

**Example**: "Create a goal to learn Python" → Task Planning Agent

### Task Planning Agent  
Specializes in goal and task management.

**Capabilities**:
- Create goals with phases
- Break down goals into tasks
- Organize work
- Suggest task prioritization

### Analytics Agent
Analyzes progress and provides insights.

**Capabilities**:
- Track goal completion rates
- Identify patterns
- Suggest improvements
- Generate reports

### Calendar Agent
Manages events and scheduling.

**Capabilities**:
- Create calendar events
- Suggest optimal time slots
- Integrate with task deadlines
- Balance workload

## 🔧 Tools (14+)

**Goal Tools** (4):
- `create_goal` - Create with phases
- `list_goals` - Filter by status
- `get_goal` - Get with details
- `update_goal` - Update properties

**Task Tools** (4):
- `create_task` - Create with priority
- `list_tasks` - Filter by status/date
- `update_task` - Update properties
- `complete_task` - Mark done

**Habit Tools** (2):
- `create_habit` - Create tracker
- `log_habit_completion` - Log completion

**Event Tools** (2):
- `create_event` - Create event
- `get_upcoming_events` - Get schedule

**Utility Tools** (2):
- `get_user_context` - Get data summary
- `search` - Cross-entity search

## 📦 Tech Stack

| Component | Technology |
|-----------|-----------|
| Framework | FastAPI |
| Agents | LangChain + LangGraph |
| LLM | Google Gemini |
| HTTP | httpx |
| Logging | Loguru |
| Config | Pydantic |
| Async | asyncio |

## 🔌 Frontend Integration

The backend communicates with your frontend via HTTP:

1. **Streaming Chat**: Frontend opens SSE stream for real-time responses
2. **Tool Execution**: Backend calls `/v1/agent/execute-tool` on frontend
3. **Data Sync**: All operations happen on frontend's local database

Perfect for local-first apps!

### Frontend Setup Required

Your frontend must:
1. Implement `/v1/agent/execute-tool` endpoint
2. Handle tool execution requests
3. Execute on local database
4. Return results to backend

See [INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md) for details.

## 📋 Project Structure

```
backend/
├── app/
│   ├── agent/               # Agent definitions
│   ├── api/                 # FastAPI routes
│   ├── services/            # Business logic
│   ├── tools/               # Tool definitions
│   ├── config/              # Configuration
│   ├── utils/               # Utilities
│   └── main.py              # App entry point
├── tests/                   # Test suite
├── examples.py              # Usage examples
├── pyproject.toml           # Dependencies
│
└── DOCS:
    ├── QUICKSTART.md            # Get started (5 min)
    ├── BACKEND_GUIDE.md         # Complete reference
    ├── INTEGRATION_GUIDE.md     # Frontend setup
    ├── IMPLEMENTATION_SUMMARY.md # What was built
    └── FRONTEND_TODO.md         # Frontend checklist
```

## 💻 Development

### Running Tests
```bash
pytest tests/ -v
```

### Code Quality
```bash
ruff check app/
black app/
```

### View Logs
```bash
tail -f logs/app.log
```

## 🐛 Troubleshooting

### Backend won't start
```bash
# Check Python version
python --version  # Should be 3.11+

# Check port is free
lsof -i :8100  # macOS/Linux

# Check dependencies
pip install -e ".[dev]"
```

### LLM errors
- Verify `LLM_API_KEY` in `.env`
- Check API key has required permissions
- Monitor API usage quota

### Tool execution fails
- Check frontend URLs in `.env`
- Verify frontend is running
- Review logs for details

See [BACKEND_GUIDE.md](BACKEND_GUIDE.md) for comprehensive troubleshooting.

## 🚀 Deployment

### Local Development
```bash
python -m uvicorn app.main:app --port 8100 --reload
```

### Production
```bash
# Using Gunicorn + Uvicorn
gunicorn app.main:app \
  --worker-class uvicorn.workers.UvicornWorker \
  --workers 4 \
  --bind 0.0.0.0:8100
```

### Cloud Deployment
- **Google Cloud Run**: Easy container deployment
- **Heroku**: Simple git push deployment
- **AWS**: EC2, Lambda (with adjustments)
- **DigitalOcean**: Droplet or App Platform

Set `FRONTEND_URL` to your frontend's deployed URL!

## 📈 Monitoring

The system logs all important events:
```
INFO:     Agent workflow started | Query: Create a goal
DEBUG:    Supervisor analyzing request
INFO:     Task Planning Agent called
DEBUG:    Tool executed: create_goal
INFO:     Agent workflow completed
```

Logs are written to `logs/app.log`

## 📖 Learning Path

1. **Start Here**: [QUICKSTART.md](QUICKSTART.md) - Get it running
2. **Understand**: [BACKEND_GUIDE.md](BACKEND_GUIDE.md) - Learn architecture
3. **See Examples**: `python examples.py` - Run examples
4. **Integrate**: [INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md) - Connect frontend
5. **Explore**: Check code in `app/` directory

## 💡 Key Insights

**Why this architecture?**
- ✅ **Separation of Concerns**: Backend handles AI, frontend handles data
- ✅ **Scalability**: Easy to add new agents
- ✅ **Flexibility**: Tools can be added without code changes
- ✅ **Real-time**: Streaming for smooth UX
- ✅ **Offline-first**: Works with local databases

**How are tools different?**
- Traditional: Backend directly accesses database
- **This approach**: Backend asks frontend to execute tools
- Benefits: Works with local-first DBs, respects user privacy

## 🎓 Want to Learn More?

- [LangChain Documentation](https://python.langchain.com/)
- [LangGraph Guide](https://langchain-ai.github.io/langgraph/)
- [FastAPI Tutorial](https://fastapi.tiangolo.com/)
- [Agent Design Patterns](https://langchain-ai.github.io/langgraph/concepts/agentic_concepts/)

## 🤝 Contributing

Pull requests welcome! Please:
1. Follow existing code structure
2. Add docstrings to functions
3. Create tests for new features
4. Update documentation

## 📄 License

[Your License Here]

## 🎉 What's Next?

1. ✅ **Backend is done!** Running and ready.
2. 📋 **Frontend setup needed**: See [FRONTEND_TODO.md](FRONTEND_TODO.md)
3. 🔗 **Integration**: Follow [INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md)
4. 🚀 **Deploy**: Push to production

## 📞 Support

Need help?
1. Check relevant docs (QUICKSTART, GUIDE, INTEGRATION)
2. Review examples.py
3. Check troubleshooting sections
4. Review code comments

---

**🚀 You have a complete, production-ready backend!**

Ready to get started? → Read [QUICKSTART.md](QUICKSTART.md)

Need integration help? → Read [INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md)

Want the full picture? → Read [BACKEND_GUIDE.md](BACKEND_GUIDE.md)

