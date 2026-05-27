import 'package:flutter/material.dart';
import 'package:frontend/features/goals/domain/models/task.dart';
import 'package:intl/intl.dart';

class TaskRow extends StatelessWidget {
  final Task task;

  const TaskRow({super.key, required this.task});

  Color _getPriorityColor(String? priority) {
    switch (priority?.toUpperCase()) {
      case 'HIGH':
        return Colors.red;
      case 'MEDIUM':
        return Colors.orange;
      case 'LOW':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getPriorityIcon(String? priority) {
    switch (priority?.toUpperCase()) {
      case 'HIGH':
        return Icons.arrow_upward;
      case 'MEDIUM':
        return Icons.arrow_forward;
      case 'LOW':
        return Icons.arrow_downward;
      default:
        return Icons.remove;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference == -1) {
      return 'Yesterday';
    } else if (difference.abs() < 7) {
      return DateFormat('EEE').format(date);
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = task.isCompleted ? Colors.green : Colors.grey;
    final priorityColor = _getPriorityColor(task.priority);
    final isCompleted = task.isCompleted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          // Task Name
          Expanded(
            flex: 4,
            child: Text(
              task.title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                decoration: isCompleted
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                color: isCompleted ? Colors.black54 : Colors.black87,
              ),
            ),
          ),
          // Status Badge
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                isCompleted ? 'DONE' : 'TODO',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // Priority Badge
          Expanded(
            flex: 2,
            child: task.priority != null
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: priorityColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getPriorityIcon(task.priority),
                          size: 10,
                          color: priorityColor,
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            task.priority!,
                            style: TextStyle(
                              color: priorityColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(),
          ),
          // Due Date
          Expanded(
            flex: 2,
            child: task.dueDate != null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(task.dueDate),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }
}
