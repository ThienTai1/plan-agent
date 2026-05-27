import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/common/domain/models/notification_model.dart';
import 'package:frontend/core/common/presentation/providers/notification_provider.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  static Route route() {
    return MaterialPageRoute(
      builder: (_) => const NotificationsPage(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationProvider);

    return Scaffold(
      backgroundColor: AppPallete.getSurface(context),
      appBar: AppBar(
        backgroundColor: AppPallete.getSurface(context),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppPallete.getTextPrimary(context),
            size: 20,
          ),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppPallete.getTextPrimary(context),
          ),
        ),
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () {
                ref.read(notificationProvider.notifier).markAllAsRead();
              },
              child: Text(
                'Mark all as read',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppPallete.getPrimaryColor(context),
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                return _NotificationItem(
                  notification: notifications[index],
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: AppPallete.getTextMuted(context).withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'All caught up!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppPallete.getTextSecondary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No new notifications at the moment.',
            style: TextStyle(
              fontSize: 14,
              color: AppPallete.getTextMuted(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationItem extends ConsumerStatefulWidget {
  final NotificationModel notification;

  const _NotificationItem({required this.notification});

  @override
  ConsumerState<_NotificationItem> createState() => _NotificationItemState();
}

class _NotificationItemState extends ConsumerState<_NotificationItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('jm').format(widget.notification.timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          if (!widget.notification.isRead) {
            ref
                .read(notificationProvider.notifier)
                .markAsRead(widget.notification.id);
          }
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.notification.isRead
                ? Colors.transparent
                : AppPallete.getSurfaceContainerLow(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.notification.isRead
                  ? AppPallete.getBorderColor(context).withValues(alpha: 0.1)
                  : AppPallete.getPrimaryColor(context).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIcon(context),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                widget.notification.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppPallete.getTextPrimary(context),
                                ),
                              ),
                            ),
                            Text(
                              timeStr,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppPallete.getTextMuted(context),
                              ),
                            ),
                          ],
                        ),
                        if (!_isExpanded) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.notification.message,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppPallete.getTextSecondary(context),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!widget.notification.isRead)
                    Padding(
                      padding: const EdgeInsets.only(left: 8, top: 2),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppPallete.getPrimaryColor(context),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              if (_isExpanded) ...[
                const SizedBox(height: 12),
                Text(
                  widget.notification.message,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppPallete.getTextSecondary(context),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppPallete.getBorderColor(
                          context,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.notification.type.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppPallete.getTextMuted(context),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('MMM d, yyyy').format(
                        widget.notification.timestamp,
                      ),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppPallete.getTextMuted(context),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    IconData icon;
    Color color;

    switch (widget.notification.type) {
      case NotificationType.success:
        icon = Icons.check_circle_rounded;
        color = Colors.green;
        break;
      case NotificationType.warning:
        icon = Icons.warning_rounded;
        color = Colors.orange;
        break;
      case NotificationType.reminder:
        icon = Icons.alarm_rounded;
        color = AppPallete.getPrimaryColor(context);
        break;
      case NotificationType.info:
        icon = Icons.info_rounded;
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 20,
        color: color,
      ),
    );
  }
}
