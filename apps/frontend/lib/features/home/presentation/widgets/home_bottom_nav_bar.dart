import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:frontend/features/home/presentation/providers/home_navigation_provider.dart';
import 'package:frontend/features/chat/presentation/pages/chat_page.dart';
import 'package:frontend/core/common/providers/app_user_notifier.dart';

class HomeBottomNavBar extends ConsumerWidget {
  const HomeBottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(homeNavigationProvider);
    final user = ref.watch(appUserNotifierProvider);
    final initials = user?.fullName?.isNotEmpty == true
        ? user!.fullName![0].toUpperCase()
        : '?';
    final avatarUrl = user?.avatarUrl;


    return Container(
      decoration: BoxDecoration(
        color: AppPallete.getCardColor(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, -5), // Shadow upwards for anchored bar
          ),
        ],
        border: Border(
          top: BorderSide(
            color: AppPallete.getBorderColor(context).withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Container(
          height: 64, // Standard height for anchored nav bar
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavBarItem(
                icon: LucideIcons.calendar,
                label: 'Today',
                isSelected: selectedIndex == 0,
                onTap: () => _updateIndex(context, ref, 0),
              ),
              _NavBarItem(
                icon: LucideIcons.folder,
                label: 'Goals',
                isSelected: selectedIndex == 1,
                onTap: () => _updateIndex(context, ref, 1),
              ),
              _NavBarItem(
                icon: LucideIcons.clipboard_list,
                label: 'Tasks',
                isSelected: selectedIndex == 2,
                onTap: () => _updateIndex(context, ref, 2),
              ),
              _NavBarItem(
                icon: LucideIcons.sparkles,
                label: 'AI',
                isSelected: false,
                onTap: () => _openAiAgent(context),
              ),
              _NavBarItem(
                label: 'You',
                isSelected: selectedIndex == 3,
                onTap: () => _updateIndex(context, ref, 3),
                avatarUrl: avatarUrl,
                initials: initials,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAiAgent(BuildContext context) {
    Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute(builder: (_) => const ChatPage()));
  }

  void _updateIndex(BuildContext context, WidgetRef ref, int index) {
    ref.read(homeNavigationProvider.notifier).setIndex(index);
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData? icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final String? avatarUrl;
  final String? initials;

  const _NavBarItem({
    this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.avatarUrl,
    this.initials,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? AppPallete.getTextPrimary(context)
        : AppPallete.getTextSecondary(context).withValues(alpha: 0.6);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (avatarUrl != null || initials != null)
              CircleAvatar(
                radius: 13,
                backgroundColor: isSelected 
                    ? AppPallete.getPrimaryColor(context) 
                    : AppPallete.getBorderColor(context).withValues(alpha: 0.2),
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                child: avatarUrl == null 
                    ? Text(
                        initials ?? '?',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected 
                              ? Colors.white 
                              : AppPallete.getTextPrimary(context),
                        ),
                      ) 
                    : null,
              )
            else if (icon != null)
              Icon(
                icon,
                color: color,
                size: 26,
              ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
