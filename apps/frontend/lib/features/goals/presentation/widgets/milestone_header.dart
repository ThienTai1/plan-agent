import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:frontend/features/goals/domain/models/phase.dart';

class MilestoneHeader extends StatelessWidget {
  final Phase phase;
  final int taskCount;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const MilestoneHeader({
    super.key,
    required this.phase,
    required this.taskCount,
    required this.isCollapsed,
    required this.onToggleCollapse,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggleCollapse,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: Row(
          children: [
            Icon(
              isCollapsed ? Icons.radio_button_unchecked : Icons.radio_button_checked,
              size: 20,
              color: AppPallete.getPrimaryColor(context),
            ),
            const SizedBox(width: 12),
            Text(
              phase.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppPallete.getTextPrimary(context),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppPallete.getSecondarySurface(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$taskCount Tasks',
                style: TextStyle(
                  fontSize: 12,
                  color: AppPallete.getTextSecondary(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () {
                // This would normally open create task modal with this phase selected
                // For now, it's a UI placeholder or we can trigger a callback
              },
              icon: Icon(
                Icons.add,
                size: 20,
                color: AppPallete.getTextSecondary(context),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_horiz,
                size: 20,
                color: AppPallete.getTextMuted(context),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onSelected: (value) {
                if (value == 'rename') {
                  onRename();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'rename',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Rename'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
