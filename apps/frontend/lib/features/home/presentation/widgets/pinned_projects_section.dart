import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/database/local_queries_providers.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:frontend/features/goals/data/models/goal_model.dart';
import 'package:frontend/features/goals/presentation/pages/goal_detail_page.dart';
import 'package:frontend/features/home/presentation/widgets/project_card.dart';

class PinnedProjectsSection extends ConsumerWidget {
  final VoidCallback? onSeeAllTap;
  final ValueChanged<Map<String, dynamic>>? onGoalTap;

  const PinnedProjectsSection({super.key, this.onSeeAllTap, this.onGoalTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(allGoalsProvider);

    return goalsAsync.when(
      data: (goals) {
        if (goals.isEmpty) {
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Goals',
                        style: TextStyle(
                          fontSize: AppFontSizes.bodyLarge, // Was 14 -> 18
                          fontWeight: FontWeight.w700,
                          color: AppPallete.getTextPrimary(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppPallete.getCardColor(context),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppPallete.getBorderColor(
                              context,
                            ).withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          '0',
                          style: TextStyle(
                            fontSize: AppFontSizes.label,
                            fontWeight: FontWeight.bold,
                            color: AppPallete.getTextPrimary(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (onSeeAllTap != null)
                    TextButton(
                      onPressed: onSeeAllTap,
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'See all',
                            style: TextStyle(
                              fontSize: AppFontSizes.label,
                              fontWeight: FontWeight.w600,
                              color: AppPallete.getTextSecondary(context),
                            ),
                          ),
                          const Icon(Icons.chevron_right, size: 14),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: onSeeAllTap,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppPallete.getCardColor(context).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppPallete.getBorderColor(
                        context,
                      ).withValues(alpha: 0.4),
                      style: BorderStyle.solid,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppPallete.getSecondarySurface(context),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          size: 24,
                          color: AppPallete.getTextSecondary(context),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No goals set',
                            style: TextStyle(
                              fontSize: AppFontSizes.bodyDefault,
                              fontWeight: FontWeight.w700,
                              color: AppPallete.getTextPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap to create your first goal',
                            style: TextStyle(
                              fontSize: AppFontSizes.label,
                              color: AppPallete.getTextSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );


        }

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Goals',
                      style: TextStyle(
                        fontSize: AppFontSizes.bodyLarge, // Was 14 -> 18
                        fontWeight: FontWeight.w700,
                        color: AppPallete.getTextPrimary(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppPallete.getCardColor(context),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppPallete.getBorderColor(
                            context,
                          ).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        '${goals.length}',
                        style: TextStyle(
                          fontSize: AppFontSizes.label,
                          fontWeight: FontWeight.bold,
                          color: AppPallete.getTextPrimary(context),
                        ),
                      ),
                    ),
                  ],
                ),
                if (onSeeAllTap != null)
                  TextButton(
                    onPressed: onSeeAllTap,
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'See all',
                          style: TextStyle(
                            fontSize: AppFontSizes.label,
                            fontWeight: FontWeight.w600,
                            color: AppPallete.getTextSecondary(context),
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 14),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...goals.take(6).map((goal) {
                    final index = goals.indexOf(goal);
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: SizedBox(
                        width: 180,
                        child: GestureDetector(
                          onTap: () {
                            if (onGoalTap != null) {
                              onGoalTap!(goal);
                              return;
                            }

                            final model = GoalModel(
                              id: goal['id'] as String,
                              userId: goal['user_id'] as String? ?? '',
                              title: goal['title'] as String,
                              currentState: goal['current_state'] as String?,
                              startDate: DateTime.parse(
                                goal['start_date'] as String,
                              ),
                              endDate: goal['end_date'] != null
                                  ? DateTime.parse(goal['end_date'] as String)
                                  : null,
                              status: goal['status'] as String,
                              createdAt: goal['created_at'] != null
                                  ? DateTime.parse(goal['created_at'] as String)
                                  : DateTime.now(),
                              updatedAt: goal['updated_at'] != null
                                  ? DateTime.parse(goal['updated_at'] as String)
                                  : DateTime.now(),
                            );

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    GoalDetailPage(goal: model),
                              ),
                            );
                          },
                          child: Consumer(
                            builder: (context, cardRef, child) {
                              final statsAsync = cardRef.watch(
                                goalTaskStatsProvider(goal['id'] as String),
                              );
                              final completedTasks =
                                  statsAsync.value?['completed'] ?? 0;
                              final totalTasks =
                                  statsAsync.value?['total'] ?? 0;

                              return ProjectCard(
                                title: goal['title'] as String,
                                completedTasks: completedTasks,
                                totalTasks: totalTasks,
                                icon: goal['icon'] as String?,
                                color: index % 2 == 0
                                    ? AppPallete.getTextPrimary(context)
                                    : AppPallete.getTextSecondary(context),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                  if (goals.length > 6)
                    GestureDetector(
                      onTap: onSeeAllTap,
                      child: Container(
                        width: 140,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppPallete.getCardColor(
                            context,
                          ).withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppPallete.getBorderColor(
                              context,
                            ).withValues(alpha: 0.3),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppPallete.getSecondarySurface(context),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                size: 20,
                                color: AppPallete.getTextSecondary(context),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'See more',
                              style: TextStyle(
                                fontSize: AppFontSizes.label,
                                fontWeight: FontWeight.w600,
                                color: AppPallete.getTextSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 95,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => SizedBox(
        height: 95,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Could not load goals',
            style: TextStyle(color: AppPallete.getTextSecondary(context)),
          ),
        ),
      ),
    );
  }
}
