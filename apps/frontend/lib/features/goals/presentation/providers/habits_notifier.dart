import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/goals/domain/models/habit.dart';
import 'package:frontend/features/goals/presentation/providers/goals_providers.dart';

final habitsNotifierProvider = AsyncNotifierProvider<HabitsNotifier, void>(() {
  return HabitsNotifier();
});

class HabitsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    return;
  }

  Future<void> createHabit(Habit habit) async {
    state = const AsyncValue.loading();
    final repository = ref.read(habitRepositoryProvider);
    final res = await repository.createHabit(habit);

    res.fold(
      (l) => state = AsyncValue.error(l.message, StackTrace.current),
      (r) => state = const AsyncValue.data(null),
    );
  }

  Future<void> updateHabit(Habit habit) async {
    final repository = ref.read(habitRepositoryProvider);
    final res = await repository.updateHabit(habit);

    res.fold(
      (l) => state = AsyncValue.error(l.message, StackTrace.current),
      (r) => state = const AsyncValue.data(null),
    );
  }

  Future<void> toggleHabit(String habitId, DateTime date) async {
    final repository = ref.read(habitRepositoryProvider);
    final res = await repository.toggleHabit(habitId, date);

    res.fold(
      (l) => state = AsyncValue.error(l.message, StackTrace.current),
      (r) => state = const AsyncValue.data(null),
    );
  }

  Future<void> deleteHabit(String habitId) async {
    final repository = ref.read(habitRepositoryProvider);
    final res = await repository.deleteHabit(habitId);

    res.fold(
      (l) => state = AsyncValue.error(l.message, StackTrace.current),
      (r) => state = const AsyncValue.data(null),
    );
  }
}
