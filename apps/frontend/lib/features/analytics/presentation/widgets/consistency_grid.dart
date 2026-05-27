import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:frontend/features/analytics/presentation/providers/consistency_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class ConsistencyGrid extends ConsumerWidget {
  const ConsistencyGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consistencyAsync = ref.watch(consistencyProvider);
    final data = consistencyAsync.value ?? ConsistencyData.initial();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "ACTIVITY CONSISTENCY",
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: AppPallete.getTextSecondary(context).withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppPallete.getCardColor(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppPallete.getBorderColor(context).withValues(alpha: 0.1),
              ),
              boxShadow: AppPallete.getDynamicSoftShadow(context),
            ),
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(24, (weekIndex) {
                      return Column(
                        children: List.generate(7, (dayIndex) {
                          // Calculate the date for this tile
                          final dayOffset = (weekIndex * 7) + dayIndex;
                          final date = data.startDate.add(
                            Duration(days: dayOffset),
                          );

                          // Don't show future dates
                          if (date.isAfter(data.endDate)) {
                            return const SizedBox(width: 14, height: 14);
                          }

                          // Get completion count for this day
                          final count =
                              data.completionsOut[DateTime(
                                date.year,
                                date.month,
                                date.day,
                              )] ??
                              0;

                          // Determine opacity (max 1.0)
                          final double opacity = count == 0
                              ? 0.1
                              : (0.3 + (count * 0.2)).clamp(0.0, 1.0);

                          return Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: AppPallete.getPrimaryColor(
                                context,
                              ).withValues(alpha: opacity),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Last 6 months",
                      style: TextStyle(
                        fontSize: 10,
                        color: AppPallete.getTextSecondary(context),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          "Less",
                          style: TextStyle(
                            fontSize: 10,
                            color: AppPallete.getTextSecondary(context),
                          ),
                        ),
                        const SizedBox(width: 4),
                        ...List.generate(
                          4,
                          (i) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 2),
                            decoration: BoxDecoration(
                              color: AppPallete.getPrimaryColor(
                                context,
                              ).withValues(alpha: 0.1 + (i * 0.2)),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "More",
                          style: TextStyle(
                            fontSize: 10,
                            color: AppPallete.getTextSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
