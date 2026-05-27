import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:frontend/features/analytics/presentation/providers/analyst_charts_provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:frontend/features/analytics/presentation/widgets/add_chart_sheet.dart';
import 'package:frontend/features/analytics/presentation/widgets/chart_list_item.dart';
import 'package:frontend/features/analytics/presentation/widgets/consistency_grid.dart';
import 'package:frontend/features/analytics/presentation/widgets/hero_overview.dart';
import 'package:frontend/features/analytics/presentation/widgets/timeline_selector.dart';

class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final charts = ref.watch(analystChartsProvider);

    return Scaffold(
      backgroundColor: AppPallete.getBackgroundColor(context),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(context),
            const TimelineSelector(),
            const HeroOverview(),
            if (charts.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.chart_bar,
                        size: 64,
                        color: AppPallete.getTextSecondary(
                          context,
                        ).withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No charts yet",
                        style: TextStyle(
                          color: AppPallete.getTextSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final chart = charts[index];
                    return ChartListItem(chart: chart);
                  }, childCount: charts.length),
                ),
              ),
            const SliverToBoxAdapter(child: ConsistencyGrid()),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddChartDialog(context),
        backgroundColor: AppPallete.getPrimaryColor(context),
        child: const Icon(LucideIcons.plus),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      backgroundColor: AppPallete.getBackgroundColor(context).withValues(alpha: 0.9),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: Text(
        'Insights',
        style: GoogleFonts.jetBrainsMono(
          color: AppPallete.getTextPrimary(context),
          fontWeight: FontWeight.w800,
          fontSize: 28,
          letterSpacing: -1.0,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(LucideIcons.share, size: 20),
        ),
        const SizedBox(width: 8),
      ],
      centerTitle: false,
    );
  }

  void _showAddChartDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddChartSheet(),
    );
  }
}
