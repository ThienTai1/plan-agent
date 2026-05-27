import 'dart:convert';
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/core/config/api_config.dart';
import 'package:frontend/core/error/failures.dart';
import 'package:frontend/features/analytics/domain/models/dashboard_stats.dart';
import 'package:frontend/features/analytics/domain/repositories/analytics_repository.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final SupabaseClient _supabase;

  AnalyticsRepositoryImpl(this._supabase);

  @override
  Future<Either<Failure, StrategicDashboardData>> getDashboardData() async {
    try {
      final token = _supabase.auth.currentSession?.accessToken;
      
      final response = await http.get(
        Uri.parse(ApiConfig.getFullUrl(ApiConfig.dashboardAnalyticsEndpoint)),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Right(StrategicDashboardData.fromJson(data));
      } else {
        return Left(ServerFailure('Failed to fetch dashboard data: ${response.statusCode}'));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TrendDataPoint>>> getTrendData({int days = 14}) async {
    try {
      final token = _supabase.auth.currentSession?.accessToken;
      
      final response = await http.get(
        Uri.parse('${ApiConfig.getFullUrl('/v1/agent/analytics/trend')}?days=$days'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['trend'] as List? ?? [])
            .map((item) => TrendDataPoint.fromJson(item))
            .toList();
        return Right(list);
      } else {
        return Left(ServerFailure('Failed to fetch trend data: ${response.statusCode}'));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
