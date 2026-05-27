import 'package:flutter/material.dart';

enum ChartType { line, bar, pie }

enum ChartMetricType {
  taskCompletion,
  goalProgress,

  focusHours,
  projectDistribution,
  custom,
}

enum AggregationType { sum, average, count }

class AnalystChart {
  final String id;
  final String title;
  final ChartType type;
  final ChartMetricType metricType;
  final List<ChartDataPoint> data;
  final List<Color> colors;
  final bool isPinned;

  // Custom Chart Metadata
  final String? sourceGoalId;
  final String? customPropertyName;
  final AggregationType aggregationType;

  AnalystChart({
    required this.id,
    required this.title,
    required this.type,
    required this.metricType,
    required this.data,
    required this.colors,
    this.isPinned = false,
    this.sourceGoalId,
    this.customPropertyName,
    this.aggregationType = AggregationType.sum,
  });

  AnalystChart copyWith({
    String? title,
    ChartType? type,
    ChartMetricType? metricType,
    List<ChartDataPoint>? data,
    List<Color>? colors,
    bool? isPinned,
    String? sourceGoalId,
    String? customPropertyName,
    AggregationType? aggregationType,
  }) {
    return AnalystChart(
      id: id,
      title: title ?? this.title,
      type: type ?? this.type,
      metricType: metricType ?? this.metricType,
      data: data ?? this.data,
      colors: colors ?? this.colors,
      isPinned: isPinned ?? this.isPinned,
      sourceGoalId: sourceGoalId ?? this.sourceGoalId,
      customPropertyName: customPropertyName ?? this.customPropertyName,
      aggregationType: aggregationType ?? this.aggregationType,
    );
  }
}

class ChartDataPoint {
  final String label;
  final double value;

  ChartDataPoint(this.label, this.value);
}
