import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:frontend/features/goals/presentation/pages/goals_list_page.dart';
import 'package:frontend/features/profile/presentation/pages/profile_page.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Drag Handle
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppPallete.getTextMuted(context).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Text(
            'More',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppPallete.getTextPrimary(context),
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth < 360 ? 3 : 4;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                mainAxisSpacing: 16,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85, // More vertical space
                children: [
                  _buildMenuCard(
                    context,
                    'Goals',
                    Icons.flag_outlined,
                    () => _navigateTo(context, const GoalsListPage()),
                  ),
                  _buildMenuCard(
                    context,
                    'Profile',
                    Icons.person_outline,
                    () => _navigateTo(context, const ProfileScreen()),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppPallete.getCardColor(context),
              border: Border.all(color: AppPallete.getBorderColor(context)),
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppPallete.getDynamicSoftShadow(context),
            ),
            child: Icon(
              icon,
              size: 24,
              color: AppPallete.getTextPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              maxLines: 1,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppPallete.getTextPrimary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }
}
