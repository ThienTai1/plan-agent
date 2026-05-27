import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/common/providers/app_user_notifier.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/features/goals/presentation/providers/goals_providers.dart';
import 'package:frontend/features/calendar/presentation/providers/calendar_repository_provider.dart';

// REFACTORED: These providers now use Repositories instead of raw SQL on local DB.
// We map the Domain Models back to Map<String, dynamic> to keep compatibility with existing UI.

final localUserIdProvider = Provider<String>((ref) {
  final user = ref.watch(appUserNotifierProvider);
  if (user != null) return user.id;

  // Fallback to Supabase session directly to avoid mismatch with PowerSync/Repo
  final session = Supabase.instance.client.auth.currentSession;
  if (session != null) return session.user.id;

  return '';
});

final activeGoalsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final repository = ref.watch(goalsRepositoryProvider);
  
  return repository.getActiveGoals().map((either) {
    return either.fold(
      (failure) => [],
      (goals) => goals.map((g) => {
        'id': g.id,
        'user_id': g.userId,
        'title': g.title,
        'current_state': g.currentState,
        'start_date': g.startDate.toIso8601String(),
        'end_date': g.endDate?.toIso8601String(),
        'status': g.status,
        'icon': g.icon,
        'custom_properties': g.customProperties,
      }).toList(),
    );
  });
});

final allGoalsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final repository = ref.watch(goalsRepositoryProvider);
  
  return repository.getAllGoals().map((either) {
    return either.fold(
      (failure) => [],
      (goals) => goals.map((g) => {
        'id': g.id,
        'user_id': g.userId,
        'title': g.title,
        'current_state': g.currentState,
        'start_date': g.startDate.toIso8601String(),
        'end_date': g.endDate?.toIso8601String(),
        'status': g.status,
        'icon': g.icon,
        'custom_properties': g.customProperties,
      }).toList(),
    );
  });
});

final todayPendingTasksProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final repository = ref.watch(goalsRepositoryProvider);
  
  return repository.getAllTasks().map((either) {
    return either.fold(
      (failure) => [],
      (tasks) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));
        
        return tasks.where((t) {
          if (t.isCompleted) return false;
          if (t.dueDate == null) return false;
          return t.dueDate!.isAfter(today.subtract(const Duration(seconds: 1))) && 
                 t.dueDate!.isBefore(tomorrow);
        }).map((t) => {
          'id': t.id,
          'user_id': t.userId,
          'goal_id': t.goalId,
          'phase_id': t.phaseId,
          'parent_task_id': t.parentTaskId,
          'title': t.title,
          'due_date': t.dueDate?.toIso8601String(),
          'is_completed': t.isCompleted ? 1 : 0,
          'priority': t.priority,
          'status': t.status,
          'custom_properties': t.customProperties,
        }).toList();
      },
    );
  });
});

final allTasksProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final repository = ref.watch(goalsRepositoryProvider);
  
  return repository.getAllTasks().map((either) {
    return either.fold(
      (failure) => [],
      (tasks) => tasks.map((t) => {
        'id': t.id,
        'user_id': t.userId,
        'goal_id': t.goalId,
        'phase_id': t.phaseId,
        'parent_task_id': t.parentTaskId,
        'title': t.title,
        'due_date': t.dueDate?.toIso8601String(),
        'is_completed': t.isCompleted ? 1 : 0,
        'priority': t.priority,
        'status': t.status,
        'custom_properties': t.customProperties,
      }).toList(),
    );
  });
});

final tasksByGoalProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, goalId) {
  final repository = ref.watch(goalsRepositoryProvider);
  
  return repository.getTasksByGoal(goalId).map((either) {
    return either.fold(
      (failure) => [],
      (tasks) => tasks.map((t) => {
        'id': t.id,
        'user_id': t.userId,
        'goal_id': t.goalId,
        'phase_id': t.phaseId,
        'parent_task_id': t.parentTaskId,
        'title': t.title,
        'due_date': t.dueDate?.toIso8601String(),
        'is_completed': t.isCompleted ? 1 : 0,
        'priority': t.priority,
        'status': t.status,
        'custom_properties': t.customProperties,
      }).toList(),
    );
  });
});

final goalTaskStatsProvider = StreamProvider.family<Map<String, int>, String>((ref, goalId) {
  final repository = ref.watch(goalsRepositoryProvider);
  
  return repository.getTasksByGoal(goalId).map((either) {
    return either.fold(
      (failure) => {'total': 0, 'completed': 0},
      (tasks) {
        final total = tasks.length;
        final completed = tasks.where((t) => t.isCompleted).length;
        return {'total': total, 'completed': completed};
      },
    );
  });
});

final phasesByGoalProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, goalId) {
  final repository = ref.watch(goalsRepositoryProvider);
  
  return repository.getPhasesByGoal(goalId).map((either) {
    return either.fold(
      (failure) => [],
      (phases) => phases.map((p) => {
        'id': p.id,
        'goal_id': p.goalId,
        'title': p.title,
        'order_index': p.orderIndex,
        'start_date': p.startDate.toIso8601String(),
        'end_date': p.endDate.toIso8601String(),
        'status': p.status,
      }).toList(),
    );
  });
});

final goalByIdProvider = StreamProvider.family<Map<String, dynamic>?, String>((ref, goalId) {
  final repository = ref.watch(goalsRepositoryProvider);
  
  return repository.getGoalById(goalId).map((either) {
    return either.fold(
      (failure) => null,
      (goal) => goal == null ? null : {
        'id': goal.id,
        'user_id': goal.userId,
        'title': goal.title,
        'current_state': goal.currentState,
        'start_date': goal.startDate.toIso8601String(),
        'end_date': goal.endDate?.toIso8601String(),
        'status': goal.status,
        'icon': goal.icon,
        'custom_properties': goal.customProperties,
      },
    );
  });
});

final upcomingEventsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final repository = ref.watch(eventRepositoryProvider);
  
  return repository.getUpcomingEvents().map((either) {
    return either.fold(
      (failure) => [],
      (events) => events.map((e) => {
        'id': e.id,
        'user_id': e.userId,
        'title': e.title,
        'description': e.description,
        'start_time': e.startTime.toIso8601String(),
        'end_time': e.endTime.toIso8601String(),
        'location': e.location,
        'color': e.color?.value,
        'is_all_day': e.isAllDay ? 1 : 0,
      }).toList(),
    );
  });
});

// ── Helper functions for parsing row data ─────────────────────────────

Map<String, dynamic>? parseCustomProperties(Map<String, dynamic> row) {
  final raw = row['custom_properties'];
  if (raw == null) return null;
  if (raw is Map<String, dynamic>) return raw;
  if (raw is String && raw.isNotEmpty) {
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }
  return null;
}

DateTime? parseOptionalDateTime(String? value) {
  if (value == null) return null;
  return DateTime.tryParse(value);
}

DateTime parseDateTime(String value) {
  return DateTime.parse(value);
}
