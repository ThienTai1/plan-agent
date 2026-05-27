class AiRequest {
  final String message;
  final Map<String, dynamic> context;
  final List<Map<String, dynamic>>? history;

  AiRequest({required this.message, required this.context, this.history});

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'context': context,
      if (history != null) 'history': history,
    };
  }
}

enum AiResponseType { text, toolCall }

class AiResponse {
  final AiResponseType type;
  final String? content;
  final ToolCallData? toolData;

  AiResponse({required this.type, this.content, this.toolData});

  factory AiResponse.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String;
    if (typeStr == 'tool_call') {
      // Backend now nests tool data inside 'content'
      return AiResponse(
        type: AiResponseType.toolCall,
        toolData: ToolCallData.fromJson(json['content'] ?? {}),
      );
    } else {
      return AiResponse(
        type: AiResponseType.text,
        content: json['content'] as String?,
      );
    }
  }
}

class ToolCallData {
  final String toolName;
  final String callId;
  final Map<String, dynamic> arguments;

  ToolCallData({
    required this.toolName,
    required this.callId,
    required this.arguments,
  });

  factory ToolCallData.fromJson(Map<String, dynamic> json) {
    return ToolCallData(
      toolName: json['tool_name'] as String? ?? 'unknown',
      callId: json['call_id'] as String? ?? '',
      arguments: json['arguments'] as Map<String, dynamic>? ?? {},
    );
  }
}

class ToolResultRequest {
  final String callId;
  final bool success;
  final dynamic data;
  final String? error;

  ToolResultRequest({
    required this.callId,
    required this.success,
    this.data,
    this.error,
  });

  Map<String, dynamic> toJson() {
    return {
      'call_id': callId,
      'success': success,
      'data': data,
      'error': error,
    };
  }
}
