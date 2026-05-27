import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/goals/presentation/providers/goals_providers.dart';

class ConsistencyData {
  // Map of days to number of tasks completed on that day
  final Map<DateTime, int> completionsOut;
  final DateTime startDate;
  final DateTime endDate;

  ConsistencyData({
    required this.completionsOut,
    required this.startDate,
    required this.endDate,
  });

  factory ConsistencyData.initial() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // 6 months approximation (24 weeks * 7 days = 168 days)
    final start = today.subtract(const Duration(days: 168));
    return ConsistencyData(
      completionsOut: {},
      startDate: start,
      endDate: today,
    );
  }
}

final consistencyProvider = Provider<AsyncValue<ConsistencyData>>((ref) {
  final allTasksAsync = ref.watch(allTasksProvider);

  return allTasksAsync.whenData((tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final limitDate = today.subtract(const Duration(days: 168));

    final Map<DateTime, int> map = {};

    for (final task in tasks) {
      if (task.isCompleted && task.updatedAt.isAfter(limitDate)) {
        final dateKey = DateTime(
          task.updatedAt.year,
          task.updatedAt.month,
          task.updatedAt.day,
        );
        map[dateKey] = (map[dateKey] ?? 0) + 1;
      }
    }

    return ConsistencyData(
      completionsOut: map,
      startDate: limitDate,
      endDate: today,
    );
  });
});
