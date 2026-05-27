import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/analytics/domain/models/analyst_chart.dart';
import 'package:frontend/features/goals/presentation/providers/goals_providers.dart';

class AnalystChartsNotifier extends Notifier<List<AnalystChart>> {
  @override
  List<AnalystChart> build() {
    // Empty list initially. Users can add custom charts.
    return [];
  }

  Future<void> addChart(AnalystChart chart) async {
    final newData = await _calculateDataPoints(chart);
    state = [...state, chart.copyWith(data: newData)];
  }

  Future<void> updateChart(AnalystChart updatedChart) async {
    final newData = await _calculateDataPoints(updatedChart);
    state = [
      for (final chart in state)
        if (chart.id == updatedChart.id)
          updatedChart.copyWith(data: newData)
        else
          chart,
    ];
  }

  void deleteChart(String id) {
    state = state.where((c) => c.id != id).toList();
  }

  void togglePin(String id) {
    state = [
      for (final chart in state)
        if (chart.id == id)
          chart.copyWith(isPinned: !chart.isPinned)
        else
          chart,
    ];
  }

  Future<List<ChartDataPoint>> _calculateDataPoints(AnalystChart chart) async {
    if (chart.metricType != ChartMetricType.custom) {
      return _generateInitialData(chart.metricType);
    }

    if (chart.sourceGoalId == null || chart.customPropertyName == null) {
      return [];
    }

    final repository = ref.read(goalsRepositoryProvider);
    final res = await repository.getTasksByGoal(chart.sourceGoalId!).first;

    return res.fold((l) => [], (tasks) {
      if (tasks.isEmpty) return [];

      // Simple aggregation by task title for now or status
      // If it's a property-based chart, we aggregate values from customProperties
      final property = chart.customPropertyName!;

      switch (chart.aggregationType) {
        case AggregationType.count:
          return tasks.map((t) => ChartDataPoint(t.title, 1.0)).toList();
        case AggregationType.sum:
        case AggregationType.average:
          final points = tasks.map((t) {
            final val = t.customProperties?[property];
            double numericVal = 0;
            if (val is num) {
              numericVal = val.toDouble();
            } else if (val is String) {
              numericVal = double.tryParse(val) ?? 0;
            }
            return ChartDataPoint(t.title, numericVal);
          }).toList();

          if (chart.aggregationType == AggregationType.average &&
              points.isNotEmpty) {
            // This is a bit complex for a simple data point list if we want a single average value
            // Usually charts show data per item. If they want a single trend, we might need a different grouping.
            // For now, let's just return the values per task.
          }
          return points;
      }
    });
  }

  List<ChartDataPoint> _generateInitialData(ChartMetricType type) {
    switch (type) {
      case ChartMetricType.taskCompletion:
        return [
          ChartDataPoint('Mon', 3),
          ChartDataPoint('Tue', 5),
          ChartDataPoint('Wed', 8),
          ChartDataPoint('Thu', 4),
          ChartDataPoint('Fri', 10),
          ChartDataPoint('Sat', 2),
          ChartDataPoint('Sun', 6),
        ];
      case ChartMetricType.goalProgress:
        return [
          ChartDataPoint('Goal A', 85),
          ChartDataPoint('Goal B', 40),
          ChartDataPoint('Goal C', 15),
          ChartDataPoint('Goal D', 65),
        ];

      case ChartMetricType.focusHours:
        return [
          ChartDataPoint('09:00', 1.5),
          ChartDataPoint('11:00', 2.0),
          ChartDataPoint('14:00', 3.0),
          ChartDataPoint('16:00', 1.0),
        ];
      case ChartMetricType.projectDistribution:
        return [
          ChartDataPoint('App Design', 35),
          ChartDataPoint('Refactoring', 25),
          ChartDataPoint('Testing', 15),
          ChartDataPoint('Documentation', 25),
        ];
      case ChartMetricType.custom:
        return [
          ChartDataPoint('Week 1', 20),
          ChartDataPoint('Week 2', 45),
          ChartDataPoint('Week 3', 30),
          ChartDataPoint('Week 4', 55),
        ];
    }
  }
}

final analystChartsProvider =
    NotifierProvider<AnalystChartsNotifier, List<AnalystChart>>(
      AnalystChartsNotifier.new,
    );
