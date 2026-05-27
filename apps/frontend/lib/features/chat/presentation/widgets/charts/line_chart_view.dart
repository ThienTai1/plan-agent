import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Standard Line/Area Chart View rendered from dynamic chart data.
class LineChartView extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isArea;

  const LineChartView({super.key, required this.data, this.isArea = false});

  @override
  Widget build(BuildContext context) {
    final series = (data['series'] as List?) ?? [];
    if (series.isEmpty) return const Center(child: Text('No data'));

    final firstPoints = ((series[0] as Map<String, dynamic>)['data'] as List?) ?? [];

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppPallete.getBorderColor(context).withValues(alpha: 0.1),
              strokeWidth: 1,
            ),
          ),
          titlesData: _buildTitlesData(firstPoints, context),
          borderData: FlBorderData(show: false),
          lineBarsData: series.asMap().entries.map((entry) {
            final s = entry.value as Map<String, dynamic>;
            final points = (s['data'] as List?) ?? [];
            return LineChartBarData(
              spots: points.asMap().entries.map((e) {
                final point = e.value as Map<String, dynamic>;
                return FlSpot(
                  e.key.toDouble(),
                  (point['y'] as num? ?? 0).toDouble(),
                );
              }).toList(),
              isCurved: true,
              curveSmoothness: 0.35,
              color: const Color(0xFF4C8CFF), // Soft blue from reference
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 3,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: const Color(0xFF4C8CFF),
                ),
              ),
              belowBarData: BarAreaData(
                show: isArea,
                color: const Color(0xFF4C8CFF).withValues(alpha: 0.1),
              ),
            );
          }).toList(),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideX(begin: 0.05, end: 0, curve: Curves.easeOutCubic);
  }

  FlTitlesData _buildTitlesData(List points, BuildContext context) {
    final textStyle = GoogleFonts.jetBrainsMono(
      fontSize: 9,
      color: AppPallete.getTextMuted(context).withValues(alpha: 0.6),
    );

    return FlTitlesData(
      show: true,
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 22,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index >= 0 && index < points.length) {
              final point = points[index] as Map<String, dynamic>;
              final label = point['x']?.toString() ?? '';
              // Hide purely numeric labels on bottom
              if (double.tryParse(label) != null) return const Text('');

              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  label.length > 5 ? label.substring(0, 3) : label,
                  style: textStyle,
                ),
              );
            }
            return const Text('');
          },
        ),
      ),
      rightTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 32,
          getTitlesWidget: (value, meta) {
            if (value % 5 != 0) return const Text(''); // Show every 5 units for clarity
            return Text(
              value.toInt().toString(),
              style: textStyle,
              textAlign: TextAlign.left,
            );
          },
        ),
      ),
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }
}


