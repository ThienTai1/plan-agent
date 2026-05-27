import 'package:flutter/foundation.dart';
import '../secrets/app_secrets.dart';

class ApiConfig {
  // Update this to match your gateway URL
  // Use 10.0.2.2 for Android Emulator, localhost for iOS Simulator/Web/Desktop
  static String get baseUrl {
    if (kReleaseMode) {
      // TODO: Replace with your actual Cloud Run URL after first deployment
      return 'https://agent-orchestrator-45530606279.asia-southeast1.run.app';
    }
    if (kIsWeb) return 'http://localhost:8100';
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:8100'
        : 'http://localhost:8100';
  }
  // Supabase URL is loaded from AppSecrets to avoid hardcoding private info
  static const String supabaseUrl = AppSecrets.supabaseUrl;

  // Auth endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String meEndpoint = '/auth/me';

  // Agent endpoints
  static const String planEndpoint = '/v1/agent/plan';
  static const String chatEndpoint = '/v1/agent/chat';
  static const String chatV3Endpoint = '/v1/agent/v4/chat';
  static const String chatStreamEndpoint = '/v1/agent/v4/chat/stream';
  static const String chatSessionTitleEndpoint = '/v1/agent/v4/chat/session-title';
  static const String chatQuotaEndpoint = '/v1/agent/quota-status';
  static const String actionExecuteEndpoint = '/v1/agent/action/execute';
  static const String actionExecuteBundleEndpoint =
      '/v1/agent/action/execute-bundle';
  static const String chatResumeEndpoint = '/v1/agent/v4/chat/resume';
  static const String dashboardAnalyticsEndpoint = '/v1/agent/analytics/dashboard';

  // Calendar endpoints
  static const String eventsEndpoint = '/users';

  // Goals endpoints
  static const String goalsEndpoint = '/goals';
  static const String phasesEndpoint = '/phases';
  static const String tasksEndpoint = '/tasks';

  static String getFullUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }

  static String getWsUrl(String path) {
    final wsBase = baseUrl.replaceFirst('http', 'ws');
    return '$wsBase$path';
  }
}
