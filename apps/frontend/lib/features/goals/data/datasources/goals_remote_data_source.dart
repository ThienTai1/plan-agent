import 'package:frontend/features/goals/data/models/goal_model.dart';
import 'package:frontend/features/goals/data/models/task_model.dart';

abstract class GoalsRemoteDataSource {
  Future<GoalModel> createGoal(GoalModel goal, String userId);

  Future<List<TaskModel>> getTasksByGoal(String goalId);
  Future<TaskModel> createTask(TaskModel task, String userId);
}
