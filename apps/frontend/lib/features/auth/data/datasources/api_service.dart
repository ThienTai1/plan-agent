import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/config/api_config.dart';
import 'package:frontend/features/auth/data/models/auth_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

class ApiService {
  final String baseUrl;

  ApiService({String? baseUrl})
      : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  // Auth methods
  Future<TokenResponse> login(LoginRequest request) async {
    final url = Uri.parse(ApiConfig.getFullUrl(ApiConfig.loginEndpoint));
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      return TokenResponse.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Login failed');
    }
  }

  Future<TokenResponse> register(RegisterRequest request) async {
    // Note: Register endpoint might not exist yet, this is a placeholder
    final url = Uri.parse(ApiConfig.getFullUrl(ApiConfig.registerEndpoint));
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return TokenResponse.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Registration failed');
    }
  }

  Future<User> getCurrentUser(String token) async {
    final url = Uri.parse(ApiConfig.getFullUrl(ApiConfig.meEndpoint));
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to get user info');
    }
  }

  Future<bool> verifyGooglePlay(String token, String purchaseToken, String productId) async {
    try {
      // Use Supabase Functions Client to invoke the function (automatically handles JWT and API Key)
      final response = await Supabase.instance.client.functions.invoke(
        'verify-google-play',
        body: {
          'purchase_token': purchaseToken,
          'product_id': productId,
          'package_name': 'com.levigo.agent',
        },
      );

      return response.status == 200;
    } catch (e) {
      print('[ApiService] verifyGooglePlay error: $e');
      return false;
    }
  }

  // Calendar methods
  Future<List<CalendarEvent>> getEvents(String token, {int limit = 10}) async {
    // This endpoint might need user_id, adjust as needed
    final url = Uri.parse(
      '${ApiConfig.getFullUrl(ApiConfig.eventsEndpoint)}/me/events?limit=$limit',
    );
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final items = data['items'] as List<dynamic>;
      return items.map((item) => CalendarEvent.fromJson(item)).toList();
    } else {
      return [];
    }
  }
}

class CalendarEvent {
  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final String? description;
  final String? location;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    this.description,
    this.location,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
      description: json['description'] as String?,
      location: json['location'] as String?,
    );
  }
}
