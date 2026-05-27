import 'package:fpdart/fpdart.dart';
import 'package:frontend/core/error/failures.dart';
import 'package:frontend/features/chat/data/models/chat_models.dart';
import 'package:frontend/features/chat/domain/entities/message.dart';
import 'package:frontend/features/chat/domain/entities/thread.dart';

abstract class ChatRepository {
  // Threads
  Stream<Either<Failure, List<Thread>>> getThreads();
  Future<Either<Failure, Thread>> createThread(String title);
  Future<Either<Failure, Unit>> renameThread(String threadId, String title);
  Future<Either<Failure, Unit>> deleteThread(String threadId);
  Future<Either<Failure, String>> generateTitle(String threadId, {String? firstMessage, bool force = false});

  // Messages
  Stream<Either<Failure, List<Message>>> getMessages(String threadId);
  Future<Either<Failure, Message>> sendMessage(
    String threadId,
    String content, {
    String? userMessageId,
    String? aiMessageId,
  });
  Future<Either<Failure, Message>> saveMessage({
    required String threadId,
    required String role,
    required String content,
    String? id,
    Map<String, dynamic>? pendingAction,
    List<Map<String, dynamic>>? pendingActions,
    List<String>? followUps,
    String? reasoning,
  });
  Future<Either<Failure, Unit>> deleteMessage(String messageId);
  Future<Either<Failure, Unit>> deleteMessagesFrom(
    String threadId,
    DateTime fromTimestamp,
  );
  Future<Either<Failure, QuotaStatus>> getQuotaStatus();

  bool get isPro;
}
