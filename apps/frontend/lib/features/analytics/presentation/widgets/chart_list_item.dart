import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:frontend/features/analytics/domain/models/analyst_chart.dart';
import 'package:frontend/features/analytics/presentation/providers/analyst_charts_provider.dart';
import 'package:frontend/features/analytics/presentation/widgets/add_chart_sheet.dart';
import 'package:google_fonts/google_fonts.dart';

class ChartListItem extends ConsumerWidget {
  final AnalystChart chart;

  const ChartListItem({super.key, required this.chart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastValue = chart.data.isNotEmpty ? chart.data.last.value : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppPallete.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppPallete.getBorderColor(context).withValues(alpha: 0.1),
        ),
        boxShadow: AppPallete.getDynamicSoftShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chart.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppPallete.getTextSecondary(context),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        lastValue.toStringAsFixed(
                          lastValue == lastValue.toInt() ? 0 : 1,
                        ),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppPallete.getTextPrimary(context),
                          letterSpacing: -1.5,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getMetricUnit(chart.metricType),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppPallete.getTextSecondary(
                            context,
                          ).withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  _buildPinButton(context, ref),
                  _buildActionButton(
                    icon: LucideIcons.pencil,
                    color: AppPallete.getTextSecondary(context),
                    onPressed: () => _showEditChartDialog(context, ref),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildChartPreview(context),
        ],
      ),
    );
  }

  String _getMetricUnit(ChartMetricType type) {
    switch (type) {
      case ChartMetricType.taskCompletion:
        return "%";
      case ChartMetricType.goalProgress:
        return "%";
      case ChartMetricType.focusHours:
        return "hrs";
      case ChartMetricType.projectDistribution:
        return "rel";
      case ChartMetricType.custom:
        return chart.customPropertyName ?? "val";
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, color: color, size: 20),
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
    );
  }

  void _showEditChartDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddChartSheet(chart: chart),
    );
  }

  Widget _buildPinButton(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: Icon(
        chart.isPinned ? LucideIcons.pin_off : LucideIcons.pin,
        color: chart.isPinned
            ? AppPallete.getPrimaryColor(context)
            : AppPallete.getTextSecondary(context),
        size: 20,
      ),
      onPressed: () {
        ref.read(analystChartsProvider.notifier).togglePin(chart.id);
      },
    );
  }

  Widget _buildChartPreview(BuildContext context) {
    switch (chart.type) {
      case ChartType.line:
        return _buildLineChart();
      case ChartType.bar:
        return _buildBarChart();
      case ChartType.pie:
        return _buildPieChart();
    }
  }

  Widget _buildLineChart() {
    return SizedBox(
      height: 120,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: chart.data
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value.value))
                  .toList(),
              isCurved: true,
              color: chart.colors.first,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  if (index != barData.spots.length - 1) {
                    return FlDotCirclePainter(radius: 0);
                  }
                  return FlDotCirclePainter(
                    radius: 5,
                    color: chart.colors.first,
                    strokeWidth: 3,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    chart.colors.first.withValues(alpha: 0.2),
                    chart.colors.first.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    return SizedBox(
      height: 120,
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: chart.data.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.value,
                  color: chart.colors.first,
                  width: 16,
                  borderRadius: BorderRadius.circular(8),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: 100,
                    color: chart.colors.first.withValues(alpha: 0.08),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    return SizedBox(
      height: 120,
      child: PieChart(
        PieChartData(
          sectionsSpace: 4,
          centerSpaceRadius: 44,
          sections: chart.data.asMap().entries.map((e) {
            final dp = e.value;
            final index = e.key;
            return PieChartSectionData(
              color: chart.colors.first.withValues(
                alpha: 0.2 + (index * 0.1).clamp(0.0, 0.7),
              ),
              value: dp.value,
              title: '',
              radius: 12,
            );
          }).toList(),
        ),
      ),
    );
  }
}
