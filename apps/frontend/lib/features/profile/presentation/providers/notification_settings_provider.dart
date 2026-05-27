import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettings {
  final bool pushEnabled;
  final bool emailEnabled;
  final bool taskReminders;
  final bool goalProgress;

  NotificationSettings({
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.taskReminders = true,
    this.goalProgress = true,
  });

  NotificationSettings copyWith({
    bool? pushEnabled,
    bool? emailEnabled,
    bool? taskReminders,
    bool? goalProgress,
  }) {
    return NotificationSettings(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      taskReminders: taskReminders ?? this.taskReminders,
      goalProgress: goalProgress ?? this.goalProgress,
    );
  }
}

final notificationSettingsProvider = 
    AsyncNotifierProvider<NotificationSettingsNotifier, NotificationSettings>(() {
  return NotificationSettingsNotifier();
});

class NotificationSettingsNotifier extends AsyncNotifier<NotificationSettings> {
  static const _pushKey = 'push_enabled';
  static const _emailKey = 'email_enabled';
  static const _taskKey = 'task_reminders';
  static const _goalKey = 'goal_progress';

  @override
  Future<NotificationSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationSettings(
      pushEnabled: prefs.getBool(_pushKey) ?? true,
      emailEnabled: prefs.getBool(_emailKey) ?? true,
      taskReminders: prefs.getBool(_taskKey) ?? true,
      goalProgress: prefs.getBool(_goalKey) ?? true,
    );
  }

  Future<void> togglePush(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pushKey, value);
    state = AsyncValue.data(state.value!.copyWith(pushEnabled: value));
  }

  Future<void> toggleEmail(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_emailKey, value);
    state = AsyncValue.data(state.value!.copyWith(emailEnabled: value));
  }

  Future<void> toggleTaskReminders(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_taskKey, value);
    state = AsyncValue.data(state.value!.copyWith(taskReminders: value));
  }

  Future<void> toggleGoalProgress(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_goalKey, value);
    state = AsyncValue.data(state.value!.copyWith(goalProgress: value));
  }
}
