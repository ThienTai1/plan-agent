import 'package:flutter/material.dart';
import 'package:frontend/features/goals/domain/models/phase.dart';
import 'package:frontend/features/goals/presentation/widgets/task_row.dart';

class PhaseSection extends StatefulWidget {
  final Phase phase;

  const PhaseSection({
    super.key,
    required this.phase,
  });

  @override
  State<PhaseSection> createState() => _PhaseSectionState();
}

class _PhaseSectionState extends State<PhaseSection> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final taskCount = widget.phase.tasks?.length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Phase Header
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                bottom: BorderSide(
                  color: Colors.black.withValues(alpha: 0.06 * 255),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  size: 20,
                  color: Colors.black54,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.phase.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$taskCount',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Tasks
        if (_isExpanded && widget.phase.tasks != null)
          ...widget.phase.tasks!.map(
            (task) => TaskRow(task: task),
          ),
      ],
    );
  }
}

