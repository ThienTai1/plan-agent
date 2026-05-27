import 'package:fpdart/fpdart.dart';
import 'package:frontend/core/error/failures.dart';
import 'package:frontend/features/analytics/domain/models/dashboard_stats.dart';

abstract class AnalyticsRepository {
  Future<Either<Failure, StrategicDashboardData>> getDashboardData();
  Future<Either<Failure, List<TrendDataPoint>>> getTrendData({int days = 14});
}
