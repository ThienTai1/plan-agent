import 'package:flutter/material.dart';
import 'package:frontend/core/common/domain/models/task.dart' as core_task;
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:frontend/core/common/providers/app_user_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/goals/data/models/task_model.dart';
import 'package:frontend/features/tasks/presentation/pages/task_detail_page.dart';
import 'package:frontend/features/profile/presentation/providers/notification_settings_provider.dart';
import 'package:frontend/features/goals/presentation/providers/tasks_notifier.dart';

class DetailedTaskItem extends StatelessWidget {
  final TaskModel task;
  final String goalTitle;
  final double progress;

  const DetailedTaskItem({
    super.key,
    required this.task,
    required this.goalTitle,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final isCompleted = task.isCompleted;
        
        return InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskDetailPage(task: task),
            ),
          ),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            clipBehavior: Clip.antiAlias, // Important for the color bar
            decoration: BoxDecoration(
              color: AppPallete.getCardColor(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppPallete.getBorderColor(context),
                width: 1.0,
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Priority Color Bar
                  Container(
                    width: 6,
                    color: AppPallete.getPriorityColor(task.priority),
                  ),
                  
                  // 2. Main Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          // Checkbox
                          GestureDetector(
                            onTap: () {
                              final updatedIsCompleted = !task.isCompleted;
                              final payload = core_task.Task(
                                id: task.id,
                                userId: ref.read(appUserNotifierProvider)?.id ?? task.userId ?? '',
                                goalId: task.goalId,
                                phaseId: task.phaseId,
                                title: task.title,
                                dueDate: task.dueDate,
                                isCompleted: updatedIsCompleted,
                                priority: task.priority,
                                createdAt: task.createdAt,
                                updatedAt: DateTime.now(),
                                customProperties: task.customProperties,
                              );
                              ref.read(tasksNotifierProvider.notifier).updateTask(payload);
                            },
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isCompleted
                                      ? AppPallete.getPrimaryColor(context)
                                      : AppPallete.getTextSecondary(context).withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                                color: isCompleted
                                    ? AppPallete.getPrimaryColor(context)
                                    : Colors.transparent,
                              ),
                              child: isCompleted
                                  ? const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Text Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppPallete.getTextPrimary(context),
                                    decoration: isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    // Priority Tag
                                    _buildPriorityTag(context, task.priority),
                                    const SizedBox(width: 12),
                                    // Date
                                    Text(
                                      _getFormattedDate(task.dueDate),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppPallete.getTextSecondary(context),
                                      ),
                                    ),
                                    
                                    // Notification Bell Indicator
                                    _buildNotificationIndicator(context, ref),
                                    // const SizedBox(width: 8),
                                    // // Recurrence Indicator
                                    // _buildRecurrenceIndicator(context),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationIndicator(BuildContext context, WidgetRef ref) {
    if (task.isCompleted) return const SizedBox.shrink();
    if (task.dueDate == null || task.dueDate!.isBefore(DateTime.now())) return const SizedBox.shrink();
    
    final settingsAsync = ref.watch(notificationSettingsProvider);
    return settingsAsync.when(
      data: (settings) {
        if (!settings.pushEnabled) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Icon(
            Icons.notifications_active_outlined,
            size: 14,
            color: AppPallete.getPrimaryColor(context).withValues(alpha: 0.6),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /* Widget _buildRecurrenceIndicator(BuildContext context) {
    if (task.recurrenceRule == null ||
        task.recurrenceRule!.toLowerCase() == 'none') {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Icon(
        Icons.repeat,
        size: 14,
        color: AppPallete.getTextSecondary(context).withValues(alpha: 0.6),
      ),
    );
  } */

  Widget _buildPriorityTag(BuildContext context, String? priority) {
    if (priority == null || priority.toLowerCase() == 'none') return const SizedBox.shrink();
    
    final color = AppPallete.getPriorityColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }



  String _getFormattedDate(DateTime? dueDate) {
    if (dueDate == null) return 'No date';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final diff = due.difference(today).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${due.day} ${months[due.month - 1]}';
  }
}
