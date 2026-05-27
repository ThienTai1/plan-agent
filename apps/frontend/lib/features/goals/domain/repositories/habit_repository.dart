import 'package:fpdart/fpdart.dart';
import 'package:frontend/core/error/failures.dart';
import 'package:frontend/features/goals/domain/models/habit.dart';

abstract class HabitRepository {
  Stream<Either<Failure, List<Habit>>> getAllHabits();
  Future<Either<Failure, Habit>> createHabit(Habit habit);
  Future<Either<Failure, Habit>> updateHabit(Habit habit);
  Future<Either<Failure, Unit>> deleteHabit(String habitId);
  Future<Either<Failure, Habit>> toggleHabit(String habitId, DateTime date);
}
