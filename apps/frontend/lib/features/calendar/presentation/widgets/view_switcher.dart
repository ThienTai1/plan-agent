import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_pallete.dart';

class ViewSwitcher extends StatelessWidget {
  final bool isScheduleView;
  final VoidCallback onToggle;

  const ViewSwitcher({
    super.key,
    required this.isScheduleView,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      height: 32,
      decoration: BoxDecoration(
        color: AppPallete.isDarkMode(context) 
            ? Colors.white10 
            : const Color(0xFFEFEFEF), // match light grey background in mockup
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppPallete.getBorderColor(context).withValues(alpha: 0.3),
        ),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: isScheduleView
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Container(
              width: (MediaQuery.of(context).size.width - 48) / 2,
              height: 32,
              decoration: BoxDecoration(
                color: AppPallete.isDarkMode(context) 
                    ? AppPallete.darkSurfaceColor 
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: isScheduleView ? onToggle : null,
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      'Daily',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: !isScheduleView
                            ? AppPallete.getTextPrimary(context)
                            : AppPallete.getTextSecondary(context),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: !isScheduleView ? onToggle : null,
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      'Schedule',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isScheduleView
                            ? AppPallete.getTextPrimary(context)
                            : AppPallete.getTextSecondary(context),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

