import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/database/local_queries_providers.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:frontend/core/common/domain/models/goal.dart';
import 'package:frontend/features/goals/presentation/pages/goal_detail_page.dart';

class GoalCard extends ConsumerStatefulWidget {
  final Goal goal;
  final VoidCallback? onTap;
  final bool isSelected;

  const GoalCard({
    super.key,
    required this.goal,
    this.onTap,
    this.isSelected = false,
  });

  @override
  ConsumerState<GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends ConsumerState<GoalCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final goal = widget.goal;
    final status = goal.status.toLowerCase().trim();
    final isCompleted =
        status == 'completed' || status == 'done' || status == 'success';

    // Watch task stats from DB
    final statsAsync = ref.watch(goalTaskStatsProvider(goal.id));
    final int totalTasks = statsAsync.value?['total'] ?? 0;
    final int completedTasks = statsAsync.value?['completed'] ?? 0;
    final double progress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;

    // Watch tasks for preview
    final tasksAsync = ref.watch(tasksByGoalProvider(goal.id));
    final previewTasks = tasksAsync.value ?? [];

    // Date range formatting helpers
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    String formatDate(DateTime date) {
      final month = months[date.month - 1];
      final day = date.day;
      String suffix = 'th';
      if (day == 1 || day == 21 || day == 31)
        suffix = 'st';
      else if (day == 2 || day == 22)
        suffix = 'nd';
      else if (day == 3 || day == 23)
        suffix = 'rd';
      return '$month, ${day}$suffix';
    }

    final dateRangeText = goal.endDate != null
        ? '${formatDate(goal.startDate)} - ${formatDate(goal.endDate!)}'
        : formatDate(goal.startDate);

    return GestureDetector(
      onTap:
          widget.onTap ??
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => GoalDetailPage(goal: goal)),
          ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppPallete.getCardColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isSelected
                ? AppPallete.getPrimaryColor(context).withValues(alpha: 0.4)
                : AppPallete.getBorderColor(context).withValues(alpha: 0.8),
            width: 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Icon and Goal Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    goal.icon ?? '🎯',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    goal.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppPallete.getTextPrimary(context),
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Row 2: Thicker Black & White Progress Bar + Expand Toggle
            GestureDetector(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _isExpanded ? 0.25 : 0,
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppPallete.getTextPrimary(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: AppPallete.getBorderColor(
                          context,
                        ).withValues(alpha: 0.15),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.green,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$completedTasks/$totalTasks tasks',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppPallete.getTextSecondary(context),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),

            // Row 3: Task Preview (Clean)
            if (_isExpanded && previewTasks.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(previewTasks.length, (index) {
                    final task = previewTasks[index];
                    final isTaskCompleted =
                        (task['is_completed'] as int? ?? 0) == 1;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          _buildTaskStatusIcon(isTaskCompleted),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              task['title'] as String,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isTaskCompleted
                                    ? AppPallete.getTextMuted(context)
                                    : AppPallete.getTextSecondary(
                                        context,
                                      ).withValues(alpha: 0.9),
                                decoration: isTaskCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
            const SizedBox(height: 12),

            // Row 4: Status and Date Range
            Row(
              children: [
                Builder(
                  builder: (context) {
                    final String displayStatus;
                    final Color statusColor;

                    if (totalTasks > 0) {
                      if (progress >= 1.0) {
                        displayStatus = 'DONE';
                        statusColor = Colors.green;
                      } else if (progress > 0) {
                        displayStatus = 'DOING';
                        statusColor = Colors.blue;
                      } else {
                        displayStatus = 'PENDING';
                        statusColor = AppPallete.getTextSecondary(context);
                      }
                    } else {
                      displayStatus = isCompleted ? 'DONE' : 'ACTIVE';
                      statusColor = isCompleted ? Colors.green : Colors.blue;
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        displayStatus,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Text(
                  dateRangeText,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppPallete.getTextMuted(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskStatusIcon(bool isCompleted) {
    return Icon(
      isCompleted
          ? Icons.check_circle_rounded
          : Icons.radio_button_unchecked_rounded,
      size: 18,
      color: isCompleted
          ? Colors.green.withValues(alpha: 0.8)
          : Colors.blue.withValues(alpha: 0.6),
    );
  }
}

