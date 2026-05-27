import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/database/local_queries_providers.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:frontend/features/goals/data/models/task_model.dart';
import 'package:frontend/core/common/domain/models/goal.dart';
import 'package:frontend/features/tasks/presentation/pages/task_detail_page.dart';
import 'package:frontend/features/tasks/presentation/widgets/task_item_widget.dart';

class GoalTimelinePage extends ConsumerStatefulWidget {
  final Goal goal;

  const GoalTimelinePage({super.key, required this.goal});

  @override
  ConsumerState<GoalTimelinePage> createState() => _GoalTimelinePageState();
}

class _GoalTimelinePageState extends ConsumerState<GoalTimelinePage> {
  static const double _minPixelsPerDay = 6;
  static const double _maxPixelsPerDay = 160;
  static const double _yearOverviewThreshold = 22;
  static const double _weekOverviewThreshold = 78;

  static const double _backlogHeaderHeight = 46;
  static const double _dayHeaderHeight = 28;
  static const double _taskTileHeight = 96;
  static const double _taskGap = 10;
  static const int _daysRangePadding = 14;

  final ScrollController _scrollController = ScrollController();
  double _pixelsPerDay = 104;
  double _scaleAtGestureStart = 1.0;
  double _pixelsPerDayAtGestureStart = 104;

  bool get _isYearOverview => _pixelsPerDay <= _yearOverviewThreshold;
  bool get _isWeekOverview =>
      !_isYearOverview && _pixelsPerDay < _weekOverviewThreshold;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksByGoalProvider(widget.goal.id));

    return Scaffold(
      backgroundColor: AppPallete.getBackgroundColor(context),
      appBar: AppBar(
        title: Text('${widget.goal.title} Timeline'),
        backgroundColor: AppPallete.getSurface(context),
      ),
      body: tasksAsync.when(
        data: (rows) {
          final tasks = rows.map(_taskFromRow).toList();
          final withDate = tasks.where((t) => _eventTime(t) != null).toList();
          final undated = tasks.where((t) => _eventTime(t) == null).toList();

          if (tasks.isEmpty) {
            return Center(
              child: Text(
                'No tasks for this goal yet',
                style: TextStyle(
                  color: AppPallete.getTextSecondary(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          final groupedByDay = <DateTime, List<TaskModel>>{};
          for (final task in withDate) {
            final dt = _eventTime(task)!;
            final day = DateTime(dt.year, dt.month, dt.day);
            groupedByDay.putIfAbsent(day, () => <TaskModel>[]).add(task);
          }

          for (final list in groupedByDay.values) {
            list.sort((a, b) {
              final at = _eventTime(a)!;
              final bt = _eventTime(b)!;
              return at.compareTo(bt);
            });
          }

          final sortedDays = groupedByDay.keys.toList()..sort();
          final range = _resolveDayRange(sortedDays);
          final content = _buildTimelineContent(
            context: context,
            rangeStart: range.$1,
            rangeEnd: range.$2,
            groupedByDay: groupedByDay,
            undated: undated,
          );

          return GestureDetector(
            onScaleStart: (details) {
              _scaleAtGestureStart = 1.0;
              _pixelsPerDayAtGestureStart = _pixelsPerDay;
            },
            onScaleUpdate: (details) {
              if (!_scrollController.hasClients) return;

              final oldMax = _scrollController.position.maxScrollExtent;
              final oldViewport = _scrollController.position.viewportDimension;
              final oldOffset = _scrollController.offset;
              final focalY = details.localFocalPoint.dy.clamp(0.0, oldViewport);
              final oldDenominator = oldMax + oldViewport;
              final anchorProgress = oldDenominator <= 0
                  ? 0.0
                  : ((oldOffset + focalY) / oldDenominator).clamp(0.0, 1.0);

              final nextPixelsPerDay =
                  (_pixelsPerDayAtGestureStart *
                          (details.scale / _scaleAtGestureStart))
                      .clamp(_minPixelsPerDay, _maxPixelsPerDay);
              if ((nextPixelsPerDay - _pixelsPerDay).abs() < 0.5) return;

              setState(() => _pixelsPerDay = nextPixelsPerDay);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!_scrollController.hasClients) return;
                final newMax = _scrollController.position.maxScrollExtent;
                final newViewport =
                    _scrollController.position.viewportDimension;
                final newDenominator = newMax + newViewport;
                final nextOffset = (anchorProgress * newDenominator - focalY)
                    .clamp(0.0, newMax);
                _scrollController.jumpTo(nextOffset);
              });
            },
            child: content,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text(
            'Could not load timeline: $err',
            style: TextStyle(color: AppPallete.getErrorColor(context)),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineContent({
    required BuildContext context,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required Map<DateTime, List<TaskModel>> groupedByDay,
    required List<TaskModel> undated,
  }) {
    if (_isYearOverview) {
      return _buildYearOverview(
        context: context,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
        groupedByDay: groupedByDay,
        undated: undated,
      );
    }
    return _buildDayTimeline(
      context: context,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
      groupedByDay: groupedByDay,
      undated: undated,
    );
  }

  Widget _buildDayTimeline({
    required BuildContext context,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required Map<DateTime, List<TaskModel>> groupedByDay,
    required List<TaskModel> undated,
  }) {
    final days = <DateTime>[];
    for (
      DateTime d = rangeStart;
      !d.isAfter(rangeEnd);
      d = d.add(const Duration(days: 1))
    ) {
      days.add(d);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: days.length + (undated.isNotEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        if (undated.isNotEmpty && index == 0) {
          return _buildBacklogLane(context, undated);
        }

        final dayIndex = undated.isNotEmpty ? index - 1 : index;
        final day = days[dayIndex];
        final dayTasks = groupedByDay[day] ?? const <TaskModel>[];

        if (_isWeekOverview) {
          return _buildCompactDayBucket(
            context: context,
            day: day,
            dayTasks: dayTasks,
          );
        }

        return _buildDayBucket(
          context: context,
          day: day,
          dayTasks: dayTasks,
          bucketHeight: _dayHeight(dayTasks.length),
        );
      },
    );
  }

  Widget _buildYearOverview({
    required BuildContext context,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required Map<DateTime, List<TaskModel>> groupedByDay,
    required List<TaskModel> undated,
  }) {
    final groupedByMonth = <DateTime, List<TaskModel>>{};
    groupedByDay.forEach((day, list) {
      final monthKey = DateTime(day.year, day.month);
      groupedByMonth.putIfAbsent(monthKey, () => <TaskModel>[]).addAll(list);
    });

    final months = <DateTime>[];
    var cursor = DateTime(rangeStart.year, rangeStart.month);
    final end = DateTime(rangeEnd.year, rangeEnd.month);
    while (!cursor.isAfter(end)) {
      months.add(cursor);
      cursor = (cursor.month == 12)
          ? DateTime(cursor.year + 1, 1)
          : DateTime(cursor.year, cursor.month + 1);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: months.length + (undated.isNotEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        if (undated.isNotEmpty && index == 0) {
          return _buildBacklogLane(context, undated);
        }
        final monthIndex = undated.isNotEmpty ? index - 1 : index;
        final month = months[monthIndex];
        final monthTasks = groupedByMonth[month] ?? const <TaskModel>[];
        return _buildMonthBucket(
          context: context,
          month: month,
          monthTasks: monthTasks,
        );
      },
    );
  }

  Widget _buildBacklogLane(BuildContext context, List<TaskModel> tasks) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppPallete.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppPallete.getBorderColor(context).withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: _backlogHeaderHeight,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: AppPallete.getSecondarySurface(context),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Text(
              'Backlog (No date)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppPallete.getTextSecondary(context),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: tasks
                  .map(
                    (task) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TaskItemWidget(
                        task: task,
                        onTap: () => _openTask(task),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDayBucket({
    required BuildContext context,
    required DateTime day,
    required List<TaskModel> dayTasks,
  }) {
    final counts = _statusCounts(dayTasks);
    final height = _compactDayHeight;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      height: height,
      decoration: BoxDecoration(
        color: AppPallete.getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppPallete.getBorderColor(context).withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 88,
            padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
            decoration: BoxDecoration(
              color: AppPallete.getSecondarySurface(context),
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(14),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatDay(day),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppPallete.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${day.day}/${day.month}',
                  style: TextStyle(
                    fontSize: AppFontSizes.metadata,
                    fontWeight: FontWeight.w600,
                    color: AppPallete.getTextSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  _buildCountPill(
                    context,
                    icon: Icons.check_circle_outline_rounded,
                    label: '${counts.$1}',
                    color: AppPallete.statusCompletedText,
                  ),
                  const SizedBox(width: 6),
                  _buildCountPill(
                    context,
                    icon: Icons.timelapse_rounded,
                    label: '${counts.$2}',
                    color: AppPallete.statusInProgressText,
                  ),
                  const SizedBox(width: 6),
                  _buildCountPill(
                    context,
                    icon: Icons.radio_button_unchecked_rounded,
                    label: '${counts.$3}',
                    color: AppPallete.getTextSecondary(context),
                  ),
                  const Spacer(),
                  Text(
                    '${dayTasks.length} tasks',
                    style: TextStyle(
                      fontSize: AppFontSizes.metadata,
                      fontWeight: FontWeight.w700,
                      color: AppPallete.getTextSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayBucket({
    required BuildContext context,
    required DateTime day,
    required List<TaskModel> dayTasks,
    required double bucketHeight,
  }) {
    final dayLabel = _formatDay(day);
    final dateLabel = '${day.day}/${day.month}/${day.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      height: bucketHeight,
      decoration: BoxDecoration(
        color: AppPallete.getCardColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppPallete.getBorderColor(context).withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 86,
            padding: const EdgeInsets.fromLTRB(10, 10, 8, 8),
            decoration: BoxDecoration(
              color: AppPallete.getSecondarySurface(context),
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppPallete.getTextPrimary(context),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  dateLabel,
                  style: TextStyle(
                    fontSize: AppFontSizes.metadata,
                    fontWeight: FontWeight.w600,
                    color: AppPallete.getTextSecondary(context),
                  ),
                ),
                const Spacer(),
                Text(
                  '${dayTasks.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppPallete.getPrimaryColor(context),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: dayTasks.isEmpty
                ? Center(
                    child: Text(
                      'No tasks',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppPallete.getTextMuted(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                    itemCount: dayTasks.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: _taskGap),
                    itemBuilder: (context, index) {
                      final task = dayTasks[index];
                      return SizedBox(
                        height: _taskTileHeight,
                        child: TaskItemWidget(
                          task: task,
                          onTap: () => _openTask(task),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthBucket({
    required BuildContext context,
    required DateTime month,
    required List<TaskModel> monthTasks,
  }) {
    final counts = _statusCounts(monthTasks);
    final total = monthTasks.length;
    final monthLabel = _formatMonth(month);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppPallete.getCardColor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppPallete.getBorderColor(context).withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(
              monthLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppPallete.getTextPrimary(context),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$total tasks',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppPallete.getTextSecondary(context),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildCountPill(
                      context,
                      icon: Icons.check_rounded,
                      label: '${counts.$1}',
                      color: AppPallete.statusCompletedText,
                    ),
                    const SizedBox(width: 6),
                    _buildCountPill(
                      context,
                      icon: Icons.timelapse_rounded,
                      label: '${counts.$2}',
                      color: AppPallete.statusInProgressText,
                    ),
                    const SizedBox(width: 6),
                    _buildCountPill(
                      context,
                      icon: Icons.radio_button_unchecked_rounded,
                      label: '${counts.$3}',
                      color: AppPallete.getTextSecondary(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountPill(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppPallete.getSecondarySurface(context),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: AppFontSizes.metadata,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _openTask(TaskModel task) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskDetailPage(task: task)),
    );
  }

  double get _compactDayHeight {
    final h = _pixelsPerDay;
    if (h < 34) return 34;
    if (h > 72) return 72;
    return h;
  }

  double _dayHeight(int tasksCount) {
    final base = _pixelsPerDay;
    final tasksHeight = tasksCount == 0
        ? 0.0
        : (tasksCount * _taskTileHeight) + ((tasksCount - 1) * _taskGap);
    final contentMin = _dayHeaderHeight + tasksHeight + 20;
    return base > contentMin ? base : contentMin;
  }

  (DateTime, DateTime) _resolveDayRange(List<DateTime> sortedDays) {
    if (sortedDays.isEmpty) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      return (
        today.subtract(const Duration(days: 7)),
        today.add(const Duration(days: 7)),
      );
    }

    final first = sortedDays.first.subtract(
      const Duration(days: _daysRangePadding),
    );
    final last = sortedDays.last.add(const Duration(days: _daysRangePadding));
    return (
      DateTime(first.year, first.month, first.day),
      DateTime(last.year, last.month, last.day),
    );
  }

  (int, int, int) _statusCounts(List<TaskModel> tasks) {
    var done = 0;
    var inProgress = 0;
    var todo = 0;
    for (final t in tasks) {
      final status = (t.status ?? '').toLowerCase();
      if (t.isCompleted || status == 'done') {
        done++;
      } else if (status == 'in_progress') {
        inProgress++;
      } else {
        todo++;
      }
    }
    return (done, inProgress, todo);
  }

  TaskModel _taskFromRow(Map<String, dynamic> row) => TaskModel.fromJson(row);

  DateTime? _eventTime(TaskModel task) => task.startTime ?? task.dueDate;

  String _formatDay(DateTime d) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[d.weekday - 1];
  }

  String _formatMonth(DateTime d) {
    const labels = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${labels[d.month - 1]} ${d.year}';
  }
}
