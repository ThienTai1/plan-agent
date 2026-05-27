import 'package:frontend/core/error/exceptions.dart';
import 'package:frontend/features/goals/data/datasources/goals_remote_data_source.dart';
import 'package:frontend/features/goals/data/models/goal_model.dart';
import 'package:frontend/features/goals/data/models/task_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GoalsRemoteDataSourceImpl implements GoalsRemoteDataSource {
  final SupabaseClient supabaseClient;

  GoalsRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<GoalModel> createGoal(GoalModel goal, String userId) async {
    try {
      final data = await supabaseClient
          .from('goals')
          .insert({...goal.toJson(), 'user_id': userId})
          .select()
          .single();
      return GoalModel.fromJson(data);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<TaskModel> createTask(TaskModel task, String userId) async {
    try {
      final data = await supabaseClient
          .from('tasks')
          .insert({...task.toJson(), 'user_id': userId})
          .select()
          .single();
      return TaskModel.fromJson(data);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<TaskModel>> getTasksByGoal(String goalId) async {
    try {
      final data = await supabaseClient
          .from('tasks')
          .select()
          .eq('goal_id', goalId);

      return data.map((json) => TaskModel.fromJson(json)).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
