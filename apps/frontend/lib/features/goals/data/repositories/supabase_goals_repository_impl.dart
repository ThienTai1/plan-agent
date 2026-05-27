import 'dart:convert';
import 'package:fpdart/fpdart.dart' hide Task;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/core/error/failures.dart';
import 'package:frontend/core/common/domain/models/goal.dart';
import 'package:frontend/core/common/domain/models/task.dart';
import 'package:frontend/features/goals/domain/models/phase.dart';
import 'package:frontend/features/goals/domain/repositories/goals_repository.dart';
import 'package:frontend/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxdart/rxdart.dart';

/// Goals repository that calls Supabase REST directly (no PowerSync).
class SupabaseGoalsRepositoryImpl implements GoalsRepository {
  final AuthRemoteDataSource authDataSource;
  final _uuid = const Uuid();

  SupabaseGoalsRepositoryImpl(this.authDataSource);

  SupabaseClient get _client => Supabase.instance.client;

  String? _getUserId() {
    final session = authDataSource.currentUserSession;
    return session?.user.id;
  }

  static const _goalsCacheKey = 'cached_goals_list';

  Future<void> _cacheGoals(List<Map<String, dynamic>> rows) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_goalsCacheKey, jsonEncode(rows));
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> _getCachedGoals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_goalsCacheKey);
      if (cached != null) {
        return List<Map<String, dynamic>>.from(jsonDecode(cached));
      }
    } catch (_) {}
    return [];
  }

  String _persistedTaskStatus(Task task) {
    final status = task.status?.trim().toLowerCase();
    if (task.isCompleted || status == 'done' || status == 'completed') {
      return 'done';
    }
    if (status == 'in_progress' || status == 'in-progress') {
      return 'in_progress';
    }
    return 'todo';
  }

  // ─── GOAL ────────────────────────────────────────────────────────────

  @override
  Stream<Either<Failure, List<Goal>>> getAllGoals() {
    final userId = _getUserId();
    if (userId == null) return Stream.value(left(Failure('User not logged in')));
    
    // Combine offline cache and online stream
    return Rx.concat([
      // Emit cached data first
      Stream.fromFuture(_getCachedGoals()).map((rows) => right(rows.map(_goalFromRow).toList())),
      // Then listen to the real-time stream
      _client
          .from('goals')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .map<Either<Failure, List<Goal>>>(
            (rows) {
              // Cache for next time
              _cacheGoals(rows);
              
              final sortedRows = List<Map<String, dynamic>>.from(rows)
                ..sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));
              
              return right(sortedRows.map(_goalFromRow).toList());
            },
          )
          .handleError((e) {
            // If stream fails, we still have the cached data emitted earlier (or we could re-emit)
            return left(Failure(e.toString()));
          }),
    ]);
  }

  @override
  Stream<Either<Failure, List<Goal>>> getActiveGoals() {
    final userId = _getUserId();
    if (userId == null) return Stream.value(left(Failure('User not logged in')));

    return _client
        .from('goals')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map<Either<Failure, List<Goal>>>(
          (rows) {
            final activeGoals = rows
                .where((row) => row['status'] == 'active')
                .toList()
              ..sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));
            
            return right(activeGoals.map(_goalFromRow).toList());
          },
        )
        .handleError((e) => left(Failure(e.toString())));
  }

  @override
  Stream<Either<Failure, Goal?>> getGoalById(String goalId) {
    return _client
        .from('goals')
        .stream(primaryKey: ['id'])
        .eq('id', goalId)
        .map<Either<Failure, Goal?>>(
          (rows) => right(rows.isEmpty ? null : _goalFromRow(rows.first)),
        )
        .handleError((e) => left(Failure(e.toString())));
  }

  @override
  Future<Either<Failure, Goal>> createGoal(Goal goal) async {
    try {
      final userId = _getUserId();
      if (userId == null) return left(Failure('User not logged in'));

      final id = goal.id.isEmpty ? _uuid.v4() : goal.id;
      final now = DateTime.now().toIso8601String();

      final data = {
        'id': id,
        'user_id': userId,
        'title': goal.title,
        'current_state': goal.currentState,
        'start_date': goal.startDate.toIso8601String(),
        'end_date': goal.endDate?.toIso8601String(),
        'status': goal.status,
        'created_at': now,
        'updated_at': now,
        'icon': goal.icon,
        'custom_properties': goal.customProperties,
      };

      final row = await _client.from('goals').insert(data).select().single();
      return right(_goalFromRow(row));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Goal>> updateGoal(Goal goal) async {
    try {
      final now = DateTime.now().toIso8601String();

      final row = await _client
          .from('goals')
          .update({
            'title': goal.title,
            'current_state': goal.currentState,
            'start_date': goal.startDate.toIso8601String(),
            'end_date': goal.endDate?.toIso8601String(),
            'status': goal.status,
            'updated_at': now,
            'icon': goal.icon,
            'custom_properties': goal.customProperties,
          })
          .eq('id', goal.id)
          .select()
          .single();

      return right(_goalFromRow(row));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteGoal(String goalId) async {
    try {
      await _client.from('goals').delete().eq('id', goalId);
      return right(unit);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  // ─── TASK ────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, Task>> createTask(Task task) async {
    try {
      final userId = task.userId.isNotEmpty
          ? task.userId
          : (_getUserId() ?? '');
      final id = task.id.isEmpty ? _uuid.v4() : task.id;
      final now = DateTime.now().toIso8601String();

      final data = {
        'id': id,
        'user_id': userId,
        'goal_id': _toUuid(task.goalId),
        'phase_id': _toUuid(task.phaseId),
        'parent_task_id': _toUuid(task.parentTaskId),
        'title': task.title,
        'description': task.description,
        'due_date': task.dueDate?.toIso8601String(),
        'status': _persistedTaskStatus(task),
        'is_completed': task.isCompleted,
        'priority': task.priority,
        'created_at': now,
        'updated_at': now,
        'custom_properties': task.customProperties,
      };

      final row = await _client.from('tasks').insert(data).select().single();
      return right(_taskFromRow(row));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Task>> updateTask(Task task) async {
    try {
      final now = DateTime.now().toIso8601String();

      final row = await _client
          .from('tasks')
          .update({
            'goal_id': _toUuid(task.goalId),
            'phase_id': _toUuid(task.phaseId),
            'parent_task_id': _toUuid(task.parentTaskId),
            'title': task.title,
            'description': task.description,
            'due_date': task.dueDate?.toIso8601String(),
            'status': _persistedTaskStatus(task),
            'is_completed': task.isCompleted,
            'priority': task.priority,
            'updated_at': now,
            'custom_properties': task.customProperties,
          })
          .eq('id', task.id)
          .select()
          .single();

      return right(_taskFromRow(row));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteTask(String taskId) async {
    try {
      await _client.from('tasks').delete().eq('id', taskId);
      return right(unit);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<Task>>> getTasksByGoal(String goalId) {
    final userId = _getUserId();
    if (userId == null) return Stream.value(left(Failure('User not logged in')));
    
    return _client
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map<Either<Failure, List<Task>>>(
          (rows) => right(
            rows
                .where((row) => row['goal_id'] == goalId)
                .map(_taskFromRow)
                .toList(),
          ),
        )
        .handleError((e) => left(Failure(e.toString())));
  }

  @override
  Stream<Either<Failure, List<Task>>> getTasksByPhase(String phaseId) {
    final userId = _getUserId();
    if (userId == null) return Stream.value(left(Failure('User not logged in')));

    return _client
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map<Either<Failure, List<Task>>>(
          (rows) => right(
            rows
                .where((row) => row['phase_id'] == phaseId)
                .map(_taskFromRow)
                .toList(),
          ),
        )
        .handleError((e) => left(Failure(e.toString())));
  }

  @override
  Stream<Either<Failure, List<Task>>> getTasksByParent(String parentTaskId) {
    final userId = _getUserId();
    if (userId == null) return Stream.value(left(Failure('User not logged in')));

    return _client
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map<Either<Failure, List<Task>>>(
          (rows) => right(
            rows
                .where((row) => row['parent_task_id'] == parentTaskId)
                .map(_taskFromRow)
                .toList(),
          ),
        )
        .handleError((e) => left(Failure(e.toString())));
  }

  @override
  Stream<Either<Failure, List<Task>>> getAllTasks() {
    final userId = _getUserId();
    if (userId == null) return Stream.value(left(Failure('User not logged in')));

    return _client
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map<Either<Failure, List<Task>>>(
          (rows) => right(rows.map(_taskFromRow).toList()),
        )
        .handleError((e) => left(Failure(e.toString())));
  }

  // ─── PHASE ───────────────────────────────────────────────────────────

  @override
  Stream<Either<Failure, List<Phase>>> getAllPhases() {
    return _client
        .from('phases')
        .stream(primaryKey: ['id'])
        .map<Either<Failure, List<Phase>>>(
          (rows) => right(rows.map(_phaseFromRow).toList()),
        )
        .handleError((e) => left(Failure(e.toString())));
  }

  @override
  Future<Either<Failure, Phase>> createPhase(Phase phase) async {
    try {
      final id = phase.id.isEmpty ? _uuid.v4() : phase.id;
      final now = DateTime.now().toIso8601String();

      final data = {
        'id': id,
        'goal_id': phase.goalId,
        'title': phase.title,
        'description': phase.description,
        'order_index': phase.orderIndex,
        'start_date': phase.startDate.toIso8601String(),
        'end_date': phase.endDate.toIso8601String(),
        'status': phase.status,
        'created_at': now,
        'updated_at': now,
      };

      final row = await _client.from('phases').insert(data).select().single();
      return right(_phaseFromRow(row));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Phase>> updatePhase(Phase phase) async {
    try {
      final now = DateTime.now().toIso8601String();

      final row = await _client
          .from('phases')
          .update({
            'title': phase.title,
            'description': phase.description,
            'order_index': phase.orderIndex,
            'start_date': phase.startDate.toIso8601String(),
            'end_date': phase.endDate.toIso8601String(),
            'status': phase.status,
            'updated_at': now,
          })
          .eq('id', phase.id)
          .select()
          .single();

      return right(_phaseFromRow(row));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deletePhase(String phaseId) async {
    try {
      final now = DateTime.now().toIso8601String();
      await _client
          .from('tasks')
          .update({'phase_id': null, 'updated_at': now})
          .eq('phase_id', phaseId);
      await _client.from('phases').delete().eq('id', phaseId);
      return right(unit);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<Phase>>> getPhasesByGoal(String goalId) {
    return _client
        .from('phases')
        .stream(primaryKey: ['id'])
        .eq('goal_id', goalId)
        .map<Either<Failure, List<Phase>>>(
          (rows) {
            // Memory ordering
            final sortedRows = List<Map<String, dynamic>>.from(rows)
              ..sort((a, b) => (a['order_index'] as int).compareTo(b['order_index'] as int));
            
            return right(sortedRows.map(_phaseFromRow).toList());
          },
        )
        .handleError((e) => left(Failure(e.toString())));
  }

  // ─── Row → Model Mappers ─────────────────────────────────────────────

  Goal _goalFromRow(Map<String, dynamic> row) => Goal(
    id: row['id'] as String,
    userId: row['user_id'] as String? ?? '',
    title: row['title'] as String,
    icon: row['icon'] as String?,
    currentState: row['current_state'] as String?,
    startDate: DateTime.parse(row['start_date'] as String),
    endDate: row['end_date'] != null
        ? DateTime.parse(row['end_date'] as String)
        : null,
    status: row['status'] as String? ?? 'active',
    createdAt: row['created_at'] != null
        ? DateTime.parse(row['created_at'] as String)
        : DateTime.now(),
    updatedAt: row['updated_at'] != null
        ? DateTime.parse(row['updated_at'] as String)
        : DateTime.now(),
    customProperties: row['custom_properties'] != null
        ? (row['custom_properties'] is String
            ? jsonDecode(row['custom_properties'] as String)
                as Map<String, dynamic>
            : row['custom_properties'] as Map<String, dynamic>)
        : null,
  );

  Task _taskFromRow(Map<String, dynamic> row) => Task.fromPersistence(
    id: row['id'] as String,
    userId: row['user_id'] as String? ?? '',
    goalId: row['goal_id'] as String?,
    phaseId: row['phase_id'] as String?,
    parentTaskId: row['parent_task_id'] as String?,
    title: row['title'] as String,
    description: row['description'] as String?,
    dueDate: row['due_date'] != null
        ? DateTime.parse(row['due_date'] as String)
        : null,
    isCompleted: row['is_completed'] == true || row['is_completed'] == 1,
    priority: row['priority'] as String?,
    status: row['status'] as String?,
    createdAt: row['created_at'] != null
        ? DateTime.parse(row['created_at'] as String)
        : DateTime.now(),
    updatedAt: row['updated_at'] != null
        ? DateTime.parse(row['updated_at'] as String)
        : DateTime.now(),
    customProperties: row['custom_properties'] != null
        ? (row['custom_properties'] is String
            ? jsonDecode(row['custom_properties'] as String)
                as Map<String, dynamic>
            : row['custom_properties'] as Map<String, dynamic>)
        : null,
  );

  Phase _phaseFromRow(Map<String, dynamic> row) => Phase(
    id: row['id'] as String,
    goalId: row['goal_id'] as String,
    title: row['title'] as String,
    description: row['description'] as String?,
    orderIndex: row['position'] as int? ?? 0,
    startDate: row['start_date'] != null
        ? DateTime.parse(row['start_date'] as String)
        : DateTime.now(),
    endDate: row['end_date'] != null
        ? DateTime.parse(row['end_date'] as String)
        : DateTime.now(),
    status: row['status'] as String? ?? 'active',
  );

  String? _toUuid(String? id) {
    if (id == null || id.isEmpty) return null;
    return id;
  }
}
