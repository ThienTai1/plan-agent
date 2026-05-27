class DashboardOverview {
  final Map<String, dynamic> goals;
  final Map<String, dynamic> tasks;
  final double completionRate;
  final int strategyScore;
  final String summary;

  DashboardOverview({
    required this.goals,
    required this.tasks,
    required this.completionRate,
    required this.strategyScore,
    required this.summary,
  });

  factory DashboardOverview.fromJson(Map<String, dynamic> json) {
    return DashboardOverview(
      goals: json['goals'] ?? {},
      tasks: json['tasks'] ?? {},
      completionRate: (json['completion_rate'] ?? 0.0).toDouble(),
      strategyScore: json['strategy_score'] ?? 0,
      summary: json['summary'] ?? '',
    );
  }

  factory DashboardOverview.empty() {
    return DashboardOverview(
      goals: {},
      tasks: {},
      completionRate: 0.0,
      strategyScore: 0,
      summary: 'No data available yet.',
    );
  }
}

class TrendDataPoint {
  final String x;
  final double y;

  TrendDataPoint({required this.x, required this.y});

  factory TrendDataPoint.fromJson(Map<String, dynamic> json) {
    return TrendDataPoint(
      x: json['x'] ?? '',
      y: (json['y'] ?? 0.0).toDouble(),
    );
  }
}

class FocusItem {
  final String label;
  final int count;
  final double percentage;

  FocusItem({
    required this.label,
    required this.count,
    required this.percentage,
  });

  factory FocusItem.fromJson(Map<String, dynamic> json) {
    return FocusItem(
      label: json['label'] ?? 'Uncategorized',
      count: json['count'] ?? 0,
      percentage: (json['percentage'] ?? 0.0).toDouble(),
    );
  }
}

class StrategicDashboardData {
  final DashboardOverview overview;
  final List<TrendDataPoint> trend;
  final List<FocusItem> focus;

  StrategicDashboardData({
    required this.overview,
    required this.trend,
    required this.focus,
  });

  factory StrategicDashboardData.fromJson(Map<String, dynamic> json) {
    return StrategicDashboardData(
      overview: DashboardOverview.fromJson(json['overview'] ?? {}),
      trend: (json['trend'] as List? ?? [])
          .map((item) => TrendDataPoint.fromJson(item))
          .toList(),
      focus: (json['focus'] as List? ?? [])
          .map((item) => FocusItem.fromJson(item))
          .toList(),
    );
  }
}
