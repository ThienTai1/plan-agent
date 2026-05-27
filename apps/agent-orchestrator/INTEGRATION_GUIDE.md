# Frontend-Backend Integration Guide

## Overview

This guide explains how to integrate the Flutter frontend with the Planning Agent backend. The backend provides a multi-agent AI system that manages goals, tasks, habits, and events.

## Architecture Overview

```
Frontend (Flutter)                    Backend (FastAPI + LangChain)
─────────────────────────────        ─────────────────────────────

┌──────────────────┐                 ┌──────────────────────┐
│ Chat UI          │ ──────POST──→   │ Chat Endpoint        │
│                  │      /v1        │ /v4/chat/stream      │
└──────────────────┘      SSE        └──────────────────────┘
                          ←──────────
┌──────────────────┐                 ┌──────────────────────┐
│ Device Features  │                 │ Agents coordination  │
│ (Goals/Tasks)    │◄────POST────┤  ├ Task Planning Agent  │
│ Data Operations  │             │  ├ Analytics Agent      │
│ Local DB (PS)    │             │  ├ Calendar Agent       │
└──────────────────┘             │  └──────────────────────┘
                  /v1/agent/execute-tool
```

## Key Endpoints

### 1. Chat Streaming (Primary)

**Endpoint**: `POST /v1/v4/chat/stream`

**Request**:
```http
POST http://localhost:8100/v1/v4/chat/stream
Content-Type: application/json

{
  "query": "Help me create a goal to finish my project",
  "session_id": "user-session-123"
}

Headers:
- X-User-Id: "user-id-here" (optional)
```

**Response** (Server-Sent Events):
```
data: {"type":"start","session_id":"user-session-123"}

data: {"type":"message","content":"I'll help you create a goal for your project."}

data: {"type":"tool_call","tool_name":"create_goal","tool_args":{"title":"Finish my project","description":"...","endDate":"2024-12-31"}}

data: {"type":"done","final_message":"Goal created successfully!"}
```

**Implementation in Flutter**:
```dart
import 'package:http/http.dart' as http;

Future<void> chatWithAgent(String query, String sessionId) async {
  final response = await http.post(
    Uri.parse('http://localhost:8100/v1/v4/chat/stream'),
    headers: {
      'Content-Type': 'application/json',
      'X-User-Id': currentUserId,
    },
    body: jsonEncode({
      'query': query,
      'session_id': sessionId,
    }),
  );

  if (response.statusCode == 200) {
    // Parse SSE stream
    final stream = response.bodyBytes.split('\n');
    for (final line in stream) {
      if (line.startsWith('data: ')) {
        final json = jsonDecode(line.substring(6));
        _handleStreamEvent(json);
      }
    }
  }
}

void _handleStreamEvent(Map<String, dynamic> event) {
  switch (event['type']) {
    case 'message':
      _showAgentMessage(event['content']);
      break;
    case 'tool_call':
      _executeToolLocally(event['tool_name'], event['tool_args']);
      break;
    case 'done':
      _showFinalMessage(event['final_message']);
      break;
    case 'error':
      _showError(event['message']);
      break;
  }
}
```

### 2. Tool Execution on Frontend

**Endpoint**: `POST /v1/agent/execute-tool`

**Request** (from backend):
```http
POST http://localhost:3000/v1/agent/execute-tool
Content-Type: application/json
X-User-Id: user-123
X-Session-Id: session-123

{
  "tool_name": "create_goal",
  "parameters": {
    "title": "Finish my project",
    "description": "Complete the project requirements",
    "startDate": "2024-01-15",
    "endDate": "2024-12-31",
    "phases": [
      {
        "title": "Phase 1: Gather requirements",
        "tasks": [
          {"title": "Interview stakeholders"},
          {"title": "Document requirements"}
        ]
      }
    ]
  },
  "session_id": "user-session-123",
  "user_id": "user-123"
}
```

**Response** (on successful execution):
```json
{
  "success": true,
  "data": {
    "id": "goal-123",
    "title": "Finish my project",
    "status": "active",
    "createdAt": "2024-01-15T10:30:00Z",
    "phases": [...]
  }
}
```

**What your frontend must handle**:

The frontend MUST expose these tool endpoints:

#### Creating Resources

```dart
// POST /v1/agent/execute-tool?tool_name=create_goal
Future<Map> createGoal(Map params) async {
  final goal = Goal(
    title: params['title'],
    description: params['description'],
    startDate: DateTime.parse(params['startDate']),
    endDate: DateTime.parse(params['endDate']),
  );
  
  await goalRepository.create(goal);
  return goal.toJson();
}

// POST /v1/agent/execute-tool?tool_name=create_task
Future<Map> createTask(Map params) async {
  final task = Task(
    title: params['title'],
    goalId: params['goal_id'],
    priority: params['priority'],
    dueDate: params['due_date'] != null ? DateTime.parse(params['due_date']) : null,
  );
  
  await taskRepository.create(task);
  return task.toJson();
}
```

#### Listing Resources

```dart
// GET /v1/agent/execute-tool?tool_name=list_goals&status=active
Future<Map> listGoals(Map params) async {
  final status = params['status'] ?? 'all';
  final limit = params['limit'] ?? 50;
  
  final goals = await goalRepository.getByStatus(status);
  return {
    'success': true,
    'data': goals.take(limit).map((g) => g.toJson()).toList(),
  };
}
```

#### Updating Resources

```dart
// PUT /v1/agent/execute-tool?tool_name=update_task
Future<Map> updateTask(Map params) async {
  final task = await taskRepository.getById(params['task_id']);
  
  if (params['status'] != null) task.status = params['status'];
  if (params['priority'] != null) task.priority = params['priority'];
  if (params['title'] != null) task.title = params['title'];
  
  await taskRepository.update(task);
  return task.toJson();
}
```

## Available Tools

### Goal Tools
- `create_goal` - Create new goal with phases
- `list_goals` - List goals by status
- `get_goal` - Get specific goal with phases
- `update_goal` - Update goal properties

### Task Tools
- `create_task` - Create new task
- `list_tasks` - List tasks with filters
- `update_task` - Update task
- `complete_task` - Mark task as completed

### Habit Tools
- `create_habit` - Create habit tracker
- `log_habit_completion` - Log when habit is completed

### Event Tools
- `create_event` - Create calendar event
- `get_upcoming_events` - Get events for next N days

### Utility Tools
- `get_user_context` - Get summary of all user data
- `search` - Search across goals/tasks/habits

## Setup Instructions

### 1. Backend Setup

```bash
cd apps/backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Create .env
cat > .env << EOF
LLM_API_KEY=your-api-key
FRONTEND_URL=http://localhost:3000
EOF

# Run server
python -m uvicorn app.main:app --port 8100 --reload
```

### 2. Frontend Setup

Add the backend client to your Flutter app:

```dart
// lib/services/agent_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class AgentService {
  static const String baseUrl = 'http://localhost:8100';
  static const String apiV1 = '$baseUrl/v1';
  
  final String sessionId;
  final String userId;
  
  AgentService({
    required this.sessionId,
    required this.userId,
  });
  
  Future<Stream<Map<String, dynamic>>> chatStream(String query) async {
    return _streamChat(query);
  }
  
  Stream<Map<String, dynamic>> _streamChat(String query) async* {
    final request = http.Request('POST', Uri.parse('$apiV1/v4/chat/stream'))
      ..headers['Content-Type'] = 'application/json'
      ..headers['X-User-Id'] = userId
      ..body = jsonEncode({
        'query': query,
        'session_id': sessionId,
      });
    
    final response = await http.Client().send(request);
    
    await for (final line in response.stream
        .transform(utf8.decoder)
        .transform(LineSplitter())
        .where((l) => l.startsWith('data: '))) {
      try {
        final json = jsonDecode(line.substring(6));
        yield json;
      } catch (e) {
        print('Error parsing SSE: $e');
      }
    }
  }
}
```

### 3. UI Integration

```dart
// lib/features/chat/chat_page.dart
class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late AgentService agentService;
  List<ChatMessage> messages = [];
  
  @override
  void initState() {
    super.initState();
    agentService = AgentService(
      sessionId: getCurrentSessionId(),
      userId: getCurrentUserId(),
    );
  }
  
  void _sendMessage(String query) async {
    setState(() {
      messages.add(ChatMessage(role: 'user', content: query));
    });
    
    final stream = await agentService.chatStream(query);
    
    String response = '';
    await for (final event in stream) {
      switch (event['type']) {
        case 'message':
          response += event['content'];
          break;
        case 'tool_call':
          _handleToolCall(event['tool_name'], event['tool_args']);
          break;
        case 'done':
          setState(() {
            messages.add(ChatMessage(
              role: 'assistant',
              content: response,
            ));
          });
          break;
      }
    }
  }
  
  void _handleToolCall(String toolName, Map args) {
    // Execute tool on frontend
    // This could trigger UI updates, data modifications, etc.
    print('Tool called: $toolName with args: $args');
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('AI Agent')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return MessageBubble(message: msg);
              },
            ),
          ),
          ChatInput(onSubmit: _sendMessage),
        ],
      ),
    );
  }
}
```

## Error Handling

The backend can return errors in SSE format:

```json
{
  "type": "error",
  "message": "Tool execution failed",
  "error": "Goal not found"
}
```

Handle in frontend:

```dart
case 'error':
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(event['message'])),
  );
  break;
```

## Session Management

Each user session has a unique ID. Use this to:
- Track conversation history
- Maintain context across multiple queries
- Enable resumable conversations

```dart
// Generate session ID
String sessionId = uuid.v4(); // or use existing session

// Persist for offline mode
prefs.setString('session_id', sessionId);
```

## Best Practices

1. **Streaming**
   - Always use `/chat/stream` for real-time responses
   - Show loading indicators during generation
   - Display tool execution feedback

2. **Error Handling**
   - Catch and display agent errors gracefully
   - Show offline mode message if backend unavailable
   - Log errors for debugging

3. **Tool Execution**
   - Validate tool parameters before sending
   - Show confirmation dialog for critical operations
   - Sync local DB with agent results

4. **Performance**
   - Cache agent responses
   - Batch tool executions when possible
   - Limit message history for performance

5. **Security**
   - Validate backend responses
   - Don't expose sensitive data in messages
   - Use HTTPS in production

## Testing

Test the integration:

```bash
# Test health check
curl http://localhost:8100/

# Test chat endpoint
curl -X POST http://localhost:8100/v1/v4/chat \
  -H "Content-Type: application/json" \
  -d '{"query":"Create a goal","session_id":"test-123"}'

# Test streaming
curl -X POST http://localhost:8100/v1/v4/chat/stream \
  -H "Content-Type: application/json" \
  -d '{"query":"Help me plan my day","session_id":"test-123"}'
```

## Troubleshooting

| Issue | Solution |
|---|---|
| Connection refused | Ensure backend is running on correct port |
| CORS errors | Backend has CORS enabled by default |
| Slow responses | Check LLM API key and internet connection |
| Tool execution fails | Verify frontend endpoints match tool names |
| Messages not streaming | Check if using proper SSE parsing |

## Next Steps

1. Implement the tool endpoints in flutter backend (/v1/agent/execute-tool)
2. Add CORS configuration if using external frontend
3. Set up authentication with Supabase
4. Configure LLM provider and API keys
5. Test end-to-end workflows

