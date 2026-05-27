import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/features/goals/data/models/task_model.dart';

class TaskItemWidget extends StatelessWidget {
  final TaskModel task;
  final String? goalTitle;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onStatusChanged;

  const TaskItemWidget({
    super.key,
    required this.task,
    this.goalTitle,
    this.onTap,
    this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = task.isCompleted;
    final dueText = _formatDateTime(
      task.dueDate,
      task.isEvent ? 'Starts' : 'Due',
    );
    final repeatText = _repeatLabel(task.recurrenceRule);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isDone 
              ? AppPallete.getCardColor(context).withValues(alpha: 0.4) 
              : AppPallete.getCardColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDone 
                ? AppPallete.getBorderColor(context).withValues(alpha: 0.2)
                : AppPallete.getBorderColor(context).withValues(alpha: 0.8),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox Area
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 16),
              child: GestureDetector(
                onTap: onStatusChanged == null
                    ? null
                    : () => onStatusChanged!(!isDone),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone 
                        ? AppPallete.getPrimaryColor(context)
                        : Colors.transparent,
                    border: Border.all(
                      color: isDone 
                          ? AppPallete.getPrimaryColor(context)
                          : AppPallete.getTextSecondary(context).withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: isDone
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: AppPallete.getSurface(context),
                        )
                      : null,
                ),
              ),
            ),
            
            // Content Area
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (goalTitle != null && goalTitle!.isNotEmpty)
                        Expanded(
                          child: Text(
                            goalTitle!.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: AppFontSizes.caption,
                              fontWeight: FontWeight.w700,
                              color: isDone 
                                  ? AppPallete.getTextSecondary(context).withValues(alpha: 0.5) 
                                  : AppPallete.getTextSecondary(context),
                              letterSpacing: 0.5,
                            ),
                          ),
                        )
                      else
                        const Spacer(),
                      if (task.color != null)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isDone ? task.color!.withValues(alpha: 0.4) : task.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    task.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: AppFontSizes.bodyLarge,
                      fontWeight: FontWeight.w600,
                      color: isDone
                          ? AppPallete.getTextSecondary(context).withValues(alpha: 0.5)
                          : AppPallete.getTextPrimary(context),
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      decorationColor: AppPallete.getTextSecondary(context).withValues(alpha: 0.5),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (dueText != null || repeatText != null || task.priority != null || task.isEvent) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (task.priority != null && task.priority!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (isDone
                                          ? AppPallete.getTextSecondary(context)
                                              .withValues(alpha: 0.4)
                                          : AppPallete.getPriorityColor(
                                            task.priority,
                                          ))
                                      .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.flag_rounded,
                                  size: 12,
                                  color:
                                      isDone
                                          ? AppPallete.getTextSecondary(context)
                                              .withValues(alpha: 0.4)
                                          : AppPallete.getPriorityColor(
                                            task.priority,
                                          ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  task.priority!.toUpperCase(),
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        isDone
                                            ? AppPallete.getTextSecondary(
                                              context,
                                            ).withValues(alpha: 0.4)
                                            : AppPallete.getPriorityColor(
                                              task.priority,
                                            ),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (dueText != null)
                          _buildMetaText(
                            context,
                            label: dueText,
                            icon: task.isEvent
                                ? Icons.schedule_rounded
                                : Icons.calendar_today_rounded,
                            isDone: isDone,
                          ),
                        /*
                        if (repeatText != null)
                          _buildMetaText(
                            context,
                            label: repeatText,
                            icon: Icons.repeat_rounded,
                            isDone: isDone,
                          ),
                        if (task.isEvent)
                          _buildMetaText(
                            context,
                            label: 'Event',
                            icon: Icons.event_rounded,
                            isDone: isDone,
                          ),
                        */
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

  }


  Widget _buildMetaText(
    BuildContext context, {
    required String label,
    required IconData icon,
    Color? color,
    bool isDone = false,
  }) {
    final fg = color ?? (isDone 
        ? AppPallete.getTextSecondary(context).withValues(alpha: 0.4) 
        : AppPallete.getTextSecondary(context));
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: fg),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: AppFontSizes.caption,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      ],
    );
  }


  String? _repeatLabel(String? repeatRule) {
    if (repeatRule == null || repeatRule.isEmpty) return null;
    final upper = repeatRule.toUpperCase();
    if (upper.contains('DAILY')) return 'Every day';
    if (upper.contains('WEEKLY')) return 'Every week';
    if (upper.contains('MONTHLY')) return 'Every month';
    if (upper.contains('YEARLY')) return 'Every year';
    return 'Repeats';
  }

  String? _formatDateTime(DateTime? value, String prefix) {
    if (value == null) return null;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final datePart = '${months[value.month - 1]} ${value.day}';
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return '$prefix $datePart $hh:$mm';
  }
}
