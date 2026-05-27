import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:frontend/features/chat/presentation/widgets/action_cards.dart';
import 'package:frontend/features/chat/presentation/widgets/charts/bar_chart_view.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Insight Action Card — Simplified overview with a clean performance chart.
class InsightActionCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const InsightActionCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final tasksDone = data['tasks_done'] ?? 0;
    final tasksOverdue = data['tasks_overdue'] ?? 0;
    final tasksOnTrack = data['tasks_on_track'] ?? 0;
    final goalProgress = (data['goal_progress'] as List?) ?? [];
    final warnings = (data['warnings'] as List?) ?? [];

    // Map metrics to simple bar chart data with semantic colors
    final chartData = {
      'series': [
        {
          'data': [
            {'x': 'Done', 'y': tasksDone, 'color': '0xFF22C55E'}, // Green
            {'x': 'Due', 'y': tasksOverdue, 'color': '0xFFEB5757'}, // Red
            {'x': 'Track', 'y': tasksOnTrack, 'color': '0xFF4C8CFF'}, // Blue
          ]
        }
      ]
    };

    return ChatActionCard(
      category: 'Progress Insight',
      title: 'Performance Overview',
      icon: LucideIcons.chart_bar,
      showCategory: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Simplified Performance Chart
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: BarChartView(data: chartData),
          ),
          
          if (goalProgress.isNotEmpty) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'GOALS STATUS',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: AppPallete.getTextMuted(context),
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...goalProgress.map((g) => _buildPremiumGoalItem(context, g as Map<String, dynamic>)),
          ],

          if (warnings.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...warnings.map((w) => _buildInsightBubble(context, w.toString())),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, curve: Curves.easeOut).slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildPremiumGoalItem(BuildContext context, Map<String, dynamic> goal) {
    final title = goal['goal_title'] ?? '';
    final pct = (goal['progress_pct'] ?? 0.0) as double;
    final status = goal['status'] ?? 'on_track';

    Color statusColor = const Color(0xFF10B981); // Green
    String statusText = 'On Track';
    if (status == 'behind') {
      statusColor = const Color(0xFFF59E0B);
      statusText = 'Behind';
    }
    if (status == 'at_risk') {
      statusColor = const Color(0xFFEF4444);
      statusText = 'At Risk';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPallete.getSurfaceContainerLow(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPallete.getBorderColor(context).withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppPallete.getTextPrimary(context),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusText.toUpperCase(),
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: AppPallete.getBorderColor(context).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              FractionallySizedBox(
                widthFactor: pct.clamp(0.01, 1.0),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [statusColor.withValues(alpha: 0.7), statusColor],
                    ),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightBubble(BuildContext context, String text) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.lightbulb, size: 14, color: Color(0xFFF59E0B)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: AppPallete.getTextSecondary(context),
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
