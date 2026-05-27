import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:frontend/features/chat/presentation/widgets/action_cards.dart';

/// Focus Action Card — Top 3 priority tasks for today with inline checkboxes.
class FocusActionCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(String taskId, bool isCompleted) onToggle;

  const FocusActionCard({
    super.key,
    required this.data,
    required this.onToggle,
  });

  @override
  State<FocusActionCard> createState() => _FocusActionCardState();
}

class _FocusActionCardState extends State<FocusActionCard> {
  late List<Map<String, dynamic>> _tasks;

  @override
  void initState() {
    super.initState();
    _tasks = ((widget.data['tasks'] as List?) ?? [])
        .map((t) => Map<String, dynamic>.from(t as Map))
        .toList();
  }

  void _toggleTask(int index) {
    setState(() {
      _tasks[index]['is_completed'] = !(_tasks[index]['is_completed'] ?? false);
    });
    widget.onToggle(
      _tasks[index]['task_id'] ?? '',
      _tasks[index]['is_completed'] ?? false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final date = widget.data['date'] ?? 'Today';
    final completedCount = _tasks.where((t) => t['is_completed'] == true).length;

    return ChatActionCard(
      category: "Today's Focus",
      title: date,
      icon: LucideIcons.zap,
      accentColor: const Color(0xFF4C8CFF),
      showCategory: false,
      actions: [

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$completedCount/${_tasks.length}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Color(0xFF4C8CFF),
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(_tasks.length, (index) {
          return _buildTaskItem(context, _tasks[index], index);
        }),
      ),
    );
  }

  Widget _buildTaskItem(
    BuildContext context,
    Map<String, dynamic> task,
    int index,
  ) {
    final title = task['title'] ?? '';
    final goalTag = task['goal_tag'];
    final estimatedMinutes = task['estimated_minutes'];
    final isCompleted = task['is_completed'] ?? false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCompleted
            ? Colors.blue.withValues(alpha: 0.05)
            : AppPallete.getSurfaceContainerLow(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF4C8CFF).withValues(alpha: 0.2)
              : AppPallete.getBorderColor(context).withValues(alpha: 0.1),
        ),
        boxShadow: isCompleted 
          ? [] 
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
      ),

      child: Row(
        children: [
          // Checkbox
          GestureDetector(
            onTap: () => _toggleTask(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isCompleted
                    ? const Color(0xFF4C8CFF)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCompleted
                      ? const Color(0xFF4C8CFF)
                      : AppPallete.getTextMuted(context).withValues(alpha: 0.5),
                  width: 2,
                ),

              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isCompleted
                        ? AppPallete.getTextMuted(context)
                        : AppPallete.getTextPrimary(context),
                    decoration: isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (goalTag != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C4DDA).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.target,
                              size: 9,
                              color: Color(0xFF6C4DDA),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              goalTag,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6C4DDA),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (estimatedMinutes != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppPallete.getTextMuted(context)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.clock,
                              size: 9,
                              color: AppPallete.getTextMuted(context),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${estimatedMinutes}m',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppPallete.getTextMuted(context),
                              ),
                            ),
                          ],
                        ),
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
