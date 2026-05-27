import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:frontend/features/chat/presentation/widgets/charts/heatmap_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/analytics/domain/models/dashboard_stats.dart';
import 'package:frontend/features/analytics/presentation/providers/dashboard_provider.dart';

class DashboardPage extends ConsumerWidget {
  static const String routeName = '/dashboard';

  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardDataProvider);

    return Scaffold(
      backgroundColor: AppPallete.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Strategic Dashboard',
          style: TextStyle(
            color: AppPallete.getTextPrimary(context),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, 
            color: AppPallete.getTextPrimary(context), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.rotate_cw, size: 20, color: AppPallete.getTextSecondary(context)),
            onPressed: () => ref.refresh(dashboardDataProvider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: dashboardAsync.when(
        data: (data) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 32),
              _buildScoreSection(context, data.overview),
              const SizedBox(height: 32),
              _buildSectionTitle(context, 'Activity Trend'),
              const SizedBox(height: 16),
              _buildLineChart(context, data.trend),
              const SizedBox(height: 32),
              _buildSectionTitle(context, 'Focus Distribution'),
              const SizedBox(height: 16),
              _buildPieChart(context, data.focus),
              const SizedBox(height: 32),
              _buildSectionTitle(context, 'Goal Health'),
              const SizedBox(height: 16),
              _buildHealthGrid(context, data.overview),
              const SizedBox(height: 32),
              _buildSectionTitle(context, 'Commitment Heatmap'),
              const SizedBox(height: 16),
              _buildHeatmap(context, data.trend),
              const SizedBox(height: 48),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('Failed to load dashboard', style: TextStyle(color: AppPallete.getTextPrimary(context))),
              TextButton(onPressed: () => ref.refresh(dashboardDataProvider), child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analysis',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppPallete.getTextPrimary(context),
            letterSpacing: -1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Detailed look at your productivity and goal progress.',
          style: TextStyle(
            fontSize: 14,
            color: AppPallete.getTextSecondary(context),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreSection(BuildContext context, DashboardOverview overview) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppPallete.getCardColor(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppPallete.getDynamicCardShadow(context),
        border: Border.all(
          color: AppPallete.getBorderColor(context).withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Strategy Score',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppPallete.getTextSecondary(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${overview.strategyScore}/100',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: AppPallete.getPrimaryColor(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  overview.summary,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppPallete.getTextSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              value: overview.completionRate,
              strokeWidth: 10,
              backgroundColor: AppPallete.getPrimaryColor(context).withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(AppPallete.getPrimaryColor(context)),
              strokeCap: StrokeCap.round,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppPallete.getTextPrimary(context),
      ),
    );
  }

  Widget _buildLineChart(BuildContext context, List<TrendDataPoint> trend) {
    if (trend.isEmpty) {
      return const SizedBox(height: 100, child: Center(child: Text('No activity yet')));
    }

    // Map trend to sports
    final spots = <FlSpot>[];
    for (int i = 0; i < trend.length; i++) {
      spots.add(FlSpot(i.toDouble(), trend[i].y));
    }

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(16, 32, 24, 16),
      decoration: BoxDecoration(
        color: AppPallete.getCardColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppPallete.getBorderColor(context).withValues(alpha: 0.1),
        ),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= trend.length || trend.length < 5) return const Text('');
                  
                  // Only show dates for start, end, and middle to avoid clutter
                  if (idx == 0 || idx == trend.length - 1 || idx == (trend.length / 2).floor()) {
                    final date = DateTime.parse(trend[idx].x);
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '${date.day}/${date.month}',
                        style: TextStyle(color: AppPallete.getTextSecondary(context), fontSize: 10),
                      ),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 22,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (trend.length - 1).toDouble(),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppPallete.getPrimaryColor(context),
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppPallete.getPrimaryColor(context).withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(BuildContext context, List<FocusItem> focus) {
    if (focus.isEmpty) {
      return const SizedBox(height: 100, child: Center(child: Text('No goals categorized yet')));
    }

    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.green,
      Colors.orange,
      Colors.pink,
      Colors.cyan
    ];

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPallete.getCardColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppPallete.getBorderColor(context).withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 35,
                sections: List.generate(focus.length, (i) {
                  return PieChartSectionData(
                    color: colors[i % colors.length],
                    value: focus[i].count.toDouble(),
                    title: '',
                    radius: 20,
                  );
                }),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(focus.length, (i) {
              return _buildLegend(context, focus[i].label, colors[i % colors.length]);
            }),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildLegend(BuildContext context, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(
            label.length > 15 ? '${label.substring(0, 12)}...' : label, 
            style: TextStyle(fontSize: 12, color: AppPallete.getTextPrimary(context), fontWeight: FontWeight.w500)
          ),
        ],
      ),
    );
  }

  Widget _buildHealthGrid(BuildContext context, DashboardOverview overview) {
    final activeGoals = overview.goals['active']?.toString() ?? '0';
    final completionPct = (overview.completionRate * 100).toInt().toString();
    final pendingTasks = overview.tasks['pending']?.toString() ?? '0';
    final totalTasks = overview.tasks['total']?.toString() ?? '0';

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildHealthItem(context, 'Active Goals', activeGoals, LucideIcons.target, Colors.blue),
        _buildHealthItem(context, 'Progress', '$completionPct%', LucideIcons.circle_check, Colors.green),
        _buildHealthItem(context, 'Pending Tasks', pendingTasks, LucideIcons.trending_up, Colors.purple),
        _buildHealthItem(context, 'Total Efforts', totalTasks, LucideIcons.zap, Colors.orange),
      ],
    );
  }

  Widget _buildHealthItem(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPallete.getCardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppPallete.getBorderColor(context).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: AppPallete.getTextSecondary(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppPallete.getTextPrimary(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmap(BuildContext context, List<TrendDataPoint> trend) {
    // derivations: Map 14 days activity to heatmap structure
    final List<Map<String, dynamic>> points = [];
    for (int i = 0; i < trend.length; i++) {
      points.add({
        'x': trend[i].x,
        'y': trend[i].y.toInt(),
      });
    }

    final heatmapData = {
      'config': {
        'options': {
          'columns': trend.length > 7 ? 7 : trend.length,
          'rows': (trend.length / 7).ceil(),
          'color_scale': 'green',
        }
      },
      'series': [
        {'data': points}
      ]
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPallete.getCardColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppPallete.getBorderColor(context).withValues(alpha: 0.1),
        ),
      ),
      child: HeatmapView(data: heatmapData),
    );
  }
}
