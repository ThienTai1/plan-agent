import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/notification_settings_provider.dart';

class NotificationSettingsPage extends ConsumerWidget {
  static const String routeName = '/notification-settings';
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(notificationSettingsProvider);

    return Scaffold(
      backgroundColor: AppPallete.getBackgroundColor(context),
      appBar: AppBar(
        title: Text('Notifications', style: GoogleFonts.jetBrainsMono(fontSize: 18, fontWeight: FontWeight.bold, color: AppPallete.getTextPrimary(context))),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: settingsAsync.when(
        data: (settings) => SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(context, 'General Notifications'),
              _buildNotificationGroup(context, [
                _buildNotificationTile(
                  context,
                  title: 'Push Notifications',
                  subtitle: 'Receive alerts on your device',
                  value: settings.pushEnabled,
                  onChanged: (val) => ref.read(notificationSettingsProvider.notifier).togglePush(val),
                ),
                _buildNotificationTile(
                  context,
                  title: 'Email Notifications',
                  subtitle: 'Receive updates via email',
                  value: settings.emailEnabled,
                  onChanged: (val) => ref.read(notificationSettingsProvider.notifier).toggleEmail(val),
                ),
              ]),
              const SizedBox(height: 32),
              _buildSectionHeader(context, 'Activity Updates'),
              _buildNotificationGroup(context, [
                _buildNotificationTile(
                  context,
                  title: 'Task Reminders',
                  subtitle: 'Alerts for upcoming task deadlines',
                  value: settings.taskReminders,
                  onChanged: (val) => ref.read(notificationSettingsProvider.notifier).toggleTaskReminders(val),
                ),
                _buildNotificationTile(
                  context,
                  title: 'Goal Progress',
                  subtitle: 'Monthly and weekly milestones progress',
                  value: settings.goalProgress,
                  onChanged: (val) => ref.read(notificationSettingsProvider.notifier).toggleGoalProgress(val),
                ),
              ]),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Note: Some critical security and account-related notifications cannot be disabled.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppPallete.getTextSecondary(context).withValues(alpha: 0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppPallete.getTextSecondary(context),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildNotificationGroup(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppPallete.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPallete.getBorderColor(context).withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          final index = entry.key;
          final widget = entry.value;
          return Column(
            children: [
              widget,
              if (index < children.length - 1)
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: AppPallete.getBorderColor(context).withValues(alpha: 0.05),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotificationTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppPallete.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppPallete.getTextSecondary(context).withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppPallete.primaryColor.withValues(alpha: 0.2),
            activeColor: AppPallete.primaryColor,
          ),
        ],
      ),
    );
  }
}
