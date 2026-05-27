import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';


/// Standard Bar Chart View rendered from dynamic chart data.
class BarChartView extends StatelessWidget {
  final Map<String, dynamic> data;

  const BarChartView({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final series = (data['series'] as List?) ?? [];
    if (series.isEmpty) return const Center(child: Text('No data'));

    final firstSeries = series[0] as Map<String, dynamic>;
    final points = (firstSeries['data'] as List?) ?? [];

    final colors = [
      const Color(0xFF4C8CFF), // Primary blue
      const Color(0xFF00B4D8),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
    ];

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: AppPallete.getBorderColor(context).withValues(alpha: 0.1),
              strokeWidth: 1,
            ),
          ),
          titlesData: _buildTitlesData(points, context),
          borderData: FlBorderData(show: false),
          barGroups: points.asMap().entries.map((e) {
            final index = e.key;
            final point = e.value as Map<String, dynamic>;
            
            final colorValue = point['color'];
            final barColor = colorValue != null 
                ? Color(int.parse(colorValue.toString().replaceAll('#', '0xFF')))
                : colors[index % colors.length];

            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: (point['y'] as num? ?? 0).toDouble(),
                  color: barColor,
                  width: 12,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
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
             if (value % 5 != 0) return const Text('');
             return Text(
               value.toInt().toString(),
               style: textStyle,
             );
          },
        ),
      ),
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }
}


