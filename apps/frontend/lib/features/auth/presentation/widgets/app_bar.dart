import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/common/providers/app_user_notifier.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:frontend/features/profile/presentation/pages/profile_page.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBack;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBack = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appUserNotifierProvider);
    final avatarChar = (user?.email.isNotEmpty == true
        ? user!.email[0].toUpperCase()
        : 'U');

    return AppBar(
      backgroundColor: AppPallete.transparentColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      leading: showBack
          ? IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: Theme.of(context).colorScheme.onSurface,
                size: 20,
              ),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 20,
        ),
      ),
      actions: [
        if (actions != null) ...actions!,
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => Navigator.of(context).pushNamed(ProfileScreen.routeName),
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppPallete.primaryColor.withValues(alpha: 0.1),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.surface,
              child: Text(
                avatarChar,
                style: TextStyle(
                  color: AppPallete.primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
