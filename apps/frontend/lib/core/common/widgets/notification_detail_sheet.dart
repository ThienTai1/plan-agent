import 'package:flutter/material.dart';
import 'package:frontend/core/common/domain/models/notification_model.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:frontend/core/common/widgets/app_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class NotificationDetailSheet extends StatelessWidget {
  final NotificationModel notification;

  const NotificationDetailSheet({super.key, required this.notification});

  static Future<void> show(BuildContext context, NotificationModel notification) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NotificationDetailSheet(notification: notification),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullDateStr = DateFormat('MMMM d, yyyy').format(notification.timestamp);
    final timeStr = DateFormat('jm').format(notification.timestamp);

    return Container(
      decoration: BoxDecoration(
        color: AppPallete.getSurface(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppPallete.getBorderColor(context).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Icon and Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                _buildIcon(context),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    notification.title,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppPallete.getTextPrimary(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Detail Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // Message Card
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Message',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppPallete.getTextMuted(context),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: AppPallete.getTextPrimary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Meta Info Card (Date & Type)
                AppCard(
                  child: Column(
                    children: [
                      _buildMetaRow(
                        context,
                        label: 'Received',
                        value: '$fullDateStr at $timeStr',
                        icon: Icons.calendar_today_outlined,
                      ),
                      const Divider(height: 24, thickness: 0.5),
                      _buildMetaRow(
                        context,
                        label: 'Category',
                        value: notification.type.name.toUpperCase(),
                        icon: Icons.label_outline_rounded,
                        isPill: true,
                        pillColor: _getTypeColor(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Action Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPallete.getPrimaryColor(context),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Dismiss',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    bool isPill = false,
    Color? pillColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppPallete.getTextMuted(context)),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppPallete.getTextMuted(context),
          ),
        ),
        const Spacer(),
        if (isPill)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: (pillColor ?? AppPallete.getPrimaryColor(context))
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: pillColor ?? AppPallete.getTextPrimary(context),
              ),
            ),
          )
        else
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppPallete.getTextPrimary(context),
            ),
          ),
      ],
    );
  }

  Widget _buildIcon(BuildContext context) {
    IconData icon;
    Color color = _getTypeColor(context);

    switch (notification.type) {
      case NotificationType.success:
        icon = Icons.check_circle_rounded;
        break;
      case NotificationType.warning:
        icon = Icons.warning_rounded;
        break;
      case NotificationType.reminder:
        icon = Icons.alarm_rounded;
        break;
      case NotificationType.info:
        icon = Icons.info_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 28,
        color: color,
      ),
    );
  }

  Color _getTypeColor(BuildContext context) {
    switch (notification.type) {
      case NotificationType.success:
        return Colors.green;
      case NotificationType.warning:
        return Colors.orange;
      case NotificationType.reminder:
        return AppPallete.getPrimaryColor(context);
      case NotificationType.info:
        return Colors.blue;
    }
  }
}
