import 'package:fpdart/fpdart.dart' hide Task;
import 'package:frontend/core/error/exceptions.dart';
import 'package:frontend/core/error/failures.dart';
import 'package:frontend/features/goals/data/datasources/goals_remote_data_source.dart';
import 'package:frontend/core/common/domain/models/goal.dart';
import 'package:frontend/core/common/domain/models/task.dart';
import 'package:frontend/features/goals/domain/models/phase.dart';
import 'package:frontend/features/goals/domain/repositories/goals_repository.dart';
import 'package:frontend/features/goals/data/models/goal_model.dart';
import 'package:frontend/features/goals/data/models/task_model.dart';
import 'package:frontend/features/auth/data/datasources/auth_remote_data_source.dart';

class GoalsRepositoryImpl implements GoalsRepository {
  final GoalsRemoteDataSource remoteDataSource;
  final AuthRemoteDataSource authDataSource;

  GoalsRepositoryImpl(this.remoteDataSource, this.authDataSource);

  @override
  Stream<Either<Failure, List<Goal>>> getAllGoals() {
    return Stream.value(const Right([]));
  }

  @override
  Stream<Either<Failure, List<Goal>>> getActiveGoals() {
    return Stream.value(const Right([]));
  }

  @override
  Stream<Either<Failure, Goal?>> getGoalById(String goalId) {
    return Stream.value(const Right(null));
  }

  Future<String?> _getUserId() async {
    final session = authDataSource.currentUserSession;
    return session?.user.id;
  }

  @override
  Future<Either<Failure, Goal>> createGoal(Goal goal) async {
    try {
      final userId = await _getUserId();
      if (userId == null) return left(Failure('User not logged in'));

      final goalModel = GoalModel(
        id: goal.id,
        userId: userId,
        title: goal.title,
        currentState: goal.currentState,
        startDate: goal.startDate,
        endDate: goal.endDate,
        status: goal.status,
        createdAt: goal.createdAt,
        updatedAt: goal.updatedAt,
      );
      final result = await remoteDataSource.createGoal(goalModel, userId);
      return right(result as Goal);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, Goal>> updateGoal(Goal goal) async {
    return left(Failure('updateGoal is not implemented for remote repository'));
  }

  @override
  Future<Either<Failure, Unit>> deleteGoal(String goalId) async {
    return left(Failure('deleteGoal is not implemented for remote repository'));
  }

  @override
  Stream<Either<Failure, List<Phase>>> getAllPhases() {
    return Stream.value(left(Failure('Not implemented')));
  }

  @override
  Future<Either<Failure, Phase>> createPhase(Phase phase) async {
    return left(Failure('Phases not yet supported in DB'));
  }

  @override
  Stream<Either<Failure, List<Phase>>> getPhasesByGoal(String goalId) {
    return Stream.value(const Right([]));
  }

  @override
  Future<Either<Failure, Phase>> updatePhase(Phase phase) async {
    return left(Failure('updatePhase not implemented for remote repository'));
  }

  @override
  Future<Either<Failure, Unit>> deletePhase(String phaseId) async {
    return left(Failure('deletePhase not implemented for remote repository'));
  }

  @override
  Future<Either<Failure, Task>> createTask(Task task) async {
    try {
      final userId = await _getUserId();
      if (userId == null) return left(Failure('User not logged in'));

      final taskModel = TaskModel(
        id: task.id,
        userId: userId,
        title: task.title,
        goalId: task.goalId,
        phaseId: task.phaseId,
        parentTaskId: task.parentTaskId,
        dueDate: task.dueDate,
        isCompleted: task.isCompleted,
        createdAt: task.createdAt,
        priority: task.priority,
        customProperties: task.customProperties,
      );

      final result = await remoteDataSource.createTask(taskModel, userId);
      return right(result as Task);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Stream<Either<Failure, List<Task>>> getTasksByGoal(String goalId) {
    return Stream.fromFuture(remoteDataSource.getTasksByGoal(goalId))
        .map<Either<Failure, List<Task>>>(
          (result) => right(result.cast<Task>()),
        )
        .handleError((e) => left(Failure(e.toString())));
  }

  @override
  Stream<Either<Failure, List<Task>>> getTasksByPhase(String phaseId) {
    return Stream.value(const Right([]));
  }

  @override
  Stream<Either<Failure, List<Task>>> getTasksByParent(String parentTaskId) {
    return Stream.value(const Right([]));
  }

  @override
  Stream<Either<Failure, List<Task>>> getAllTasks() {
    return Stream.value(const Right([]));
  }

  @override
  Future<Either<Failure, Task>> updateTask(Task task) async {
    return left(Failure('updateTask is not implemented for remote repository'));
  }

  @override
  Future<Either<Failure, Unit>> deleteTask(String taskId) async {
    return left(Failure('deleteTask is not implemented for remote repository'));
  }
}
