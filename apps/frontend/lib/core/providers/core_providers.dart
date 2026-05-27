import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:frontend/features/auth/data/datasources/api_service.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});
