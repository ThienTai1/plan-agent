import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:frontend/core/theme/app_pallete.dart';

class AppDatePickerSheet extends StatefulWidget {
  final String title;
  final String subtitle;
  final DateTimeRange? initialRange;
  final DateTime? initialDate;
  final bool isRange;

  const AppDatePickerSheet({
    super.key,
    required this.title,
    this.subtitle = '',
    this.initialRange,
    this.initialDate,
    this.isRange = true,
  });

  static Future<DateTimeRange?> showRange({
    required BuildContext context,
    required String title,
    String subtitle = '',
    DateTimeRange? initialRange,
  }) async {
    return showModalBottomSheet<DateTimeRange>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AppDatePickerSheet(
        title: title,
        subtitle: subtitle,
        initialRange: initialRange,
        isRange: true,
      ),
    );
  }

  static Future<DateTime?> showSingle({
    required BuildContext context,
    required String title,
    String subtitle = '',
    DateTime? initialDate,
  }) async {
    final range = await showModalBottomSheet<DateTimeRange>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AppDatePickerSheet(
        title: title,
        subtitle: subtitle,
        initialDate: initialDate,
        isRange: false,
      ),
    );
    return range?.start;
  }

  @override
  State<AppDatePickerSheet> createState() => _AppDatePickerSheetState();
}

class _AppDatePickerSheetState extends State<AppDatePickerSheet> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();
    if (widget.isRange) {
      _rangeStart = widget.initialRange?.start;
      _rangeEnd = widget.initialRange?.end;
      _focusedDay = _rangeStart ?? DateTime.now();
    } else {
      _rangeStart = widget.initialDate;
      _focusedDay = _rangeStart ?? DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppPallete.getBackgroundColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDragHandle(),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppPallete.getTextPrimary(context),
                        ),
                      ),
                      if (widget.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppPallete.getTextSecondary(context),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: AppPallete.getSecondarySurface(context),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TableCalendar(
              firstDay: DateTime(2000),
              lastDay: DateTime(2100),
              focusedDay: _focusedDay,
              rangeStartDay: _rangeStart,
              rangeEndDay: _rangeEnd,
              rangeSelectionMode: widget.isRange
                  ? RangeSelectionMode.toggledOn
                  : RangeSelectionMode.disabled,
              selectedDayPredicate: (day) =>
                  !widget.isRange && isSameDay(_rangeStart, day),
              onDaySelected: (selectedDay, focusedDay) {
                if (!widget.isRange) {
                  setState(() {
                    _rangeStart = selectedDay;
                    _rangeEnd = null;
                    _focusedDay = focusedDay;
                  });
                }
              },
              onRangeSelected: (start, end, focusedDay) {
                if (widget.isRange) {
                  setState(() {
                    _rangeStart = start;
                    _rangeEnd = end;
                    _focusedDay = focusedDay;
                  });
                }
              },
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppPallete.getTextPrimary(context),
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: AppPallete.getTextPrimary(context),
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: AppPallete.getTextPrimary(context),
                ),
              ),
              calendarStyle: CalendarStyle(
                rangeHighlightColor:
                    AppPallete.getPrimaryColor(context).withValues(alpha: 0.08),
                rangeStartDecoration: BoxDecoration(
                  color: AppPallete.getPrimaryColor(context),
                  shape: BoxShape.circle,
                ),
                rangeEndDecoration: BoxDecoration(
                  color: AppPallete.getPrimaryColor(context),
                  shape: BoxShape.circle,
                ),
                withinRangeTextStyle: TextStyle(
                  color: AppPallete.getPrimaryColor(context),
                ),
                todayDecoration: BoxDecoration(
                  color: AppPallete.getSurface(context),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppPallete.getPrimaryColor(context)
                        .withValues(alpha: 0.3),
                  ),
                ),
                todayTextStyle: TextStyle(
                  color: AppPallete.getPrimaryColor(context),
                  fontWeight: FontWeight.bold,
                ),
                weekendTextStyle: TextStyle(
                  color: AppPallete.getTextPrimary(context)
                      .withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppPallete.getSecondarySurface(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppPallete.getTextSecondary(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _rangeStart == null
                        ? null
                        : () {
                            Navigator.pop(
                              context,
                              DateTimeRange(
                                start: _rangeStart!,
                                end: _rangeEnd ?? _rangeStart!,
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppPallete.getPrimaryColor(context),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      widget.isRange ? 'Save Range' : 'Confirm Date',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppPallete.getTextMuted(context).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
