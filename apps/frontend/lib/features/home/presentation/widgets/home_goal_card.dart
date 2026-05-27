import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:frontend/core/common/domain/models/goal.dart';

class HomeGoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback? onTap;

  const HomeGoalCard({super.key, required this.goal, this.onTap});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getGoalIcon(String title) {
    if (title.toLowerCase().contains('saas') ||
        title.toLowerCase().contains('platform')) {
      return '🚀';
    } else if (title.toLowerCase().contains('certification') ||
        title.toLowerCase().contains('pmp')) {
      return '🎓';
    } else if (title.toLowerCase().contains('coder') ||
        title.toLowerCase().contains('bootcamp')) {
      return '💻';
    }
    return '🎯';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(goal.status);
    final icon = _getGoalIcon(goal.title);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(icon, style: const TextStyle(fontSize: 24)),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    goal.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: AppFontSizes.caption, // Was 10 -> 12
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              goal.title,
              style: TextStyle(
                fontSize: AppFontSizes.bodyDefault, // 16
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${goal.phases?.length ?? 0} Phases', // Basic detail
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
