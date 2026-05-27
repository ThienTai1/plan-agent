import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/config/api_config.dart';

class StreamResult {
  final String? intent;
  final String? text;
  final String? status;
  final Map<String, dynamic>? toolCall;
  final Map<String, dynamic>? metadata;
  final String? error;

  StreamResult({
    this.intent,
    this.text,
    this.status,
    this.toolCall,
    this.metadata,
    this.error,
  });
}

class ChatStreamService {
  final http.Client _client = http.Client();

  Stream<StreamResult> streamChat({
    required String query,
    required List<Map<String, dynamic>> history,
    required String userId,
    String? token,
  }) async* {
    final url = Uri.parse(ApiConfig.getFullUrl(ApiConfig.chatStreamEndpoint));

    final request = http.Request('POST', url);
    request.headers.addAll({
      'Content-Type': 'application/json',
      'Accept': 'text/event-stream',
      if (token != null) 'Authorization': 'Bearer $token',
    });
    request.body = jsonEncode({'query': query, 'history': history});

    try {
      final response = await _client.send(request);

      if (response.statusCode == 403) {
        yield StreamResult(error: 'QUOTA_EXCEEDED');
        return;
      } else if (response.statusCode == 429) {
        yield StreamResult(error: 'RATE_LIMIT_EXCEEDED');
        return;
      } else if (response.statusCode != 200) {
        yield StreamResult(error: 'Failed to connect: ${response.statusCode}');
        return;
      }

      await for (final chunk
          in response.stream
              .transform(utf8.decoder)
              .transform(const LineSplitter())) {
        if (chunk.isEmpty) continue;

        if (chunk.startsWith('data: ')) {
          final data = chunk.substring(6);
          if (data == '[DONE]') break;

          try {
            final json = jsonDecode(data);
            final type = json['type'];
            final content = json['content'];

            if (type == 'intent') {
              yield StreamResult(intent: content['intent']);
            } else if (type == 'text') {
              yield StreamResult(text: content);
            } else if (type == 'status' || type == 'thought') {
              yield StreamResult(status: content);
            } else if (type == 'tool_call') {
              yield StreamResult(toolCall: content);
            } else if (type == 'object') {
              yield StreamResult(metadata: {'type': 'object', 'content': content});
            } else if (type == 'final') {
              yield StreamResult(metadata: json);
            } else if (type == 'error') {
              yield StreamResult(error: json['message'] ?? content);
            }
          } catch (e) {
            // Ignore parse errors for partial chunks
          }
        }
      }
    } catch (e) {
      yield StreamResult(error: e.toString());
    }
  }

  Stream<StreamResult> streamResume({
    required String sessionId,
    required dynamic response,
    required String userId,
    String? token,
  }) async* {
    final url = Uri.parse(ApiConfig.getFullUrl(ApiConfig.chatResumeEndpoint));

    final request = http.Request('POST', url);
    request.headers.addAll({
      'Content-Type': 'application/json',
      'Accept': 'text/event-stream',
      if (token != null) 'Authorization': 'Bearer $token',
    });
    request.body = jsonEncode({'session_id': sessionId, 'response': response});

    try {
      final res = await _client.send(request);

      if (res.statusCode != 200) {
        yield StreamResult(error: 'Failed to resume: ${res.statusCode}');
        return;
      }

      await for (final chunk
          in res.stream
              .transform(utf8.decoder)
              .transform(const LineSplitter())) {
        if (chunk.isEmpty) continue;

        if (chunk.startsWith('data: ')) {
          final data = chunk.substring(6);
          if (data == '[DONE]') break;

          try {
            final json = jsonDecode(data);
            final type = json['type'];
            final content = json['content'];

            if (type == 'text') {
              yield StreamResult(text: content);
            } else if (type == 'status') {
              yield StreamResult(status: content);
            } else if (type == 'object') {
              yield StreamResult(metadata: {'type': 'object', 'content': content});
            } else if (type == 'error') {
              yield StreamResult(error: json['message'] ?? content);
            }
          } catch (e) {
            // Ignore parse errors
          }
        }
      }
    } catch (e) {
      yield StreamResult(error: e.toString());
    }
  }

  void dispose() {
    _client.close();
  }
}
