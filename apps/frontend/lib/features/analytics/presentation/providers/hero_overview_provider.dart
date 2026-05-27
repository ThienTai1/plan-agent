import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/common/domain/models/task.dart';
import 'package:frontend/features/goals/presentation/providers/goals_providers.dart';
import 'package:frontend/features/analytics/presentation/providers/analytics_timeline_provider.dart';

class HeroMetrics {
  final int tasksCompleted;
  final double consistencyPercent;
  final int percentageChange;
  final bool isPositiveTrend;
  final String label;

  HeroMetrics({
    required this.tasksCompleted,
    required this.consistencyPercent,
    required this.percentageChange,
    required this.isPositiveTrend,
    required this.label,
  });

  factory HeroMetrics.initial() => HeroMetrics(
    tasksCompleted: 0,
    consistencyPercent: 0,
    percentageChange: 0,
    isPositiveTrend: true,
    label: "THIS WEEK",
  );
}

final heroOverviewProvider = Provider<AsyncValue<HeroMetrics>>((ref) {
  final timeline = ref.watch(analyticsTimelineProvider);
  final allTasksAsync = ref.watch(allTasksProvider);

  return allTasksAsync.whenData((tasks) {
    return _calculateMetrics(tasks, timeline);
  });
});

HeroMetrics _calculateMetrics(List<Task> tasks, AnalyticsTimeline timeline) {
  final now = DateTime.now();
  final periodStart = now.subtract(Duration(days: timeline.days));
  final previousPeriodStart = periodStart.subtract(
    Duration(days: timeline.days),
  );

  // Current period tasks
  final currentTasks = tasks
      .where(
        (t) =>
            t.isCompleted &&
            t.updatedAt.isAfter(periodStart) &&
            t.updatedAt.isBefore(now),
      )
      .toList();

  // Previous period tasks
  final previousTasks = tasks
      .where(
        (t) =>
            t.isCompleted &&
            t.updatedAt.isAfter(previousPeriodStart) &&
            t.updatedAt.isBefore(periodStart),
      )
      .toList();

  final currentCount = currentTasks.length;
  final previousCount = previousTasks.length;

  int percentageChange = 0;
  if (previousCount > 0) {
    percentageChange = ((currentCount - previousCount) / previousCount * 100)
        .round();
  } else if (currentCount > 0) {
    percentageChange = 100; // 100% increase if previous was 0
  }

  // Consistency = days with at least 1 completed task / total days in period
  final activeDays = currentTasks
      .map(
        (t) => DateTime(t.updatedAt.year, t.updatedAt.month, t.updatedAt.day),
      )
      .toSet()
      .length;

  // Cap at timeline days, but avoid dividing by 0
  final daysToDivide = timeline.days > 0 ? timeline.days : 1;
  final consistency = (activeDays / daysToDivide) * 100;

  String getLabel() {
    switch (timeline) {
      case AnalyticsTimeline.sevenDays:
        return "THIS WEEK";
      case AnalyticsTimeline.thirtyDays:
        return "THIS MONTH";
      case AnalyticsTimeline.ninetyDays:
        return "THIS QUARTER";
      case AnalyticsTimeline.all:
        return "ALL TIME";
    }
  }

  return HeroMetrics(
    tasksCompleted: currentCount,
    consistencyPercent: consistency.clamp(0, 100).toDouble(),
    percentageChange: percentageChange.abs(),
    isPositiveTrend: percentageChange >= 0,
    label: getLabel(),
  );
}
