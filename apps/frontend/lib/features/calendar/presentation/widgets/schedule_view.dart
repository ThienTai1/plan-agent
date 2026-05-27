import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:frontend/features/goals/data/models/task_model.dart';
import 'package:intl/intl.dart';

class ScheduleView extends StatefulWidget {
  final Map<DateTime, List<TaskModel>> tasksByDate;
  final DateTime anchorDate;
  final DateTime focusedDate;
  final ValueChanged<DateTime>? onVisibleDateChanged;

  const ScheduleView({
    super.key,
    required this.tasksByDate,
    required this.anchorDate,
    required this.focusedDate,
    this.onVisibleDateChanged,
  });

  @override
  State<ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<ScheduleView> {
  late ScrollController _scrollController;
  final double _hourHeight = 80.0;
  final int _centerIndex = 100000; // 100,000 hours ~ 11 years from center

  @override
  void initState() {
    super.initState();
    // Calculate initial offset based on focusedDate relative to anchorDate
    final diffDays = widget.focusedDate.difference(widget.anchorDate).inDays;
    final initialIndex = _centerIndex + (diffDays * 24);

    // Scroll to 8 AM of the focused day
    _scrollController = ScrollController(
      initialScrollOffset: (initialIndex + 8) * _hourHeight,
    );
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant ScheduleView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!isSameDay(widget.focusedDate, oldWidget.focusedDate)) {
      // Check if we need to jump
      // Calculate current visible date
      // If difference is large, or if it was a user selection (which we assume if focusedDate changed), jump.
      // However, if focusedDate changed because WE scrolled, we shouldn't jump.
      // The parent handles this by only updating focusedDate on selection?
      // Let's assume parent passes selection.
      // But wait, parent also updates focusedDate on scroll (to keep them in sync).
      // We need to differentiate "User Tapped Date" vs "User Scrolled".
      // Actually, safely jumping to the new focusedDate is fine IF it matches the scroll position.
      // But if we are scrolling, we don't want to fight the scroll.

      // Improved logic:
      // The parent should probably ONLY pass focusedDate when it wants us to jump?
      // Or we check if the current scroll position is already close to the new focusedDate.

      final currentScrollOffset = _scrollController.offset;
      final diffDays = widget.focusedDate.difference(widget.anchorDate).inDays;
      final targetIndex = _centerIndex + (diffDays * 24);
      final targetOffset = (targetIndex + 8) * _hourHeight; // Target 8 AM

      // If the difference between current and target is more than 24 hours, or if we want to snap:
      if ((currentScrollOffset - targetOffset).abs() > _hourHeight * 24) {
        _scrollController.jumpTo(targetOffset);
      }
    }
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final offset = _scrollController.offset;
    final index = (offset / _hourHeight).floor();

    final diffHours = index - _centerIndex;
    final dayOffset = (diffHours / 24).floor();

    // Determine the visible date relative to anchorDate
    final date = widget.anchorDate.add(Duration(days: dayOffset));

    // Notify parent if the date changes
    if (widget.onVisibleDateChanged != null) {
      widget.onVisibleDateChanged!(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Infinite count
    const int itemCount = 200000;

    return ListView.builder(
      controller: _scrollController,
      itemCount: itemCount,
      itemExtent: _hourHeight,
      padding: const EdgeInsets.only(bottom: 100),
      itemBuilder: (context, index) {
        final int diffHours = index - _centerIndex;
        final int dayOffset = (diffHours / 24).floor();
        final int hour = diffHours - (dayOffset * 24);

        // Calculate the date for this slot relative to anchorDate
        final date = widget.anchorDate.add(Duration(days: dayOffset));
        final normalizedDate = DateTime(date.year, date.month, date.day);

        final isStartOfDay = hour == 0;

        // Get tasks
        final dayTasks = widget.tasksByDate[normalizedDate] ?? [];
        final tasksInHour = dayTasks.where((t) {
          final start = t.startTime ?? t.dueDate;
          return start != null && start.hour == hour;
        }).toList();

        return _buildHourSlot(
          context,
          normalizedDate,
          hour,
          tasksInHour,
          isStartOfDay,
        );
      },
    );
  }

  Widget _buildHourSlot(
    BuildContext context,
    DateTime date,
    int hour,
    List<TaskModel> tasks,
    bool isStartOfDay,
  ) {
    final timeString = '${hour.toString().padLeft(2, '0')}:00';

    return Container(
      decoration: isStartOfDay
          ? BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppPallete.getPrimaryColor(context),
                  width: 2,
                ),
              ),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Column
          SizedBox(
            width: 75,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    timeString,
                    style: TextStyle(
                      color: AppPallete.getTextSecondary(context),
                      fontSize: AppFontSizes.metadata,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isStartOfDay)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        DateFormat('MMM d').format(date),
                        style: TextStyle(
                          color: AppPallete.getPrimaryColor(context),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Vertical Line
          Container(
            width: 1,
            color: AppPallete.getBorderColor(context).withValues(alpha: 0.5),
          ),

          // Content
          Expanded(
            child: Stack(
              children: [
                // Horizontal Grid Line
                Container(
                  height: 1,
                  color: AppPallete.getBorderColor(
                    context,
                  ).withValues(alpha: 0.1),
                ),

                // Tasks
                if (tasks.isNotEmpty)
                  Positioned.fill(
                    top: 2,
                    bottom: 2,
                    left: 4,
                    right: 4,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: tasks.map((task) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: _buildTaskBlock(context, task),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskBlock(BuildContext context, TaskModel task) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppPallete.getPrimaryColor(context).withValues(alpha: 0.1),
        border: Border(
          left: BorderSide(
            color: AppPallete.getPrimaryColor(context),
            width: 3,
          ),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            task.title,
            style: TextStyle(
              fontSize: AppFontSizes.title,
              fontWeight: FontWeight.w700,
              color: AppPallete.getTextPrimary(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (task.startTime != null && task.dueDate != null)
            Text(
              '${DateFormat('HH:mm').format(task.startTime!)} - ${DateFormat('HH:mm').format(task.dueDate!)}',
              style: TextStyle(
                fontSize: AppFontSizes.tiny,
                color: AppPallete.getTextSecondary(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}
