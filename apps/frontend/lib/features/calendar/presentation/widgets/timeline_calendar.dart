import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class TimelineCalendar extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime selectedDate;
  final DateTime firstDay;
  final DateTime lastDay;
  final CalendarFormat calendarFormat;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(CalendarFormat) onFormatChanged;
  final Function(DateTime) onPageChanged;

  const TimelineCalendar({
    super.key,
    required this.focusedDay,
    required this.selectedDate,
    required this.firstDay,
    required this.lastDay,
    required this.calendarFormat,
    required this.onDaySelected,
    required this.onFormatChanged,
    required this.onPageChanged,
  });

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Widget _buildDayCard(
    BuildContext context,
    DateTime day,
    bool isSelected,
    bool isToday, {
    bool isOutside = false,
  }) {
    final dayNumber = day.day.toString(); // 22

    final isDarkMode = AppPallete.isDarkMode(context);

    // Unselected state is now transparent for a minimalist look
    final bgColor = isSelected
        ? AppPallete.getTextPrimary(context)
        : Colors.transparent;

    final numberColor = isSelected
        ? AppPallete.getBackgroundColor(context)
        : (isOutside
              ? AppPallete.getTextPrimary(context).withValues(alpha: 0.3)
              : AppPallete.getTextPrimary(context));

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12), // More rounded
            boxShadow: isSelected && !isDarkMode
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              dayNumber,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: numberColor,
                height: 1.0,
              ),
            ),
          ),
        ),
        if (isToday && !isSelected)
          Positioned(
            bottom: 2,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: AppPallete.getPrimaryColor(context),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
      ), 
      child: TableCalendar(
        firstDay: firstDay,
        lastDay: lastDay,
        focusedDay: focusedDay,
        calendarFormat: calendarFormat,
        selectedDayPredicate: (day) => _isSameDay(selectedDate, day),
        onDaySelected: onDaySelected,
        onFormatChanged: onFormatChanged,
        onPageChanged: onPageChanged,
        daysOfWeekVisible: true, // Visible now
        rowHeight: 52, // More compact
        daysOfWeekHeight: 32,
        
        daysOfWeekStyle: DaysOfWeekStyle(
          dowTextFormatter: (date, locale) => DateFormat.E(locale).format(date).toUpperCase(),
          weekdayStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppPallete.getTextSecondary(context).withValues(alpha: 0.6),
            letterSpacing: 0.8,
          ),
          weekendStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppPallete.getTextSecondary(context).withValues(alpha: 0.6),
            letterSpacing: 0.8,
          ),
        ),

        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) =>
              _buildDayCard(context, day, false, false),
          selectedBuilder: (context, day, focusedDay) =>
              _buildDayCard(context, day, true, false),
          todayBuilder: (context, day, focusedDay) =>
              _buildDayCard(context, day, false, true),
          outsideBuilder: (context, day, focusedDay) =>
              _buildDayCard(context, day, false, false, isOutside: true),
        ),
        availableCalendarFormats: const {
          CalendarFormat.month: 'Month',
          CalendarFormat.week: 'Week',
        },
        headerVisible: false,
      ),
    );
  }
}
