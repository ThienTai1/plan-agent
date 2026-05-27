import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/common/widgets/app_card.dart';
import 'package:frontend/core/common/widgets/app_section_header.dart';
import 'package:frontend/core/common/widgets/app_scaffold.dart';
import 'package:frontend/core/database/local_queries_providers.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:frontend/features/goals/presentation/pages/goals_list_page.dart';
import 'package:frontend/features/home/presentation/providers/home_navigation_provider.dart';

class HomeMinimalView extends ConsumerWidget {
  const HomeMinimalView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final todayTasksAsync = ref.watch(todayPendingTasksProvider);
    final upcomingEventsAsync = ref.watch(upcomingEventsProvider);
    final activeGoalsAsync = ref.watch(activeGoalsProvider);

    return AppScaffold(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      body: ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 100),
        children: [
          Text(
            'Dashboard',
            style: GoogleFonts.jetBrainsMono(
              fontSize: AppFontSizes.sectionTitle,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: AppPallete.getTextPrimary(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            MaterialLocalizations.of(context).formatFullDate(now),
            style: GoogleFonts.jetBrainsMono(
              fontSize: AppFontSizes.label,
              fontWeight: FontWeight.w500,
              color: AppPallete.getTextSecondary(context),
            ),
          ),
          const SizedBox(height: 18),
          const AppSectionHeader(title: 'Today'),
          const SizedBox(height: 10),
          todayTasksAsync.when(
            data: (todayTasks) => AppCard(
              onTap: () =>
                  ref.read(homeNavigationProvider.notifier).setIndex(0),
              child: Row(
                children: [
                  _Metric(label: 'Tasks', value: '${todayTasks.length}'),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      todayTasks.isEmpty
                          ? 'Nothing scheduled. Keep it light.'
                          : 'Next: ${todayTasks.first['title']}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        color: AppPallete.getTextPrimary(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.chevron_right,
                    color: AppPallete.getTextMuted(context),
                  ),
                ],
              ),
            ),
            loading: () => const AppCard(child: SizedBox(height: 52)),
            error: (err, _) => AppCard(
              child: Text(
                'Could not load today.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppPallete.getTextSecondary(context),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const AppSectionHeader(title: 'Next up'),
          const SizedBox(height: 10),
          upcomingEventsAsync.when(
            data: (events) {
              final nextEvent = events.isNotEmpty ? events.first : null;
              return AppCard(
                onTap: () =>
                    ref.read(homeNavigationProvider.notifier).setIndex(0),
                child: nextEvent == null
                    ? Text(
                        'No upcoming events.',
                        style: TextStyle(
                          fontSize: AppFontSizes.label, // Was 13 -> 14
                          fontWeight: FontWeight.w600,
                          color: AppPallete.getTextSecondary(context),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nextEvent['title'] as String? ?? 'Event',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: AppFontSizes.bodyDefault,
                              fontWeight: FontWeight.w700,
                              color: AppPallete.getTextPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatTimeRange(
                              context,
                              DateTime.parse(nextEvent['start_time'] as String),
                              DateTime.parse(nextEvent['end_time'] as String),
                            ),
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: AppFontSizes.label,
                              fontWeight: FontWeight.w600,
                              color: AppPallete.getTextSecondary(context),
                            ),
                          ),
                        ],
                      ),
              );
            },
            loading: () => const AppCard(child: SizedBox(height: 60)),
            error: (err, _) => AppCard(
              child: Text(
                'Could not load upcoming events.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppPallete.getTextSecondary(context),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          AppSectionHeader(
            title: 'Goals',
            actionLabel: 'See all',
            onAction: () =>
                Navigator.pushNamed(context, GoalsListPage.routeName),
          ),
          const SizedBox(height: 10),
          activeGoalsAsync.when(
            data: (activeGoals) => AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _Metric(label: 'Active', value: '${activeGoals.length}'),
                    ],
                  ),
                  if (activeGoals.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ...activeGoals
                        .take(3)
                        .map(
                          (g) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              '• ${g['title']}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: AppFontSizes.label, // Was 13 -> 14
                                fontWeight: FontWeight.w600,
                                color: AppPallete.getTextPrimary(context),
                              ),
                            ),
                          ),
                        ),
                  ] else ...[
                    const SizedBox(height: 12),
                    Text(
                      'Create your first goal to start tracking progress.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppPallete.getTextSecondary(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            loading: () => const AppCard(child: SizedBox(height: 90)),
            error: (err, _) => AppCard(
              child: Text(
                'Could not load goals.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppPallete.getTextSecondary(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppPallete.getSecondarySurface(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppPallete.getTextPrimary(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: AppFontSizes.caption, // Was 11 -> 12
              fontWeight: FontWeight.w600,
              color: AppPallete.getTextSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatTimeRange(BuildContext context, DateTime start, DateTime end) {
  final localizations = MaterialLocalizations.of(context);
  final startLabel = localizations.formatTimeOfDay(
    TimeOfDay.fromDateTime(start),
  );
  final endLabel = localizations.formatTimeOfDay(TimeOfDay.fromDateTime(end));
  return '$startLabel → $endLabel';
}
