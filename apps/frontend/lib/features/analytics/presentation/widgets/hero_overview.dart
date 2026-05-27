import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:frontend/features/analytics/presentation/providers/hero_overview_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class HeroOverview extends ConsumerWidget {
  const HeroOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(heroOverviewProvider);
    final metrics = metricsAsync.value ?? HeroMetrics.initial();
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              metrics.label,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: AppPallete.getTextSecondary(context).withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  metrics.tasksCompleted.toString(),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    color: AppPallete.getTextPrimary(context),
                    letterSpacing: -2,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    "Tasks Done",
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppPallete.getTextSecondary(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  metrics.isPositiveTrend
                      ? LucideIcons.trending_up
                      : LucideIcons.trending_down,
                  size: 14,
                  color: metrics.isPositiveTrend
                      ? Colors.green.shade400
                      : Colors.red.shade400,
                ),
                const SizedBox(width: 4),
                Text(
                  "\b${metrics.percentageChange}% from previous period",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: metrics.isPositiveTrend
                        ? Colors.green.shade400
                        : Colors.red.shade400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                _buildMiniStat(context, "Avg. Focus", "4.8h", LucideIcons.zap),
                const SizedBox(width: 16),
                _buildMiniStat(
                  context,
                  "Consistency",
                  "${metrics.consistencyPercent.toStringAsFixed(0)}%",
                  LucideIcons.target,
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppPallete.getCardColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppPallete.getBorderColor(context).withValues(alpha: 0.8),
          ),
          boxShadow: AppPallete.getDynamicSoftShadow(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: AppPallete.getPrimaryColor(context)),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppPallete.getTextPrimary(context),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppPallete.getTextSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
