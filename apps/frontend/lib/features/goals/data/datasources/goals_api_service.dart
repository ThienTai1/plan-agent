import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend/core/config/api_config.dart';
import 'package:frontend/core/common/domain/models/goal.dart';
import 'package:frontend/features/goals/domain/models/phase.dart';
import 'package:frontend/features/goals/domain/models/task.dart';

class GoalsApiService {
  final String baseUrl;

  GoalsApiService({String? baseUrl}) : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  /// Get all goals for the current user
  Future<List<Goal>> getGoals(String token) async {
    final url = Uri.parse(ApiConfig.getFullUrl('/goals'));
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Handle both list and paginated response
      final items = data is List
          ? data
          : (data['items'] as List<dynamic>? ?? []);
      return items
          .map((item) => Goal.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to load goals');
    }
  }

  /// Get a single goal by ID with phases and tasks
  Future<Goal> getGoalById(String token, String goalId) async {
    final url = Uri.parse(ApiConfig.getFullUrl('/goals/$goalId'));
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return Goal.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to load goal');
    }
  }

  /// Create a new goal
  Future<Goal> createGoal(String token, Map<String, dynamic> goalData) async {
    final url = Uri.parse(ApiConfig.getFullUrl('/goals'));
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(goalData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Goal.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to create goal');
    }
  }

  /// Update an existing goal
  Future<Goal> updateGoal(
    String token,
    String goalId,
    Map<String, dynamic> goalData,
  ) async {
    final url = Uri.parse(ApiConfig.getFullUrl('/goals/$goalId'));
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(goalData),
    );

    if (response.statusCode == 200) {
      return Goal.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to update goal');
    }
  }

  /// Delete a goal
  Future<void> deleteGoal(String token, String goalId) async {
    final url = Uri.parse(ApiConfig.getFullUrl('/goals/$goalId'));
    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to delete goal');
    }
  }

  /// Get phases for a goal
  Future<List<Phase>> getPhases(String token, String goalId) async {
    final url = Uri.parse(ApiConfig.getFullUrl('/goals/$goalId/phases'));
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final items = data is List
          ? data
          : (data['items'] as List<dynamic>? ?? []);
      return items
          .map((item) => Phase.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to load phases');
    }
  }

  /// Get tasks for a phase
  Future<List<Task>> getTasks(String token, String phaseId) async {
    final url = Uri.parse(ApiConfig.getFullUrl('/phases/$phaseId/tasks'));
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final items = data is List
          ? data
          : (data['items'] as List<dynamic>? ?? []);
      return items
          .map((item) => Task.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to load tasks');
    }
  }

  /// Create a new task
  Future<Task> createTask(String token, Map<String, dynamic> taskData) async {
    final url = Uri.parse(ApiConfig.getFullUrl('/tasks'));
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(taskData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Task.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to create task');
    }
  }

  /// Update a task
  Future<Task> updateTask(
    String token,
    String taskId,
    Map<String, dynamic> taskData,
  ) async {
    final url = Uri.parse(ApiConfig.getFullUrl('/tasks/$taskId'));
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(taskData),
    );

    if (response.statusCode == 200) {
      return Task.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to update task');
    }
  }

  /// Delete a task
  Future<void> deleteTask(String token, String taskId) async {
    final url = Uri.parse(ApiConfig.getFullUrl('/tasks/$taskId'));
    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to delete task');
    }
  }
}
