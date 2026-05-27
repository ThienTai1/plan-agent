import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/common/domain/models/task.dart';
import 'package:frontend/features/goals/presentation/providers/goals_providers.dart';
import 'package:frontend/core/services/notification_service.dart';
import 'package:frontend/features/profile/presentation/providers/notification_settings_provider.dart';

final tasksNotifierProvider = AsyncNotifierProvider<TasksNotifier, void>(() {
  return TasksNotifier();
});

class TasksNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Listen for notification settings changes to sync all notifications
    ref.listen(notificationSettingsProvider, (previous, next) {
      next.whenData((settings) {
        final wasEnabled = previous?.value?.pushEnabled ?? true;
        final wasTaskEnabled = previous?.value?.taskReminders ?? true;
        
        if (settings.pushEnabled != wasEnabled || settings.taskReminders != wasTaskEnabled) {
          if (!settings.pushEnabled || !settings.taskReminders) {
            ref.read(notificationServiceProvider).cancelAllNotifications();
            // If it was just taskReminders toggled off, but push is still on, 
            // we might want to keep other notifications, but for now cancelAll is safer.
          } else {
            _rescheduleAllTasks();
          }
        }
      });
    });
  }

  Future<void> _rescheduleAllTasks() async {
    final settings = ref.read(notificationSettingsProvider).value;
    final pushEnabled = settings?.pushEnabled ?? true;
    final taskRemindersEnabled = settings?.taskReminders ?? true;

    if (!pushEnabled || !taskRemindersEnabled) return;

    final tasks = ref.read(allTasksProvider).value;
    if (tasks == null) return;

    final notificationService = ref.read(notificationServiceProvider);
    final now = DateTime.now();

    for (final task in tasks) {
      if (!task.isCompleted && task.dueDate != null && task.dueDate!.isAfter(now)) {
        notificationService.scheduleNotification(
          id: task.id.hashCode,
          title: 'Task Reminder',
          body: task.title,
          scheduledDate: task.dueDate!,
          offsetMinutes: 10,
        );
      }
    }
  }

  Future<void> createTask(Task task) async {
    state = const AsyncValue.loading();
    final repository = ref.read(goalsRepositoryProvider);
    final res = await repository.createTask(task);

    res.fold((l) => state = AsyncValue.error(l.message, StackTrace.current), (
      r,
    ) {
      state = const AsyncValue.data(null);
      
      final settings = ref.read(notificationSettingsProvider).value;
      final pushEnabled = settings?.pushEnabled ?? true;
      final taskRemindersEnabled = settings?.taskReminders ?? true;

      if (pushEnabled && taskRemindersEnabled && task.dueDate != null && task.dueDate!.isAfter(DateTime.now())) {
        ref
            .read(notificationServiceProvider)
            .scheduleNotification(
              id: task.id.hashCode,
              title: 'Task Reminder',
              body: task.title,
              scheduledDate: task.dueDate!,
              offsetMinutes: 10,
            );
      }
    });
  }

  Future<void> updateTask(Task task) async {
    final repository = ref.read(goalsRepositoryProvider);

    // Handle Recurrence: If task is being completed and has a recurrence rule,
    // we move it to the next date instead of marking it finished.
    Task taskToUpdate = task;
    // bool wasRescheduled = false;

    /* if (task.isCompleted &&
        task.recurrenceRule != null &&
        task.recurrenceRule!.toLowerCase() != 'none') {
      final nextDate = _calculateNextDate(
        task.dueDate ?? DateTime.now(),
        task.recurrenceRule!,
      );
      if (nextDate != null) {
        taskToUpdate = task.copyWith(
          dueDate: nextDate,
          isCompleted: false,
          status: 'todo',
          updatedAt: DateTime.now(),
        );
        wasRescheduled = true;
      }
    } */

    final res = await repository.updateTask(taskToUpdate);

    res.fold((l) => state = AsyncValue.error(l.message, StackTrace.current), (
      r,
    ) {
      state = const AsyncValue.data(null);

      final settings = ref.read(notificationSettingsProvider).value;
      final pushEnabled = settings?.pushEnabled ?? true;
      final taskRemindersEnabled = settings?.taskReminders ?? true;

      if (taskToUpdate.isCompleted) {
        ref
            .read(notificationServiceProvider)
            .cancelNotification(taskToUpdate.id.hashCode);
      } else if (pushEnabled &&
          taskRemindersEnabled &&
          taskToUpdate.dueDate != null &&
          taskToUpdate.dueDate!.isAfter(DateTime.now())) {
        ref.read(notificationServiceProvider).scheduleNotification(
              id: taskToUpdate.id.hashCode,
              title: 'Task Reminder',
              body: taskToUpdate.title,
              scheduledDate: taskToUpdate.dueDate!,
              offsetMinutes: 10,
            );
      }
    });
  }

  /* DateTime? _calculateNextDate(DateTime current, String rule) {
    try {
      switch (rule.toLowerCase()) {
        case 'daily':
          return current.add(const Duration(days: 1));
        case 'weekly':
          return current.add(const Duration(days: 7));
        case 'monthly':
          // Simple month increment
          return DateTime(current.year, current.month + 1, current.day);
        default:
          return null;
      }
    } catch (e) {
      return current.add(const Duration(days: 1)); // Fallback to daily
    }
  } */
}
