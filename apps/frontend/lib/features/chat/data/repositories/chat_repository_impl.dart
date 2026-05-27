import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/core/error/failures.dart';
import 'package:frontend/features/chat/data/models/chat_models.dart';
import 'package:frontend/features/chat/domain/entities/message.dart';
import 'package:frontend/features/chat/domain/entities/thread.dart';
import 'package:frontend/features/chat/domain/repositories/chat_repository.dart';
import 'package:uuid/uuid.dart';
import 'package:frontend/core/config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Supabase-direct chat repository.
/// Replaces the legacy PowerSync local-first implementation.
class ChatRepositoryImpl implements ChatRepository {
  final SupabaseClient _supabase;
  final bool _isPro;
  final _uuid = const Uuid();

  ChatRepositoryImpl({
    required SupabaseClient supabase,
    required bool isPro,
  }) : _supabase = supabase, _isPro = isPro;

  @override
  bool get isPro => _isPro;

  @override
  Future<Either<Failure, String>> generateTitle(String threadId, {String? firstMessage, bool force = false}) async {
    try {
      final token = _supabase.auth.currentSession?.accessToken;
      
      final response = await http.post(
        Uri.parse(ApiConfig.getFullUrl(ApiConfig.chatSessionTitleEndpoint)),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'session_id': threadId,
          'first_message': firstMessage,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Right(data['title'] as String);
      } else {
        return Left(ServerFailure('Failed to generate title: ${response.statusCode}'));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Thread>> createThread(String title) async {
    try {
      final id = _uuid.v4();
      final userId = _supabase.auth.currentUser?.id;
      
      final data = await _supabase.from('threads').insert({
        'id': id,
        'user_id': userId,
        'title': title,
      }).select().single();

      return Right(Thread(
        id: data['id'] as String,
        title: data['title'] as String?,
        createdAt: DateTime.parse(data['created_at'] as String),
        updatedAt: DateTime.parse(data['updated_at'] as String),
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteThread(String threadId) async {
    try {
      await _supabase.from('threads').delete().eq('id', threadId);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> renameThread(String threadId, String title) async {
    try {
      await _supabase
          .from('threads')
          .update({'title': title, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', threadId);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<Message>>> getMessages(String threadId) {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return Stream.value(Left(ServerFailure('User not logged in')));

    // Using Supabase Realtime Stream
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('thread_id', threadId)
        .map<Either<Failure, List<Message>>>((data) {
          final messages = data
              .where((row) => row['user_id'] == userId)
              .toList()
              ..sort((a, b) => (a['created_at'] as String).compareTo(b['created_at'] as String));
          
          final mapped = messages.map((row) {
                final content = row['content'] as String;
                final pendingActions = row['pending_actions'] != null 
                    ? (row['pending_actions'] as List).cast<Map<String, dynamic>>()
                    : null;
                
                // Reconstruct fragments from content and pendingActions
                final fragments = <MessageFragment>[
                  MessageFragment(type: 'text', text: content),
                ];
                if (pendingActions != null) {
                  for (final action in pendingActions) {
                    fragments.add(MessageFragment(type: 'object', object: action));
                  }
                }

                return Message(
                  id: row['id'] as String,
                  threadId: row['thread_id'] as String,
                  role: row['role'] as String,
                  content: content,
                  createdAt: DateTime.parse(row['created_at'] as String),
                  pendingAction: row['pending_action'] != null 
                      ? row['pending_action'] as Map<String, dynamic> 
                      : null,
                  pendingActions: pendingActions,
                  followUps: row['follow_ups'] != null 
                      ? (row['follow_ups'] as List).cast<String>()
                      : null,
                  reasoning: row['reasoning'] as String?,
                  fragments: fragments,
                );
              }).toList();
          return Right<Failure, List<Message>>(mapped);
        })
        .handleError((error) {
          return Left<Failure, List<Message>>(ServerFailure(error.toString()));
        });
  }

  @override
  Stream<Either<Failure, List<Thread>>> getThreads() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return Stream.value(Left(ServerFailure('User not logged in')));

    return _supabase
        .from('threads')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map<Either<Failure, List<Thread>>>((data) {
      final sortedData = List<Map<String, dynamic>>.from(data)
          ..sort((a, b) => (b['updated_at'] as String).compareTo(a['updated_at'] as String));
          
      final threads = sortedData.map((row) {
            return Thread(
              id: row['id'] as String,
              title: row['title'] as String?,
              createdAt: DateTime.parse(row['created_at'] as String),
              updatedAt: DateTime.parse(row['updated_at'] as String),
            );
          }).toList();

      return Right(threads);
    }).handleError((e) {
      return Left(ServerFailure(e.toString()));
    });
  }

  @override
  Future<Either<Failure, Message>> saveMessage({
    required String threadId,
    required String role,
    required String content,
    String? id,
    Map<String, dynamic>? pendingAction,
    List<Map<String, dynamic>>? pendingActions,
    List<String>? followUps,
    String? reasoning,
  }) async {
    try {
      final messageId = id ?? _uuid.v4();
      
      final userId = _supabase.auth.currentUser?.id;
      
      final data = await _supabase.from('messages').upsert({
        'id': messageId,
        'thread_id': threadId,
        'user_id': userId,
        'role': role,
        'content': content,
        'pending_action': pendingAction,
        'pending_actions': pendingActions,
        'follow_ups': followUps,
        'reasoning': reasoning,
      }).select().single();

      // Reconstruct fragments for the returned entity
      final fragments = <MessageFragment>[
        MessageFragment(type: 'text', text: data['content'] as String),
      ];
      if (pendingActions != null) {
        for (final action in pendingActions) {
          fragments.add(MessageFragment(type: 'object', object: action));
        }
      }

      return Right(Message(
        id: data['id'] as String,
        threadId: data['thread_id'] as String,
        role: data['role'] as String,
        content: data['content'] as String,
        createdAt: DateTime.parse(data['created_at'] as String),
        pendingAction: pendingAction,
        pendingActions: pendingActions,
        followUps: followUps,
        reasoning: reasoning,
        fragments: fragments,
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Message>> sendMessage(
    String threadId,
    String content, {
    String? userMessageId,
    String? aiMessageId,
  }) async {
    // Deprecated for SSE-based flow, but matching interface
    return saveMessage(threadId: threadId, role: 'user', content: content, id: userMessageId);
  }

  @override
  Future<Either<Failure, Unit>> deleteMessage(String messageId) async {
    try {
      await _supabase.from('messages').delete().eq('id', messageId);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteMessagesFrom(String threadId, DateTime fromTimestamp) async {
    try {
      await _supabase
          .from('messages')
          .delete()
          .eq('thread_id', threadId)
          .gte('created_at', fromTimestamp.toIso8601String());
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, QuotaStatus>> getQuotaStatus() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return Right(QuotaStatus.initial());

      final data = await _supabase.from('profiles').select().eq('id', userId).single();

      return Right(QuotaStatus(
        role: data['role'] as String? ?? 'free',
        isPro: (data['role'] as String? ?? 'free') == 'pro',
        aiCredits: data['ai_credits'] as int? ?? 0,
        dailyCount: 0,
        dailyLimit: 0,
        monthlyCount: data['monthly_messages_count'] as int? ?? 0,
        monthlyLimit: 500,
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
