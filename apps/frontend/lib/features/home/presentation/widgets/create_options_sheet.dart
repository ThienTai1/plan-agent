import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:frontend/features/goals/presentation/widgets/create_goal_modal.dart';
import 'package:frontend/features/goals/presentation/widgets/create_task_modal.dart';

class CreateOptionsSheet extends StatelessWidget {
  const CreateOptionsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 12, bottom: 40, left: 24, right: 24),
      decoration: BoxDecoration(
        color: AppPallete.getBackgroundColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(bottom: 24),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppPallete.getTextMuted(
                    context,
                  ).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Create New',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppPallete.getTextPrimary(context),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'What would you like to add today?',
              style: TextStyle(
                fontSize: 14,
                color: AppPallete.getTextSecondary(context),
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 32),
            _buildOptionItem(
              context,
              icon: Icons.check_circle_outline_rounded,
              title: 'Quick Task',
              subtitle: 'Add a small todo item to your list',
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors
                      .transparent, // Use transparent for the sheet itself
                  builder: (context) =>
                      const CreateTaskModal(initialIsEvent: false),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildOptionItem(
              context,
              icon: Icons.flag_outlined,
              title: 'Long-term Goal',
              subtitle: 'Start a new project or milestone',
              onTap: () {
                Navigator.pop(context);
                CreateGoalModal.show(context);
              },
            ),
            const SizedBox(height: 16),
            _buildOptionItem(
              context,
              icon: Icons.calendar_today_outlined,
              title: 'Calendar Event',
              subtitle: 'Schedule a meeting or set a reminder',
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) =>
                      const CreateTaskModal(initialIsEvent: true),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: AppPallete.getCardColor(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppPallete.getBorderColor(context).withValues(alpha: 0.5),
          ),
          boxShadow: AppPallete.getDynamicCardShadow(context),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppPallete.getPrimaryColor(
                  context,
                ).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: AppPallete.getPrimaryColor(context),
                size: 26,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppPallete.getTextPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppPallete.getTextSecondary(context),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppPallete.getTextMuted(context),
            ),
          ],
        ),
      ),
    );
  }
}
