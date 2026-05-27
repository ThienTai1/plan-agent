import 'package:flutter/foundation.dart';
import 'package:frontend/features/goals/data/datasources/goals_api_service.dart';
import 'package:frontend/core/common/domain/models/goal.dart';
import 'package:frontend/features/goals/domain/models/task.dart';

class GoalsProvider with ChangeNotifier {
  final GoalsApiService _apiService;
  String? _token;
  
  List<Goal> _goals = [];
  Goal? _currentGoal;
  bool _isLoading = false;
  String? _error;

  GoalsProvider({GoalsApiService? apiService, String? token})
      : _apiService = apiService ?? GoalsApiService(),
        _token = token;

  // Getters
  List<Goal> get goals => _goals;
  Goal? get currentGoal => _currentGoal;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Set authentication token
  void setToken(String token) {
    _token = token;
  }

  /// Load all goals for the current user
  Future<void> loadGoals() async {
    if (_token == null) {
      _error = 'Not authenticated';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _goals = await _apiService.getGoals(_token!);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Load a single goal with phases and tasks
  Future<void> loadGoalById(String goalId) async {
    if (_token == null) {
      _error = 'Not authenticated';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentGoal = await _apiService.getGoalById(_token!, goalId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Create a new goal
  Future<Goal> createGoal(Map<String, dynamic> goalData) async {
    if (_token == null) {
      throw Exception('Not authenticated');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newGoal = await _apiService.createGoal(_token!, goalData);
      _goals.add(newGoal);
      _isLoading = false;
      notifyListeners();
      return newGoal;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Update an existing goal
  Future<void> updateGoal(String goalId, Map<String, dynamic> goalData) async {
    if (_token == null) {
      throw Exception('Not authenticated');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedGoal = await _apiService.updateGoal(_token!, goalId, goalData);
      final index = _goals.indexWhere((g) => g.id == goalId);
      if (index != -1) {
        _goals[index] = updatedGoal;
      }
      if (_currentGoal?.id == goalId) {
        _currentGoal = updatedGoal;
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Delete a goal
  Future<void> deleteGoal(String goalId) async {
    if (_token == null) {
      throw Exception('Not authenticated');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deleteGoal(_token!, goalId);
      _goals.removeWhere((g) => g.id == goalId);
      if (_currentGoal?.id == goalId) {
        _currentGoal = null;
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Create a new task
  Future<Task> createTask(Map<String, dynamic> taskData) async {
    if (_token == null) {
      throw Exception('Not authenticated');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newTask = await _apiService.createTask(_token!, taskData);
      _isLoading = false;
      notifyListeners();
      return newTask;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Update a task
  Future<void> updateTask(String taskId, Map<String, dynamic> taskData) async {
    if (_token == null) {
      throw Exception('Not authenticated');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.updateTask(_token!, taskId, taskData);
      // Reload current goal to get updated task
      if (_currentGoal != null) {
        await loadGoalById(_currentGoal!.id);
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Delete a task
  Future<void> deleteTask(String taskId) async {
    if (_token == null) {
      throw Exception('Not authenticated');
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deleteTask(_token!, taskId);
      // Reload current goal to reflect deletion
      if (_currentGoal != null) {
        await loadGoalById(_currentGoal!.id);
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

