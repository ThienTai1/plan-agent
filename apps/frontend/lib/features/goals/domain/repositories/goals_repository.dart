import 'package:fpdart/fpdart.dart' hide Task;
import 'package:frontend/core/error/failures.dart';
import 'package:frontend/core/common/domain/models/goal.dart';
import 'package:frontend/core/common/domain/models/task.dart';
import 'package:frontend/features/goals/domain/models/phase.dart';

abstract class GoalsRepository {
  // Goal
  Stream<Either<Failure, List<Goal>>> getAllGoals();
  Stream<Either<Failure, List<Goal>>> getActiveGoals();
  Stream<Either<Failure, Goal?>> getGoalById(String goalId);
  Future<Either<Failure, Goal>> createGoal(Goal goal);
  Future<Either<Failure, Goal>> updateGoal(Goal goal);
  Future<Either<Failure, Unit>> deleteGoal(String goalId);

  // Phase
  Stream<Either<Failure, List<Phase>>> getPhasesByGoal(String goalId);
  Stream<Either<Failure, List<Phase>>> getAllPhases();
  Future<Either<Failure, Phase>> createPhase(Phase phase);
  Future<Either<Failure, Phase>> updatePhase(Phase phase);
  Future<Either<Failure, Unit>> deletePhase(String phaseId);

  // Task
  Stream<Either<Failure, List<Task>>> getTasksByGoal(String goalId);
  Stream<Either<Failure, List<Task>>> getTasksByPhase(String phaseId);
  Stream<Either<Failure, List<Task>>> getTasksByParent(String parentTaskId);
  Stream<Either<Failure, List<Task>>> getAllTasks();
  Future<Either<Failure, Task>> createTask(Task task);
  Future<Either<Failure, Task>> updateTask(Task task);
  Future<Either<Failure, Unit>> deleteTask(String taskId);
}
