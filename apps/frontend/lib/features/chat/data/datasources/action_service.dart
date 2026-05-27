import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/config/api_config.dart';

class ActionService {
  Future<Map<String, dynamic>> executeAction({
    required String action,
    required Map<String, dynamic> data,
    String? token,
  }) async {
    final url = Uri.parse(
      ApiConfig.getFullUrl(ApiConfig.actionExecuteEndpoint),
    );

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'action': action, 'data': data}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  /// Execute a bundle of actions (from V3 LangGraph agent)
  Future<Map<String, dynamic>> executeBundleAction({
    required List<Map<String, dynamic>> actions,
    String? token,
  }) async {
    final url = Uri.parse(
      ApiConfig.getFullUrl(ApiConfig.actionExecuteBundleEndpoint),
    );

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'actions': actions
              .map(
                (a) => {'action': a['type'] ?? a['action'], 'data': a['data']},
              )
              .toList(),
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        return {
          'status': 'error',
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  /// Resume an interrupted agent workflow (Human-in-the-Loop)
  Future<Map<String, dynamic>> resumeAction({
    required String sessionId,
    required String userId,
    required dynamic response, // User feedback or confirmation
    String? token,
  }) async {
    final url = Uri.parse(
      ApiConfig.getFullUrl(ApiConfig.chatResumeEndpoint),
    );

    try {
      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'session_id': sessionId,
          'response': response,
        }),
      );

      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes));
      } else {
        return {
          'status': 'error',
          'message': 'Server error: ${res.statusCode}',
        };
      }
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }
}
