import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/common/presentation/providers/notification_provider.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:google_fonts/google_fonts.dart';


class HomeHeader extends StatelessWidget {
  final String? userName;
  final VoidCallback onNotificationTap;
  final VoidCallback? onTodayTap;
  const HomeHeader({
    super.key,
    this.userName,
    required this.onNotificationTap,
    this.onTodayTap,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      color: Colors.transparent,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: AppFontSizes.label,
                      fontWeight: FontWeight.w600,
                      color: AppPallete.getTextSecondary(context),
                    ),
                  ),
                  if (userName != null)
                    Text(
                      userName!,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: AppFontSizes.subtitle,
                        fontWeight: FontWeight.w800,
                        color: AppPallete.getTextPrimary(context),
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              if (onTodayTap != null) ...[
                IconButton(
                  icon: Icon(
                    Icons.calendar_today_rounded,
                    size: 22,
                    color: AppPallete.getTextPrimary(context),
                  ),
                  onPressed: onTodayTap,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 16),
              ],
              Consumer(
                builder: (context, ref, child) {
                  final unreadCount = ref.watch(
                    unreadNotificationsCountProvider,
                  );
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: Icon(
                          unreadCount > 0
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_none_rounded,
                          size: 26,
                          color: unreadCount > 0
                              ? AppPallete.getPrimaryColor(context)
                              : AppPallete.getTextPrimary(context),
                        ),
                        onPressed: onNotificationTap,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppPallete.getErrorColor(context),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppPallete.getSurface(context),
                                width: 2,
                              ),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Center(
                              child: Text(
                                unreadCount > 9 ? '9+' : '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
