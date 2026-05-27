import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/common/providers/app_user_notifier.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:frontend/features/auth/presentation/providers/auth_notifier.dart';
import 'package:frontend/features/auth/presentation/pages/login_page.dart';
import 'package:frontend/features/profile/presentation/pages/personal_info_page.dart';
import 'package:frontend/features/profile/presentation/pages/notification_settings_page.dart';
import 'package:frontend/features/premium/presentation/pages/subscription_page.dart';
import 'package:frontend/features/profile/presentation/pages/gallery_page.dart';
import 'package:frontend/features/premium/presentation/pages/dashboard_page.dart';
import 'package:frontend/core/common/providers/theme_notifier.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:frontend/core/common/entities/user.dart' as entity;
import 'package:frontend/features/premium/presentation/widgets/paywall_bottom_sheet.dart';
import 'package:frontend/features/premium/data/services/revenue_cat_service.dart';

class ProfileScreen extends ConsumerWidget {
  static const String routeName = '/profile';

  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appUserNotifierProvider);
    final userName = user?.fullName ?? user?.email.split('@')[0] ?? 'User';
    final userEmail = user?.email ?? '';
    final initials = user?.fullName?.isNotEmpty == true
        ? user!.fullName![0].toUpperCase()
        : userEmail.isNotEmpty
        ? userEmail[0].toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Profile',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppPallete.getTextPrimary(context),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // 1. Profile Header
              _buildProfileHeader(
                context,
                userName,
                userEmail,
                user?.avatarUrl,
                initials,
              ),

              const SizedBox(height: 40),

              // 2. Settings Sections
              _buildSettingsSection(context, ref, user),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    String userName,
    String userEmail,
    String? avatarUrl,
    String initials,
  ) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppPallete.getCardColor(context),
                boxShadow: AppPallete.getDynamicSoftShadow(context),
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: AppPallete.getPrimaryColor(
                  context,
                ).withValues(alpha: 0.1),
                backgroundImage: avatarUrl != null
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null
                    ? Text(
                        initials,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppPallete.getPrimaryColor(context),
                        ),
                      )
                    : null,
              ),
            ),
            // Edit avatar button
            Container(
              decoration: BoxDecoration(
                color: AppPallete.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppPallete.getBackgroundColor(context),
                  width: 2,
                ),
              ),
              child: IconButton(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.edit, size: 14, color: Colors.white),
                onPressed: () {
                  // TODO: open image picker
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          userName,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppPallete.getTextPrimary(context),
            letterSpacing: -1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          userEmail,
          style: TextStyle(
            fontSize: 14,
            color: AppPallete.getTextSecondary(context),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context, WidgetRef ref, entity.User? user) {
    final themeMode = ref.watch(themeNotifierProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    final isPro = ref.watch(isProProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Subscription'),
        _buildActionGroup(context, [
          _buildActionTile(
            context,
            icon: Icons.star_outline_rounded,
            iconColor: Colors.amber,
            title: 'Levigo Premium',
            onTap: () =>
                Navigator.pushNamed(context, SubscriptionPage.routeName),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isPro ? Colors.green.withOpacity(0.2) : Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isPro ? 'ACTIVE' : 'UPGRADE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isPro ? Colors.green : Colors.amber,
                ),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 24),
        _buildSectionHeader(context, 'Account'),
        _buildActionGroup(context, [
          _buildActionTile(
            context,
            icon: Icons.person_outline_rounded,
            title: 'Personal Information',
            onTap: () =>
                Navigator.pushNamed(context, PersonalInfoPage.routeName),
          ),
          _buildActionTile(
            context,
            icon: Icons.emoji_events_outlined,
            title: 'Achievements',
            onTap: () => Navigator.pushNamed(context, GalleryPage.routeName),
          ),
          _buildActionTile(
            context,
            icon: LucideIcons.chart_bar,
            title: 'Strategic Dashboard',
            onTap: () {
              if (isPro) {
                Navigator.pushNamed(context, DashboardPage.routeName);
              } else {
                PaywallBottomSheet.show(context);
              }
            },
            trailing: isPro 
              ? null 
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppPallete.getPrimaryColor(context).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppPallete.getPrimaryColor(context).withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    'PRO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppPallete.getPrimaryColor(context),
                    ),
                  ),
                ),
          ),
        ]),
        const SizedBox(height: 24),
        _buildSectionHeader(context, 'App'),
        _buildActionGroup(context, [
          _buildActionTile(
            context,
            icon: isDarkMode
                ? Icons.dark_mode_outlined
                : Icons.light_mode_outlined,
            title: 'Theme',
            trailing: Switch(
              value: isDarkMode,
              onChanged: (val) {
                ref.read(themeNotifierProvider.notifier).toggleTheme(val);
              },
              activeThumbColor: AppPallete.primaryColor,
            ),
            onTap: () {
              ref.read(themeNotifierProvider.notifier).toggleTheme(!isDarkMode);
            },
          ),
          _buildActionTile(
            context,
            icon: Icons.notifications_none_rounded,
            title: 'Notifications',
            onTap: () => Navigator.pushNamed(
              context,
              NotificationSettingsPage.routeName,
            ),
          ),
        ]),
        const SizedBox(height: 24),
        _buildSectionHeader(context, 'Support'),
        _buildActionGroup(context, [
          _buildActionTile(
            context,
            icon: Icons.logout_rounded,
            title: 'Log Out',
            iconColor: AppPallete.errorColor,
            textColor: AppPallete.errorColor,
            onTap: () => _showLogoutDialog(context, ref),
          ),
        ]),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppPallete.getTextSecondary(context),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildActionGroup(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppPallete.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppPallete.getBorderColor(context).withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children.map((widget) => widget).toList()),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
    Color? iconColor,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppPallete.getSurfaceContainerLow(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor ?? AppPallete.getTextSecondary(context),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: textColor ?? AppPallete.getTextPrimary(context),
                ),
              ),
            ),
            if (trailing != null)
              trailing
            else
              Icon(
                Icons.chevron_right,
                size: 18,
                color: AppPallete.getTextSecondary(
                  context,
                ).withValues(alpha: 0.5),
              ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
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
