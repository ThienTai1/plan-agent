import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:intl/intl.dart';

class DailyTimelineHeader extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime firstDay;
  final DateTime lastDay;
  final Function(DateTime) onDateSelected;
  final VoidCallback onTodayTap;

  const DailyTimelineHeader({
    super.key,
    required this.focusedDay,
    required this.firstDay,
    required this.lastDay,
    required this.onDateSelected,
    required this.onTodayTap,
  });

  @override
  Widget build(BuildContext context) {
    final monthYear = DateFormat('MMMM, yyyy').format(focusedDay);

    return Container(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: GestureDetector(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: focusedDay,
                    firstDate: firstDay,
                    lastDate: lastDay,
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.fromSeed(
                            seedColor: AppPallete.primaryColor,
                            brightness: AppPallete.isDarkMode(context)
                                ? Brightness.dark
                                : Brightness.light,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    onDateSelected(picked);
                  }
                },
                child: Text(
                  monthYear,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: AppFontSizes.subtitle, // around 18-20px
                    fontWeight: FontWeight.w800,
                    color: AppPallete.getTextPrimary(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

