import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/core/error/failures.dart';
import 'package:frontend/core/common/domain/models/event.dart';
import 'package:frontend/features/calendar/domain/repositories/event_repository.dart';
import 'package:frontend/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

class SupabaseEventRepositoryImpl implements EventRepository {
  final AuthRemoteDataSource authDataSource;
  final _uuid = const Uuid();

  SupabaseEventRepositoryImpl(this.authDataSource);

  SupabaseClient get _client => Supabase.instance.client;

  String? _getUserId() {
    final session = authDataSource.currentUserSession;
    return session?.user.id;
  }

  @override
  Stream<Either<Failure, List<Event>>> getUpcomingEvents() {
    final userId = _getUserId();
    if (userId == null) return Stream.value(left(Failure('User not logged in')));
    
    final now = DateTime.now();
    return _client
        .from('events')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map<Either<Failure, List<Event>>>(
          (rows) {
            final filtered = rows
                .where((row) => DateTime.parse(row['start_time']).isAfter(now))
                .toList()
              ..sort((a, b) => (a['start_time'] as String).compareTo(b['start_time'] as String));
            
            return right(filtered.map(_eventFromRow).toList());
          },
        )
        .handleError((e) => left(Failure(e.toString())));
  }

  @override
  Future<Either<Failure, Event>> createEvent(Event event) async {
    try {
      final userId = _getUserId();
      if (userId == null) return left(Failure('User not logged in'));

      final id = event.id.isEmpty ? _uuid.v4() : event.id;
      final now = DateTime.now().toIso8601String();

      final data = {
        'id': id,
        'user_id': _toUuid(userId)!,
        'title': event.title,
        'description': event.description,
        'start_time': event.startTime.toIso8601String(),
        'end_time': event.endTime.toIso8601String(),
        'location': event.location,
        'color': event.color?.value,
        'is_all_day': event.isAllDay,
        'created_at': now,
        'updated_at': now,
      };

      final row = await _client.from('events').insert(data).select().single();
      return right(_eventFromRow(row));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Event>> updateEvent(Event event) async {
    try {
      final now = DateTime.now().toIso8601String();
      
      final row = await _client
          .from('events')
          .update({
            'title': event.title,
            'description': event.description,
            'start_time': event.startTime.toIso8601String(),
            'end_time': event.endTime.toIso8601String(),
            'location': event.location,
            'color': event.color?.value,
            'is_all_day': event.isAllDay,
            'updated_at': now,
          })
          .eq('id', event.id)
          .select()
          .single();
          
      return right(_eventFromRow(row));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteEvent(String eventId) async {
    try {
      await _client.from('events').delete().eq('id', eventId);
      return right(unit);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  Event _eventFromRow(Map<String, dynamic> row) => Event(
    id: row['id'] as String,
    userId: row['user_id'] as String? ?? '',
    title: row['title'] as String,
    description: row['description'] as String?,
    startTime: DateTime.parse(row['start_time'] as String),
    endTime: DateTime.parse(row['end_time'] as String),
    location: row['location'] as String?,
    color: row['color'] != null ? Color(row['color'] as int) : null,
    isAllDay: row['is_all_day'] as bool? ?? false,
    createdAt: row['created_at'] != null 
        ? DateTime.parse(row['created_at'] as String)
        : DateTime.now(),
    updatedAt: row['updated_at'] != null 
        ? DateTime.parse(row['updated_at'] as String)
        : DateTime.now(),
  );

  String? _toUuid(String? id) {
    if (id == null || id.isEmpty) return null;
    return id;
  }
}
