# Backend Complete - Frontend Action Items

## ✅ Backend Status: COMPLETE

All backend components are built, tested, and documented!

## 📋 Next Steps for Frontend

Your frontend needs to implement the following to fully integrate with the backend:

### 1. ⚠️ CRITICAL: Tool Execution Endpoint

**What**: The backend will send HTTP requests to your frontend asking it to execute tools.

**Endpoint to implement**:
```http
POST /v1/agent/execute-tool
Content-Type: application/json
X-User-Id: user-123
X-Session-Id: session-123
```

**Request body example**:
```json
{
  "tool_name": "create_goal",
  "parameters": {
    "title": "Learn Flutter",
    "description": "Complete Flutter course",
    "startDate": "2024-01-15T00:00:00Z",
    "endDate": "2024-03-15T00:00:00Z",
    "phases": null
  },
  "session_id": "session-123",
  "user_id": "user-123"
}
```

**Response format**:
```json
{
  "success": true,
  "data": {
    "id": "goal-uuid",
    "title": "Learn Flutter",
    "createdAt": "2024-01-15T10:30:00Z"
  }
}
```

### 2. Implement Tool Handlers

Implement handlers for these tools in your `/v1/agent/execute-tool` endpoint:

#### Goal Tools
- [ ] `create_goal(title, description, startDate, endDate, phases)` → Create goal in PowerSync
- [ ] `list_goals(status, limit)` → Query goals by status
- [ ] `get_goal(goal_id)` → Get goal with all phases/tasks
- [ ] `update_goal(goal_id, title, status, endDate)` → Update goal

#### Task Tools
- [ ] `create_task(title, goal_id, phase_id, priority, due_date, tags)` → Create task
- [ ] `list_tasks(status, goal_id, priority, due_date_range, limit)` → Query tasks
- [ ] `update_task(task_id, title, status, priority, due_date, notes)` → Update task
- [ ] `complete_task(task_id)` → Mark as completed

#### Habit Tools
- [ ] `create_habit(title, description, frequency, target_count)` → Create habit
- [ ] `log_habit_completion(habit_id, date)` → Log completion

#### Event Tools
- [ ] `create_event(title, start_time, end_time, description, color)` → Create event
- [ ] `get_upcoming_events(days, limit)` → Get upcoming events

#### Utility Tools
- [ ] `get_user_context()` → Return summary of user's data
- [ ] `search(query, entity_type)` → Search across entities

### 3. Connect Chat UI to Backend

**Add chat integration in your chat page**:

```dart
// In your chat provider/service
Future<void> sendMessageToAgent(String message) async {
  final response = await http.post(
    Uri.parse('http://localhost:8100/v1/v4/chat/stream'),
    headers: {
      'Content-Type': 'application/json',
      'X-User-Id': getCurrentUserId(),
    },
    body: jsonEncode({
      'query': message,
      'session_id': getCurrentSessionId(),
    }),
  );
  
  // Parse SSE stream and handle events
}
```

### 4. Update Environment Configuration

```dart
// In your config/constants.dart or similar
class ApiConfig {
  static const String agentBackendUrl = 'http://localhost:8100';
  static const String agentChatEndpoint = '/v1/v4/chat/stream';
}
```

### 5. Handle Streaming Responses

Implement SSE parsing in your chat service:

```dart
Stream<ChatEvent> chatStream(String message) async* {
  final request = http.Request(
    'POST',
    Uri.parse(ApiConfig.agentBackendUrl + ApiConfig.agentChatEndpoint),
  );
  
  request.body = jsonEncode({
    'query': message,
    'session_id': sessionId,
  });
  
  final response = await http.Client().send(request);
  
  await for (final line in response.stream
      .transform(utf8.decoder)
      .transform(LineSplitter())) {
    if (line.startsWith('data: ')) {
      final event = ChatEvent.fromJson(
        jsonDecode(line.substring(6)),
      );
      yield event;
    }
  }
}
```

### 6. Update Data Models

Add support for agent context in your models:

```dart
class ChatMessage {
  final String id;
  final String content;
  final String role; // 'user', 'assistant'
  final DateTime timestamp;
  final String? toolName; // For tool calls
  final Map<String, dynamic>? toolArgs;
}

class ChatThread {
  final String id;
  final String sessionId;
  final String userId;
  final List<ChatMessage> messages;
}
```

## 📝 Implementation Order

1. **Priority 1** - Implement tool execution endpoint + handlers
2. **Priority 2** - Connect chat UI to streaming endpoint
3. **Priority 3** - Handle SSE events properly
4. **Priority 4** - Sync results back to local database
5. **Priority 5** - Error handling and user feedback

## 🧪 Testing Checklist

After implementation, test:

- [ ] Backend health check: `curl http://localhost:8100/`
- [ ] Simple chat: Send "Hello" to backend
- [ ] Tool execution: Create goal via agent
- [ ] Task management: List and update tasks
- [ ] Error handling: Test with invalid data
- [ ] Session persistence: Multi-turn conversation
- [ ] Streaming: Verify SSE events arrive
- [ ] Offline mode: Gracefully handle backend unavailable

## 🔒 Security Considerations

1. **Authorization**: Validate `X-User-Id` header on all requests
2. **Input Validation**: Validate tool parameters before executing
3. **CORS**: Configure CORS properly for production
4. **Rate Limiting**: Implement rate limits on tool execution
5. **API Keys**: Never expose LLM API keys to frontend
6. **HTTPS**: Use HTTPS in production

## 🚀 Deployment Steps

1. Backend running on cloud (e.g., Cloud Run, Heroku)
2. Update `FRONTEND_URL` environment variable
3. Update backend URL in frontend config
4. Test end-to-end
5. Deploy frontend

## 🆘 Common Integration Issues

| Issue | Solution |
|-------|----------|
| Backend timeout on tool calls | Implement timeout handling |
| SSE stream cuts off | Check for proxy/load balancer issues |
| Tool endpoint not found | Verify exact URL path and method |
| CORS errors | Check CORS configuration |
| Tools fail silently | Add error logging to handlers |

## 📚 Reference Links

- Backend Docs: `BACKEND_GUIDE.md`
- Integration Guide: `INTEGRATION_GUIDE.md`
- Quick Start: `QUICKSTART.md`
- Example Code: `examples.py`

## 📞 Support

If you need help:

1. Check INTEGRATION_GUIDE.md first
2. Review examples.py for patterns
3. Check BACKEND_GUIDE.md for details
4. Add logging to debug issues

## ✨ What You Get After Integration

✅ AI-powered task planning
✅ Automated goal breakdown
✅ Progress analytics
✅ Smart scheduling
✅ Natural language interface
✅ Real-time responses
✅ Conversational UI

## 🎯 Your Next Immediate Action

**👉 Start here: Implement `POST /v1/agent/execute-tool` endpoint in your frontend**

This is the critical piece that bridges backend and frontend. Once this works, everything else follows naturally!

---

**Backend is ready! Now it's time to connect it to your frontend.** 💪

