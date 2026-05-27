import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/features/analytics/data/repositories/analytics_repository_impl.dart';
import 'package:frontend/features/analytics/domain/models/dashboard_stats.dart';
import 'package:frontend/features/analytics/domain/repositories/analytics_repository.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepositoryImpl(Supabase.instance.client);
});

final dashboardDataProvider = FutureProvider<StrategicDashboardData>((ref) async {
  final repository = ref.watch(analyticsRepositoryProvider);
  final result = await repository.getDashboardData();
  
  return result.fold(
    (failure) => throw Exception(failure.message),
    (data) => data,
  );
});
