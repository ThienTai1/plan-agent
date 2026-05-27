import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Pie Chart View rendered from dynamic chart data.
class PieChartView extends StatelessWidget {
  final Map<String, dynamic> data;

  const PieChartView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final series = (data['series'] as List?) ?? [];
    if (series.isEmpty) return const Center(child: Text('No data'));

    final firstSeries = series[0] as Map<String, dynamic>;
    final points = (firstSeries['data'] as List?) ?? [];

    final colors = [
      AppPallete.getPrimaryColor(context),
      AppPallete.infoColor,
      const Color(0xFF8B5CF6),
      const Color(0xFFF59E0B),
      const Color(0xFF14B8A6),
      const Color(0xFFEF4444),
    ];

    return SizedBox(
      height: 180,
      child: PieChart(
        PieChartData(
          sectionsSpace: 4,
          centerSpaceRadius: 30,
          sections: points.asMap().entries.map((e) {
            final index = e.key;
            final point = e.value as Map<String, dynamic>;
            final value = (point['y'] as num? ?? 0).toDouble();
            final label = point['x']?.toString() ?? '';
            return PieChartSectionData(
              color: colors[index % colors.length],
              value: value,
              title: label.length > 6 ? '${value.toInt()}' : label,
              radius: 40,
              titleStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack);
  }
}
