import 'dart:convert';
import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/core/error/failures.dart';
import 'package:frontend/features/goals/domain/models/habit.dart';
import 'package:frontend/features/goals/data/models/habit_model.dart';
import 'package:frontend/features/goals/domain/repositories/habit_repository.dart';
import 'package:frontend/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:uuid/uuid.dart';

class SupabaseHabitRepositoryImpl implements HabitRepository {
  final AuthRemoteDataSource authDataSource;
  final _uuid = const Uuid();

  SupabaseHabitRepositoryImpl(this.authDataSource);

  SupabaseClient get _client => Supabase.instance.client;

  String? _getUserId() {
    final session = authDataSource.currentUserSession;
    return session?.user.id;
  }

  @override
  Stream<Either<Failure, List<Habit>>> getAllHabits() {
    final userId = _getUserId();
    if (userId == null) return Stream.value(left(Failure('User not logged in')));
    
    return _client
        .from('habits')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map<Either<Failure, List<Habit>>>(
          (rows) => right(rows.map(_habitFromRow).toList()),
        )
        .handleError((e) => left(Failure(e.toString())));
  }

  @override
  Future<Either<Failure, Habit>> createHabit(Habit habit) async {
    try {
      final userId = _getUserId();
      if (userId == null) return left(Failure('User not logged in'));

      final id = habit.id.isEmpty ? _uuid.v4() : habit.id;
      final now = DateTime.now().toIso8601String();

      final data = {
        'id': id,
        'user_id': _toUuid(userId)!, // userId must be valid for RLS anyway
        'title': habit.title,
        'description': habit.description,
        'start_date': habit.startDate.toIso8601String(),
        'end_date': habit.endDate?.toIso8601String(),
        'status': habit.status,
        'created_at': now,
        'updated_at': now,
        'custom_properties': habit.customProperties,
      };

      final row = await _client.from('habits').insert(data).select().single();
      return right(_habitFromRow(row));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Habit>> updateHabit(Habit habit) async {
    try {
      final now = DateTime.now().toIso8601String();
      
      final row = await _client
          .from('habits')
          .update({
            'title': habit.title,
            'description': habit.description,
            'start_date': habit.startDate.toIso8601String(),
            'end_date': habit.endDate?.toIso8601String(),
            'status': habit.status,
            'updated_at': now,
            'custom_properties': habit.customProperties,
          })
          .eq('id', habit.id)
          .select()
          .single();
          
      return right(_habitFromRow(row));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteHabit(String habitId) async {
    try {
      await _client.from('habits').delete().eq('id', habitId);
      return right(unit);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Habit>> toggleHabit(String habitId, DateTime date) async {
    try {
      final row = await _client.from('habits').select().eq('id', habitId).single();
      final habit = _habitFromRow(row);
      
      final dateStr = date.toIso8601String().split('T')[0];
      final completions = List<String>.from(habit.customProperties?['completions'] ?? []);
      
      if (completions.contains(dateStr)) {
        completions.remove(dateStr);
      } else {
        completions.add(dateStr);
      }
      
      completions.sort();
      int streak = _calculateStreak(completions);
      
      final updatedCustom = Map<String, dynamic>.from(habit.customProperties ?? {});
      updatedCustom['completions'] = completions;
      updatedCustom['streak'] = streak;
      
      final updatedHabit = habit.copyWith(customProperties: updatedCustom);
      return updateHabit(updatedHabit);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  int _calculateStreak(List<String> completions) {
    if (completions.isEmpty) return 0;
    
    final dates = completions.map((s) => DateTime.parse(s)).toList()
      ..sort((a, b) => b.compareTo(a));
      
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    int streak = 0;
    DateTime currentCheck = dates.first;
    
    final diffToday = todayDate.difference(DateTime(currentCheck.year, currentCheck.month, currentCheck.day)).inDays;
    if (diffToday > 1) return 0;
    
    streak = 1;
    for (int i = 0; i < dates.length - 1; i++) {
        final d1 = DateTime(dates[i].year, dates[i].month, dates[i].day);
        final d2 = DateTime(dates[i+1].year, dates[i+1].month, dates[i+1].day);
        if (d1.difference(d2).inDays == 1) {
            streak++;
        } else if (d1.difference(d2).inDays == 0) {
            continue;
        } else {
            break;
        }
    }
    
    return streak;
  }

  Habit _habitFromRow(Map<String, dynamic> row) => HabitModel.fromJson({
    'id': row['id'],
    'user_id': row['user_id'],
    'title': row['title'],
    'description': row['description'],
    'start_date': row['start_date'],
    'end_date': row['end_date'],
    'status': row['status'],
    'created_at': row['created_at'],
    'updated_at': row['updated_at'],
    'custom_properties': row['custom_properties'] is String 
        ? jsonDecode(row['custom_properties']) 
        : row['custom_properties'],
  });

  String? _toUuid(String? id) {
    if (id == null || id.isEmpty) return null;
    return id;
  }
}
