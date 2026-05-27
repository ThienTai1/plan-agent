import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_pallete.dart';

class ScheduleView extends StatelessWidget {
  const ScheduleView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppPallete.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 32),
          _buildCalendarGrid(context),
          const SizedBox(height: 32),
          _buildScheduleList(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            'February',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.chevron_left_rounded, color: AppPallete.greyColor),
        const Icon(Icons.chevron_right_rounded, color: AppPallete.greyColor),
        const Spacer(),
        const Icon(Icons.sync_rounded, color: AppPallete.greyColor, size: 24),
        const SizedBox(width: 16),
        const Icon(
          Icons.add_circle_outline_rounded,
          color: AppPallete.greyColor,
          size: 24,
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(BuildContext context) {
    final List<String> days = ['1', '2', '3', '4', '5', '6', '7'];
    final List<String> datesRow1 = ['8', '9', '10', '11', '12', '13', '14'];
    final List<String> datesRow2 = ['15', '16', '17', '18', '19', '20', '21'];
    final List<String> datesRow3 = ['22', '23', '24', '25', '26', '27', '28'];
    final List<String> datesRow4 = ['29', '30', '31', '', '', '', ''];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: days
              .map((day) => Expanded(child: _buildDayHeader(day)))
              .toList(),
        ),
        const SizedBox(height: 24),
        _buildDateRow(context, datesRow1, []),
        _buildDateRow(context, datesRow2, ['18', '19', '20', '21']),
        _buildDateRow(context, datesRow3, ['22', '23', '24', '25', '26', '27']),
        _buildDateRow(context, datesRow4, []),
      ],
    );
  }

  Widget _buildDayHeader(String day) {
    return Center(
      child: Text(
        day,
        style: TextStyle(
          color: AppPallete.greyColor.withValues(alpha: 0.5),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDateRow(
    BuildContext context,
    List<String> dates,
    List<String> inRange,
  ) {
    final onSurface = AppPallete.getOnSurface(context);
    final surface = AppPallete.getSurface(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: dates.map((date) {
          if (date.isEmpty) {
            return const Expanded(child: SizedBox(height: 48));
          }

          final isSelected = date == '18' || date == '28';
          final isInRange = inRange.contains(date);
          final isRangeStart = date == '18' || date == '22';
          final isRangeEnd = date == '21' || date == '28';

          return Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: isInRange && !isSelected
                    ? AppPallete.getSecondarySurface(
                        context,
                      ).withValues(alpha: 0.8)
                    : Colors.transparent,
                borderRadius: BorderRadius.horizontal(
                  left: isRangeStart ? const Radius.circular(24) : Radius.zero,
                  right: isRangeEnd || date == '27'
                      ? const Radius.circular(24)
                      : Radius.zero,
                ),
              ),
              child: Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected ? onSurface : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      date,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected ? surface : onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildScheduleList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildScheduleHeader(context, 'WEDNESDAY 13'),
        const SizedBox(height: 16),
        _buildScheduleItem(
          context,
          '8:00',
          '17:00',
          'Assigment Deadline',
          'History of UX design',
          AppPallete.statusUrgentText,
        ),
        _buildScheduleItem(
          context,
          '17:00',
          '19:30',
          'Class Cancelled',
          'Basics of Marketing',
          AppPallete.statusInReviewText,
        ),
        const SizedBox(height: 24),
        _buildScheduleHeader(context, 'THURSDAY 14'),
        const SizedBox(height: 16),
        _buildScheduleItem(
          context,
          '19:00',
          '21:00',
          'Basketball Training',
          'S033 Sport Hall 07',
          AppPallete.statusInProgressText,
        ),
        _buildScheduleItem(
          context,
          '22:00',
          '-',
          'Dinner with Diana',
          '',
          AppPallete.statusCompletedText,
        ),
      ],
    );
  }

  Widget _buildScheduleHeader(BuildContext context, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: AppPallete.borderColor),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppPallete.getOnSurface(context),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleItem(
    BuildContext context,
    String startTime,
    String endTime,
    String title,
    String subtitle,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 45,
            child: Column(
              children: [
                Text(
                  startTime,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppPallete.greyColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  endTime,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppPallete.greyColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppPallete.getOnSurface(context),
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppPallete.greyColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
