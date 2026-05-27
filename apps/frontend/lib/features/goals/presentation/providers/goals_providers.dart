import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/goals/domain/models/habit.dart';
import 'package:frontend/features/goals/domain/repositories/habit_repository.dart';
import 'package:frontend/features/goals/domain/repositories/goals_repository.dart';
import 'package:frontend/features/goals/data/repositories/supabase_habit_repository_impl.dart';
import 'package:frontend/features/goals/data/repositories/supabase_goals_repository_impl.dart';
import 'package:frontend/features/auth/presentation/providers/auth_providers.dart';
import 'package:frontend/core/common/domain/models/task.dart';
import 'package:frontend/core/common/domain/models/goal.dart';
import 'package:frontend/features/goals/domain/models/phase.dart';

// Repositories
final goalsRepositoryProvider = Provider<GoalsRepository>((ref) {
  return SupabaseGoalsRepositoryImpl(
    ref.watch(authRemoteDataSourceProvider),
  );
});

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  return SupabaseHabitRepositoryImpl(
    ref.watch(authRemoteDataSourceProvider),
  );
});

final allHabitsProvider = StreamProvider.autoDispose<List<Habit>>((ref) {
  final repository = ref.watch(habitRepositoryProvider);
  return repository.getAllHabits().map(
    (either) => either.fold(
      (failure) => <Habit>[],
      (habits) => habits,
    ),
  );
});

final allTasksProvider = StreamProvider.autoDispose<List<Task>>((ref) {
  final repository = ref.watch(goalsRepositoryProvider);
  return repository.getAllTasks().map(
    (either) => either.fold(
      (failure) => <Task>[], // Return empty list on failure for now
      (tasks) => tasks,
    ),
  );
});

final allGoalsStreamProvider = StreamProvider.autoDispose<List<Goal>>((ref) {
  final repository = ref.watch(goalsRepositoryProvider);
  return repository.getAllGoals().map(
    (either) => either.fold((failure) => <Goal>[], (goals) => goals),
  );
});

final allPhasesStreamProvider = StreamProvider.autoDispose<List<Phase>>((ref) {
  final repository = ref.watch(goalsRepositoryProvider);
  return repository.getAllPhases().map(
    (either) => either.fold((failure) => <Phase>[], (phases) => phases),
  );
});

final tasksByParentProvider = StreamProvider.autoDispose.family<List<Task>, String>((
  ref,
  parentTaskId,
) {
  final repository = ref.watch(goalsRepositoryProvider);
  return repository
      .getTasksByParent(parentTaskId)
      .map((either) => either.fold((failure) => <Task>[], (tasks) => tasks));
});
