import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/common/domain/models/task.dart' as core_task;
import 'package:frontend/core/common/providers/app_user_notifier.dart';
import 'package:frontend/core/database/local_queries_providers.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:frontend/features/home/presentation/providers/home_navigation_provider.dart';
import 'package:frontend/features/calendar/presentation/widgets/daily_timeline_header.dart';
import 'package:frontend/features/calendar/presentation/widgets/timeline_calendar.dart';
import 'package:frontend/features/home/presentation/widgets/home_header.dart';
import 'package:frontend/features/home/presentation/widgets/pinned_projects_section.dart';
import 'package:frontend/features/goals/data/models/task_model.dart';
import 'package:frontend/features/tasks/presentation/pages/task_detail_page.dart';
import 'package:frontend/features/tasks/presentation/widgets/daily_tasks_list.dart';
import 'package:frontend/features/goals/presentation/providers/goals_providers.dart'
    hide allTasksProvider;
import 'package:frontend/features/home/presentation/pages/notifications_page.dart';
import 'package:table_calendar/table_calendar.dart';

class DailyTimelinePage extends ConsumerStatefulWidget {
  const DailyTimelinePage({super.key});

  @override
  ConsumerState<DailyTimelinePage> createState() => _DailyTimelinePageState();
}

class _DailyTimelinePageState extends ConsumerState<DailyTimelinePage> {
  late DateTime _selectedDate;
  late DateTime _focusedDay;
  CalendarFormat _calendarFormat = CalendarFormat.week;
  final DateTime _firstDay = DateTime.utc(2020, 1, 1);
  final DateTime _lastDay = DateTime.utc(2100, 12, 31);

  // We use a large offset center to simulate infinite scroll
  // Day 0 is _selectedDate at init.
  // Index = (Date - StartDate).inDays
  // But standard infinite list usually centers at an index, e.g. 10000.
  // Let's use PageController for DayView? No, user wants vertical scroll across days.
  // So it's one giant vertical list of hours.
  // We need to listen to scroll position to determine "Current Day".

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = now;
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(appUserNotifierProvider);

    final allTasksAsync = ref.watch(allTasksProvider);
    final allGoalsAsync = ref.watch(allGoalsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Fixed Header Area
            Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: AppPallete.getBorderColor(
                      context,
                    ).withValues(alpha: 0.2), // Softer divider
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  HomeHeader(
                    userName: user?.fullName ?? user?.username,
                    onNotificationTap: () {
                      Navigator.push(context, NotificationsPage.route());
                    },
                    onTodayTap: () {
                      setState(() {
                        _focusedDay = DateTime.now();
                        _selectedDate = DateTime(
                          _focusedDay.year,
                          _focusedDay.month,
                          _focusedDay.day,
                        );
                      });
                    },
                  ),
                  DailyTimelineHeader(
                    focusedDay: _focusedDay,
                    firstDay: _firstDay,
                    lastDay: _lastDay,
                    onDateSelected: (date) {
                      setState(() {
                        _focusedDay = date;
                        _selectedDate = date;
                      });
                      // TODO: Scroll ScheduleView to this date
                    },
                    onTodayTap: () {
                      setState(() {
                        _focusedDay = DateTime.now();
                        _selectedDate = DateTime.now();
                      });
                    },
                  ),
                  TimelineCalendar(
                    focusedDay: _focusedDay,
                    selectedDate: _selectedDate,
                    firstDay: _firstDay,
                    lastDay: _lastDay,
                    calendarFormat: _calendarFormat,
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDate = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onFormatChanged: (format) {
                      if (_calendarFormat != format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      }
                    },
                    onPageChanged: (focusedDay) {
                      setState(() {
                        _focusedDay = focusedDay;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            Expanded(
              child: NotificationListener<UserScrollNotification>(
                onNotification: (notification) {
                  final ScrollDirection direction = notification.direction;
                  if (direction == ScrollDirection.reverse) {
                    if (_calendarFormat != CalendarFormat.week) {
                      setState(() {
                        _calendarFormat = CalendarFormat.week;
                      });
                    }
                  } else if (direction == ScrollDirection.forward) {
                    if (notification.metrics.pixels <= 0 &&
                        _calendarFormat != CalendarFormat.month) {
                      setState(() {
                        _calendarFormat = CalendarFormat.month;
                      });
                    }
                  }
                  return true;
                },
                child: allTasksAsync.when(
                  data: (taskEntries) {
                    final taskModels = taskEntries
                        .map((row) => TaskModel.fromJson(row))
                        .toList();

                    // Filter for Tasks List (Single Day)
                    final dailyTasks =
                        taskModels.where((task) {
                          final start = task.startTime ?? task.dueDate;
                          final end = task.dueDate ?? task.startTime;

                          if (start == null || end == null) return false;

                          // Normalize to date-only for comparison
                          final startDate = DateTime(
                            start.year,
                            start.month,
                            start.day,
                          );
                          final endDate = DateTime(
                            end.year,
                            end.month,
                            end.day,
                          );

                          return (startDate.isBefore(_selectedDate) ||
                                  _isSameDay(startDate, _selectedDate)) &&
                              (endDate.isAfter(_selectedDate) ||
                                  _isSameDay(endDate, _selectedDate));
                        }).toList()..sort((a, b) {
                          final aTime =
                              a.startTime ?? a.dueDate ?? DateTime(2100);
                          final bTime =
                              b.startTime ?? b.dueDate ?? DateTime(2100);
                          return aTime.compareTo(bTime);
                        });

                    return SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            // Add bottom padding for Navbar (64 height + 24 margin + extra)
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                PinnedProjectsSection(
                                  onSeeAllTap: () {
                                    ref
                                        .read(homeNavigationProvider.notifier)
                                        .setIndex(1);
                                  },
                                ),
                                const SizedBox(height: 32),
                                allGoalsAsync.when(
                                  data: (goals) {
                                    final goalTitleById = <String, String>{
                                      for (final g in goals)
                                        g['id'] as String: g['title'] as String,
                                    };
                                    return DailyTasksList(
                                      tasks: dailyTasks,
                                      goalTitleById: goalTitleById,
                                      onSeeAllTap: () {
                                        ref
                                            .read(homeNavigationProvider.notifier)
                                            .setIndex(2);
                                      },
                                      onTaskTap: (task) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                TaskDetailPage(task: task),
                                          ),
                                        );
                                      },
                                      onToggleStatus: (task) async {
                                        final coreTask = core_task.Task(
                                          id: task.id,
                                          userId: task.userId ?? '',
                                          title: task.title,
                                          dueDate: task.dueDate,
                                          isCompleted: !task.isCompleted,
                                          priority: task.priority,
                                          status:
                                              !task.isCompleted
                                                  ? 'done'
                                                  : 'todo',
                                          createdAt: task.createdAt,
                                          updatedAt: DateTime.now(),
                                          customProperties:
                                              task.customProperties,
                                        );
                                        await ref
                                            .read(goalsRepositoryProvider)
                                            .updateTask(coreTask);
                                      },
                                    );
                                  },
                                  loading: () => const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                  error: (err, _) => Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      'Could not load goals',
                                      style: TextStyle(
                                        color: AppPallete.getTextSecondary(
                                          context,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) =>
                      const Center(child: Text('Could not load tasks')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
