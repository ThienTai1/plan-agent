import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_pallete.dart';
import 'package:frontend/features/calendar/presentation/widgets/timeline_calendar.dart';
import 'package:frontend/features/goals/data/models/task_model.dart';
import 'package:frontend/features/tasks/presentation/widgets/task_item_widget.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:frontend/features/tasks/presentation/pages/task_detail_page.dart';
import 'package:frontend/core/database/local_queries_providers.dart';
import 'dart:convert';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final allTasksAsync = ref.watch(allTasksProvider);

    return Scaffold(
      backgroundColor: AppPallete.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('Calendar'),
        backgroundColor: AppPallete.getSurface(context),
        actions: [
          IconButton(
            icon: Icon(
              _calendarFormat == CalendarFormat.month
                  ? Icons.calendar_view_week
                  : Icons.calendar_view_month,
            ),
            onPressed: () {
              setState(() {
                _calendarFormat = _calendarFormat == CalendarFormat.month
                    ? CalendarFormat.week
                    : CalendarFormat.month;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          TimelineCalendar(
            focusedDay: _focusedDay,
            selectedDate: _selectedDay,
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            calendarFormat: _calendarFormat,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
          const Divider(),
          Expanded(
            child: allTasksAsync.when(
              data: (taskEntries) {
                final taskModels = taskEntries.map(_taskModelFromRow).toList();
                final dailyTasks = taskModels.where((task) {
                  final taskDate = task.startTime ?? task.dueDate;
                  if (taskDate == null) return false;
                  return _isSameDay(taskDate, _selectedDay);
                }).toList();

                if (dailyTasks.isEmpty) {
                  return const Center(child: Text('No tasks for this day'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: dailyTasks.length,
                  itemBuilder: (context, index) {
                    final task = dailyTasks[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TaskItemWidget(
                        task: task,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TaskDetailPage(task: task),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) =>
                  const Center(child: Text('Error loading tasks')),
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  TaskModel _taskModelFromRow(Map<String, dynamic> row) {
    Map<String, dynamic>? custom;
    final raw = row['custom_properties'];
    if (raw != null) {
      if (raw is String && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) custom = decoded;
        } catch (_) {}
      } else if (raw is Map<String, dynamic>) {
        custom = raw;
      }
    }

    return TaskModel(
      id: row['id'] as String,
      userId: row['user_id'] as String? ?? '',
      goalId: row['goal_id'] as String?,
      phaseId: row['phase_id'] as String?,
      title: row['title'] as String,
      dueDate: parseOptionalDateTime(row['due_date'] as String?),
      isCompleted: (row['is_completed'] as int?) == 1,
      createdAt: row['created_at'] != null
          ? DateTime.parse(row['created_at'] as String)
          : DateTime.now(),
      priority: row['priority'] as String?,
      customProperties: custom,
    );
  }
}
