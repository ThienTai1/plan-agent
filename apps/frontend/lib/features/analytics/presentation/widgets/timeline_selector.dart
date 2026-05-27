import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:frontend/features/analytics/presentation/providers/analytics_timeline_provider.dart';

class TimelineSelector extends ConsumerWidget {
  const TimelineSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTimeline = ref.watch(analyticsTimelineProvider);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Row(
          children: AnalyticsTimeline.values.map((timeline) {
            final isSelected = selectedTimeline == timeline;
            return GestureDetector(
              onTap: () => ref
                  .read(analyticsTimelineProvider.notifier)
                  .setTimeline(timeline),
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppPallete.getPrimaryColor(context)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : AppPallete.getBorderColor(context),
                  ),
                ),
                child: Text(
                  timeline.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : AppPallete.getTextSecondary(context),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
