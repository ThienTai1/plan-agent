import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:frontend/core/common/providers/app_user_notifier.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:frontend/features/auth/presentation/providers/auth_notifier.dart';
import 'package:frontend/features/auth/presentation/pages/login_page.dart';
import 'package:frontend/features/profile/presentation/pages/gallery_page.dart';
import 'package:frontend/features/premium/presentation/pages/subscription_page.dart';
import 'package:frontend/features/chat/presentation/pages/chat_page.dart';
import 'package:google_fonts/google_fonts.dart';

class MainDrawer extends ConsumerWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appUserNotifierProvider);
    final userName = user?.fullName ?? user?.email.split('@')[0] ?? 'User';
    final userEmail = user?.email ?? '';
    final initials = user?.fullName?.isNotEmpty == true
        ? user!.fullName![0].toUpperCase()
        : userEmail.isNotEmpty ? userEmail[0].toUpperCase() : '?';

    return Drawer(
      backgroundColor: AppPallete.getBackgroundColor(context),
      child: Column(
        children: [
          // Drawer Header
          _buildHeader(context, userName, userEmail, user?.avatarUrl, initials),
          
          const SizedBox(height: 16),
          
          // Drawer Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildSectionLabel(context, 'MAIN'),
                _buildDrawerItem(
                  context,
                  icon: LucideIcons.trophy,
                  label: 'Achievements',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, GalleryPage.routeName);
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: LucideIcons.sparkles,
                  label: 'AI Assistant',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatPage()));
                  },
                ),
                
                const SizedBox(height: 24),
                _buildSectionLabel(context, 'PREMIUM'),
                _buildDrawerItem(
                  context,
                  icon: LucideIcons.star,
                  label: 'Levigo Pro',
                  iconColor: Colors.amber,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, SubscriptionPage.routeName);
                  },
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'PRO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                _buildSectionLabel(context, 'SUPPORT'),
                _buildDrawerItem(
                  context,
                  icon: LucideIcons.settings,
                  label: 'Settings',
                  onTap: () {
                    // Navigate to settings
                    Navigator.pop(context);
                  },
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.help_outline_rounded,
                  label: 'Help & FAQ',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          
          // Logout
          Padding(
            padding: const EdgeInsets.all(24),
            child: _buildDrawerItem(
              context,
              icon: LucideIcons.log_out,
              label: 'Logout',
              iconColor: AppPallete.errorColor,
              textColor: AppPallete.errorColor,
              onTap: () => _showLogoutDialog(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String userName,
    String userEmail,
    String? avatarUrl,
    String initials,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      decoration: BoxDecoration(
        color: AppPallete.getSurfaceContainerLow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppPallete.getPrimaryColor(context).withValues(alpha: 0.1),
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? Text(
                    initials,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppPallete.getPrimaryColor(context),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            userName,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppPallete.getTextPrimary(context),
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            userEmail,
            style: TextStyle(
              fontSize: 13,
              color: AppPallete.getTextSecondary(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppPallete.getTextSecondary(context).withValues(alpha: 0.5),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        size: 20,
        color: iconColor ?? AppPallete.getTextPrimary(context),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textColor ?? AppPallete.getTextPrimary(context),
        ),
      ),
      trailing: trailing,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.w600)),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppPallete.getTextSecondary(context)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authNotifierProvider.notifier).logout();
              Navigator.of(context).pushNamedAndRemoveUntil(
                LoginScreen.routeName,
                (route) => false,
              );
            },
            child: Text(
              'Logout',
              style: TextStyle(
                color: AppPallete.errorColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
