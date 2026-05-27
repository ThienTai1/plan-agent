import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:frontend/features/goals/data/models/task_model.dart';
import 'package:frontend/features/tasks/presentation/widgets/task_item_widget.dart';

class DailyTasksList extends StatelessWidget {
  final List<TaskModel> tasks;
  final Map<String, String> goalTitleById;
  final VoidCallback? onSeeAllTap;
  final ValueChanged<TaskModel>? onTaskTap;
  final ValueChanged<TaskModel>? onToggleStatus;

  const DailyTasksList({
    super.key,
    required this.tasks,
    this.goalTitleById = const {},
    this.onSeeAllTap,
    this.onTaskTap,
    this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final pendingTasksCount = tasks.where((t) => !t.isCompleted).length;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Tasks',
                  style: TextStyle(
                    fontSize: AppFontSizes.bodyLarge, // Was header (12) -> 18
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
                    '$pendingTasksCount',
                    style: TextStyle(
                      fontSize: AppFontSizes.label, // Was metadata (12) -> 14
                      fontWeight: FontWeight.bold,
                      color: AppPallete.getTextPrimary(context),
                    ),
                  ),
                ),
              ],
            ),
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
                      fontSize: AppFontSizes.label, // Was title (12) -> 14
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
        const SizedBox(height: 8),
        if (tasks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 48),
            decoration: BoxDecoration(
              color: AppPallete.getSecondarySurface(
                context,
              ).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppPallete.getBorderColor(
                  context,
                ).withValues(alpha: 0.8),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppPallete.isDarkMode(context)
                        ? Colors.white12
                        : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.check_circle_outline_rounded,
                      size: 36,
                      color: AppPallete.getTextSecondary(
                        context,
                      ).withValues(alpha: 0.7),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No tasks for this day',
                  style: TextStyle(
                    fontSize: AppFontSizes.bodyLarge,
                    fontWeight: FontWeight.w700,
                    color: AppPallete.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Enjoy your free time!',
                  style: TextStyle(
                    fontSize: AppFontSizes.label,
                    fontWeight: FontWeight.w500,
                    color: AppPallete.getTextSecondary(context),
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tasks.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final task = tasks[index];
              // Goal label for this task
              String goalTitle = 'General';
              if (task.goalId != null) {
                goalTitle = goalTitleById[task.goalId!] ?? 'Goal';
              }

              return TaskItemWidget(
                task: task,
                goalTitle: goalTitle,
                onTap: onTaskTap == null ? null : () => onTaskTap!(task),
                onStatusChanged: (isDone) {
                  if (onToggleStatus != null) onToggleStatus!(task);
                },
              );
            },
          ),
      ],
    );
  }
}
