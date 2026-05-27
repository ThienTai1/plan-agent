import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:frontend/features/goals/data/models/task_model.dart';
import 'package:frontend/features/tasks/presentation/pages/task_detail_page.dart';
import 'package:frontend/features/goals/presentation/widgets/custom_properties_view.dart';

class TaskRowItem extends StatelessWidget {
  final TaskModel task;
  final List<CustomProperty> goalFieldDefinitions;
  final VoidCallback onToggleCompletion;
  final Future<bool?> Function() onConfirmDelete;
  final VoidCallback onDismissed;
  final int depth;
  final bool hasChildren;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final VoidCallback onAddSubtask;
  final int completedSubtasks;
  final int totalSubtasks;

  const TaskRowItem({
    super.key,
    required this.task,
    required this.goalFieldDefinitions,
    required this.onToggleCompletion,
    required this.onConfirmDelete,
    required this.onDismissed,
    this.depth = 0,
    this.hasChildren = false,
    this.isCollapsed = false,
    required this.onToggleCollapse,
    required this.onAddSubtask,
    this.completedSubtasks = 0,
    this.totalSubtasks = 0,
  });

  String _formatDueDate(DateTime date) {
    return DateFormat('d MMM').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final isOverdue =
        task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now()) &&
        !task.isCompleted;

    // SIGNIFICANT Indentation as per screenshot (40px per depth level)
    const double indentSize = 40.0;

    return Dismissible(
      key: Key('task-${task.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.withValues(alpha: 0.1),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      confirmDismiss: (direction) => onConfirmDelete(),
      onDismissed: (direction) => onDismissed(),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskDetailPage(
                task: task,
                goalFieldDefinitions: goalFieldDefinitions,
              ),
            ),
          );
        },
        child: Container(
          padding: EdgeInsets.only(
            left: 16 + (depth * indentSize),
            right: 16,
            top: 12,
            bottom: 12,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppPallete.getBorderColor(context).withValues(alpha: 0.5),
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Line 1: Chevron + Checkbox + Title
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Smaller Chevron on the very left
                  if (hasChildren)
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: GestureDetector(
                        onTap: onToggleCollapse,
                        child: Icon(
                          isCollapsed ? Icons.chevron_right : Icons.expand_more,
                          size: 16,
                          color: AppPallete.getTextSecondary(context),
                        ),
                      ),
                    )
                  else if (depth > 0)
                    const SizedBox(width: 24), // Spacer for subtasks to align checkbox
                  const SizedBox(width: 4),
                  // Circle Checkbox
                  GestureDetector(
                    onTap: onToggleCompletion,
                    child: Icon(
                      task.isCompleted
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 22,
                      color: task.isCompleted
                          ? AppPallete.getPrimaryColor(context)
                          : _getPriorityColor(task.priority).withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: depth == 0 ? FontWeight.w500 : FontWeight.w400,
                        color: task.isCompleted
                            ? AppPallete.getTextMuted(context)
                            : AppPallete.getTextPrimary(context),
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                  // Hidden Quick Add button - visible in tree view but discreet
                  IconButton(
                    onPressed: onAddSubtask,
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: AppPallete.getPrimaryColor(context).withValues(alpha: 0.4),
                  ),
                ],
              ),
              // Line 2: Metadata (Indented to match Title)
              if (!task.isCompleted && (totalSubtasks > 0 || task.dueDate != null))
                Padding(
                  padding: const EdgeInsets.only(left: 64, top: 4), // 24 (chevron area) + 4 (space) + 24 (checkbox area) + 12 (space) = 64
                  child: Row(
                    children: [
                      if (totalSubtasks > 0) ...[
                         Icon(
                           Icons.account_tree_outlined, 
                           size: 14, 
                           color: AppPallete.getTextSecondary(context).withValues(alpha: 0.7)
                         ),
                         const SizedBox(width: 4),
                         Text(
                           '$completedSubtasks/$totalSubtasks',
                           style: TextStyle(
                             fontSize: 12,
                             color: AppPallete.getTextSecondary(context),
                           ),
                         ),
                         const SizedBox(width: 12),
                      ],
                      if (task.dueDate != null) ...[
                        Icon(
                          Icons.calendar_today_outlined, 
                          size: 14, 
                          color: isOverdue ? Colors.red : AppPallete.getTextSecondary(context).withValues(alpha: 0.7)
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDueDate(task.dueDate!),
                          style: TextStyle(
                            fontSize: 12,
                            color: isOverdue ? Colors.red : AppPallete.getTextSecondary(context),
                            fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return Colors.orange;
      case 'urgent':
        return Colors.red;
      case 'low':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
