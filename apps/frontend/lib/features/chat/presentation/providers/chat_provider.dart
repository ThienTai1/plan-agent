import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:frontend/features/chat/data/models/chat_models.dart';
import 'package:frontend/features/chat/domain/repositories/chat_repository.dart';
import 'package:frontend/features/chat/domain/entities/message.dart';
import 'package:frontend/features/chat/domain/entities/thread.dart';
import 'package:frontend/features/chat/data/datasources/chat_stream_service.dart';
import 'package:frontend/features/chat/data/datasources/action_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class ChatProvider with ChangeNotifier {
  final ChatRepository _repository;
  final ChatStreamService _streamService = ChatStreamService();
  final ActionService _actionService = ActionService();
  final _uuid = const Uuid();

  List<ChatMessage> _messages = [];
  List<Thread> _threads = [];
  String? _currentThreadId;
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _error;
  String? _currentStatus;
  QuotaStatus _quotaStatus = QuotaStatus.initial();

  StreamSubscription? _messagesSubscription;
  StreamSubscription? _threadsSubscription;
  final Set<String> _optimisticMsgIds = {};

  ChatProvider({required ChatRepository repository}) : _repository = repository;

  List<ChatMessage> get messages => _messages;
  List<Thread> get threads => _threads;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  String? get currentStatus => _currentStatus;

  String? get currentThreadId => _currentThreadId;
  QuotaStatus get quotaStatus => _quotaStatus;
  int get dailyMessageCount => _quotaStatus.dailyCount;

  bool get isPro => _repository.isPro;

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _threadsSubscription?.cancel();
    _streamService.dispose();
    super.dispose();
  }

  Future<void> init([String? threadId]) async {
    _isLoading = true;
    notifyListeners();

    try {
      _subscribeToThreads();

      if (threadId != null) {
        _currentThreadId = threadId;
      } else if (_currentThreadId == null) {
        if (_threads.isNotEmpty) {
          _currentThreadId = _threads.first.id;
        } else {
          _currentThreadId = null;
        }
      }

      if (_currentThreadId != null) {
        _subscribeToMessages(_currentThreadId!);
      }
      await refreshQuotaStatus();
      debugPrint('🔵 ChatProvider initialized: ${_messages.length} messages, quota: ${_quotaStatus.aiCredits} credits');

    } catch (e) {
      debugPrint('🔴 ChatProvider init failed: $e');
      _error = e.toString();

    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _subscribeToThreads() {
    _threadsSubscription?.cancel();
    _threadsSubscription = _repository.getThreads().listen((result) {
      result.fold(
        (failure) {
          _error = failure.message;
          notifyListeners();
        },
        (loadedThreads) {
          _threads = loadedThreads;
          notifyListeners();
        },
      );
    });
  }

  Future<void> loadThreads() async {
    // This is now handled by _subscribeToThreads, but keeping the method 
    // for compatibility if needed elsewhere, converting it to a no-op 
    // or a simple refresh if the repository supports it.
  }

  Future<void> refreshQuotaStatus() async {
    final result = await _repository.getQuotaStatus();
    result.fold(
      (failure) {
        debugPrint('🔴 Failed to refresh quota: ${failure.message}');
      },
      (status) {
        debugPrint('🟢 Quota refreshed: ${status.aiCredits} credits, ${status.dailyCount} daily');
        _quotaStatus = status;
        notifyListeners();
      },
    );
  }



  void _subscribeToMessages(String threadId) {
    _messagesSubscription?.cancel();
    _messagesSubscription = _repository.getMessages(threadId).listen((result) {
      result.fold(
        (failure) {
          _error = failure.message;
          notifyListeners();
        },
        (dbMessages) {
          // Skip DB updates while generating — optimistic messages are showing
          // correctly, and Supabase stream can cause timestamp-based reordering
          if (_isGenerating) return;

          final mappedMessages = dbMessages.map(_mapEntityToModel).toList();

          // Remove from optimistic set if the DB has it now
          final dbIds = mappedMessages.map((m) => m.id).toSet();
          _optimisticMsgIds.removeWhere((id) => dbIds.contains(id));

          // Preserve any existing optimistic message that hasn't synced yet
          for (final existingMsg in _messages) {
            if (_optimisticMsgIds.contains(existingMsg.id) &&
                !dbIds.contains(existingMsg.id)) {
              mappedMessages.add(existingMsg);
            }
          }

          _messages = mappedMessages;
          _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          notifyListeners();
        },
      );
    });
  }

  Future<void> sendMessage(String content) async {
    if (_currentThreadId == null) {
      final result = await _repository.createThread("New Chat");
      await result.fold(
        (failure) async {
          _error = failure.message;
        },
        (thread) async {
          _currentThreadId = thread.id;
          _threads.insert(0, thread);
        },
      );
      if (_currentThreadId == null) return;
      _subscribeToMessages(_currentThreadId!);
    }

    // 1. Send message to Supabase (Optimistic UI handled by persistence layer usually)
    // We call repository.sendMessage which doesn't stream but saves.
    // Actually, we want to START streaming first for best UX.

    _isGenerating = true;
    _error = null;

    final userMessageId = _uuid.v4();
    final now = DateTime.now();

    // Optimistically add the user message to the UI IMMEDIATELY
    _optimisticMsgIds.add(userMessageId);
    _messages.add(
      ChatMessage(
        id: userMessageId,
        content: content,
        isUser: true,
        timestamp: now,
        isLoading: false,
      ),
    );

    // Insert a temporary AI message for streaming IMMEDIATELY
    final aiMessageId = _uuid.v4();
    _optimisticMsgIds.add(aiMessageId);
    final tempAiMessage = ChatMessage(
      id: aiMessageId,
      content: "",
      isUser: false,
      timestamp: now.add(const Duration(milliseconds: 10)),
      isLoading: true,
    );
    _messages.add(tempAiMessage);
    notifyListeners();

    // Save user message to DB before calling sendMessage
    // (must complete first so history query finds it)
    final userMsgResult = await _repository.saveMessage(
      threadId: _currentThreadId!,
      role: 'user',
      content: content,
      id: userMessageId,
    );
    userMsgResult.fold((failure) {
      _error = failure.message;
      notifyListeners();
    }, (_) => null);

    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    final history = _messages
        .where((m) => m.id != userMessageId && m.id != aiMessageId)
        .map((m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.content})
        .toList();

    _currentStatus = "Connecting...";
    notifyListeners();

    try {
      String fullContent = "";
      Map<String, dynamic> finalMetadata = {};
      final userId = Supabase.instance.client.auth.currentUser?.id ?? "00000000-0000-0000-0000-000000000000";

      await for (final result in _streamService.streamChat(
        query: content,
        history: history,
        userId: userId,
        token: token,
      )) {
        if (result.error != null) {
          if (result.error == 'QUOTA_EXCEEDED') {
            _error = "You have used up all your Chat turns. Please upgrade to Pro for unlimited conversation! 🚀";
          } else if (result.error == 'RATE_LIMIT_EXCEEDED') {
            _error = "You are sending messages too fast (Anti-spam). Please wait a moment and try again. 🐢";
          } else {
            _error = result.error;
          }
          
          final index = _messages.indexWhere((m) => m.id == aiMessageId);
          if (index != -1) {
            _messages[index] = _messages[index].copyWith(
              content: '❌ ${_error}',
              isLoading: false,
            );
          }
          break;
        }

        if (result.status != null) {
          _currentStatus = result.status;
          notifyListeners();
        }

        if (result.text != null) {
          fullContent += result.text!;
          final index = _messages.indexWhere((m) => m.id == aiMessageId);
          if (index != -1) {
            final currentFragments = List<ChatFragment>.from(_messages[index].fragments ?? []);
            if (currentFragments.isEmpty || currentFragments.last.type != 'text') {
              currentFragments.add(ChatFragment.text(result.text!));
            } else {
              final lastIdx = currentFragments.length - 1;
              currentFragments[lastIdx] = ChatFragment.text(
                (currentFragments[lastIdx].text ?? "") + result.text!
              );
            }

            _messages[index] = _messages[index].copyWith(
              content: fullContent,
              fragments: currentFragments,
              isLoading: false,
            );
          }
          notifyListeners();
        }

        if (result.metadata != null) {
          final type = result.metadata!['type'];
          final content = result.metadata!['content'];

          if (type == 'object') {
            final index = _messages.indexWhere((m) => m.id == aiMessageId);
            if (index != -1) {
              final currentFragments = List<ChatFragment>.from(_messages[index].fragments ?? []);
              currentFragments.add(ChatFragment.object(content as Map<String, dynamic>));

              final currentActions = List<Map<String, dynamic>>.from(_messages[index].pendingActions ?? []);
              currentActions.add(content);
              
              _messages[index] = _messages[index].copyWith(
                pendingActions: currentActions,
                fragments: currentFragments,
              );
            }
          } else if (type == 'final') {
            finalMetadata = result.metadata!;
          }
          notifyListeners();
        }
      }

      // Cleanup and save resulting AI message to DB for persistence
      _currentStatus = null;
      _isGenerating = false;

      final index = _messages.indexWhere((m) => m.id == aiMessageId);
      if (index != -1) {
        final finalMsg = _messages[index];
        await _repository.saveMessage(
          threadId: _currentThreadId!,
          role: 'assistant',
          content: finalMsg.content,
          id: aiMessageId,
          pendingAction: finalMsg.pendingAction,
          pendingActions: finalMsg.pendingActions,
          followUps: (finalMetadata['follow_ups'] as List?)?.cast<String>(),
          reasoning: finalMetadata['reasoning'] as String?,
        );
        
        // Update local model with final metadata
        _messages[index] = finalMsg.copyWith(
          followUps: (finalMetadata['follow_ups'] as List?)?.cast<String>(),
          reasoning: finalMetadata['reasoning'] as String?,
        );
      }

      // Reload threads for title updates
      await loadThreads();
      
      // Refresh daily limit count
      await refreshQuotaStatus();

      // NEW: Generate title for new conversations
      if (history.isEmpty) {
        debugPrint('🪄 Generating title for new thread...');
        final titleResult = await _repository.generateTitle(
          _currentThreadId!,
          firstMessage: content,
        );
        titleResult.fold(
          (f) => debugPrint('🔴 Title generation failed: ${f.message}'),
          (newTitle) async {
            debugPrint('✅ Title generated: $newTitle');
            
            // Optimistically update the thread title in the list
            for (int i = 0; i < _threads.length; i++) {
              if (_threads[i].id == _currentThreadId) {
                _threads[i] = Thread(
                  id: _threads[i].id,
                  title: newTitle,
                  createdAt: _threads[i].createdAt,
                  updatedAt: DateTime.now(),
                );
                break;
              }
            }
            notifyListeners();
          },
        );
      }

    } catch (e) {
      _error = e.toString();
      _currentStatus = null;
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<void> executeConfirmedAction(Map<String, dynamic> actionData, String messageId) async {
    final action = actionData['action'];
    final data = actionData['data'];
    final token = Supabase.instance.client.auth.currentSession?.accessToken;

    _isLoading = true;
    notifyListeners();

    try {
      final res = await _actionService.executeAction(
        action: action,
        data: data,
        token: token,
      );

      if (res['status'] == 'success') {
        // Find the message that had this pending action and clear it
        final index = _messages.indexWhere(
          (m) =>
              m.pendingAction != null && m.pendingAction!['action'] == action,
        );
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(
            pendingAction: null,
            content:
                "${_messages[index].content}\n\n✅ Action performed successfully.",
          );
          
          // Persist the cleared action to DB
          await _repository.saveMessage(
            threadId: _currentThreadId!,
            role: 'assistant',
            content: _messages[index].content,
            id: messageId,
            pendingAction: null,
          );
        }
      } else {
        _error = res['message'] ?? 'Action failed';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Execute a bundle of actions (from V3 LangGraph agent)
  Future<void> executeBundleActions(
    List<Map<String, dynamic>> actions,
    String messageId,
  ) async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;

    _isLoading = true;
    notifyListeners();

    try {
      final res = await _actionService.executeBundleAction(
        actions: actions,
        token: token,
      );

      if (res['status'] == 'success') {
        final index = _messages.indexWhere((m) => m.id == messageId);
        if (index != -1) {
          _messages[index] = _messages[index].copyWith(
            pendingActions: [],
            content:
                "${_messages[index].content}\n\n✅ All actions performed successfully.",
          );
          
          // Persist the cleared actions to DB
          await _repository.saveMessage(
            threadId: _currentThreadId!,
            role: 'assistant',
            content: _messages[index].content,
            id: messageId,
            pendingActions: [],
          );
        }
      } else {
        _error = res['message'] ?? 'Bundle execution failed';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle a task's completion status (used by Focus Action Card)
  Future<void> toggleFocusTask(String taskId, bool isCompleted) async {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;

    try {
      await _actionService.executeAction(
        action: 'update_task',
        data: {
          'task_id': taskId,
          'is_completed': isCompleted,
        },
        token: token,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Execute batch actions from Action Cards (Breakdown "Add all", Reschedule "Accept all")
  Future<void> executeBatchCardActions(List<Map<String, dynamic>> actions, String sourceMessageId) async {
    if (_currentThreadId == null) return;

    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    final userId = Supabase.instance.client.auth.currentUser?.id ?? "00000000-0000-0000-0000-000000000000";

    _isGenerating = true;
    _error = null;
    notifyListeners();

    try {
      // 🚀 NEW: Use the streaming resume flow for real-time feedback
      final aiMessageId = _uuid.v4();
      _optimisticMsgIds.add(aiMessageId);
      
      // Add a placeholder AI message for the sync logs and final response
      _messages.add(
        ChatMessage(
          id: aiMessageId,
          content: "",
          isUser: false,
          timestamp: DateTime.now(),
          isLoading: true,
        ),
      );
      notifyListeners();

      String fullContent = "";

      await for (final result in _streamService.streamResume(
        sessionId: _currentThreadId!,
        response: actions,
        userId: userId,
        token: token,
      )) {
        if (result.error != null) {
          _error = result.error;
          break;
        }

        if (result.status != null) {
          _currentStatus = result.status;
          notifyListeners();
        }

        if (result.text != null) {
          fullContent += result.text!;
          final index = _messages.indexWhere((m) => m.id == aiMessageId);
          if (index != -1) {
            _messages[index] = _messages[index].copyWith(
              content: fullContent,
              isLoading: false,
            );
          }
          notifyListeners();
        }

        if (result.metadata != null && result.metadata!['type'] == 'object') {
          final index = _messages.indexWhere((m) => m.id == aiMessageId);
          if (index != -1) {
            _messages[index] = _messages[index].copyWith(
              pendingAction: result.metadata!['content'],
              isLoading: false,
            );
          }
          notifyListeners();
        }
      }

      // 💾 Persist the final AI confirmation message to DB
      final index = _messages.indexWhere((m) => m.id == aiMessageId);
      if (index != -1 && (fullContent.isNotEmpty || _messages[index].pendingAction != null)) {
        await _repository.saveMessage(
          threadId: _currentThreadId!,
          role: 'assistant',
          content: _messages[index].content,
          id: aiMessageId,
          pendingAction: _messages[index].pendingAction,
        );
      }
      
      // 💾 Persist the cleared state of the SOURCE message (where the button was)
      final sourceIdx = _messages.indexWhere((m) => m.id == sourceMessageId);
      if (sourceIdx != -1) {
        _messages[sourceIdx] = _messages[sourceIdx].copyWith(pendingActions: []);
        await _repository.saveMessage(
          threadId: _currentThreadId!,
          role: 'assistant',
          content: _messages[sourceIdx].content,
          id: sourceMessageId,
          pendingActions: [],
        );
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      // 🏁 Guaranteed Cleanup
      _currentStatus = null;
      _isGenerating = false;
      
      // Clear loading state for messages
      for (int i = 0; i < _messages.length; i++) {
        if (_messages[i].isLoading) {
          _messages[i] = _messages[i].copyWith(isLoading: false);
        }
      }
      
      await refreshQuotaStatus();
      notifyListeners();
    }
  }

  void clearMessages() {
    _currentThreadId = null;
    _messages.clear();
    _messagesSubscription?.cancel();
    notifyListeners();
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      final result = await _repository.deleteMessage(messageId);
      result.fold((failure) {
        _error = failure.message;
        notifyListeners();
      }, (_) => null);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> editMessage(ChatMessage message, String newContent) async {
    if (_currentThreadId == null) return;
    try {
      final deleteResult = await _repository.deleteMessagesFrom(
        _currentThreadId!,
        message.timestamp,
      );
      await deleteResult.fold(
        (failure) async {
          _error = failure.message;
          notifyListeners();
        },
        (_) async {
          await sendMessage(newContent);
        },
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> renameThread(String threadId, String title) async {
    try {
      final result = await _repository.renameThread(threadId, title);
      result.fold(
        (failure) {
          _error = failure.message;
          notifyListeners();
        },
        (_) {
          for (int i = 0; i < _threads.length; i++) {
            if (_threads[i].id == threadId) {
              _threads[i] = Thread(
                id: threadId,
                title: title,
                createdAt: _threads[i].createdAt,
                updatedAt: DateTime.now(),
              );
              break;
            }
          }
          notifyListeners();
        },
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteThread(String threadId) async {
    try {
      final result = await _repository.deleteThread(threadId);
      result.fold(
        (failure) {
          _error = failure.message;
          notifyListeners();
        },
        (_) {
          _threads.removeWhere((t) => t.id == threadId);
          if (_currentThreadId == threadId) {
            clearMessages();
          } else {
            notifyListeners();
          }
        },
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void stopGenerating() {
    _isGenerating = false;
    notifyListeners();
  }

  ChatMessage _mapEntityToModel(Message entity) {
    return ChatMessage(
      id: entity.id,
      content: entity.content,
      isUser: entity.role == 'user',
      timestamp: entity.createdAt,
      isLoading: false,
      pendingAction: entity.pendingAction,
      pendingActions: entity.pendingActions,
      followUps: entity.followUps,
      reasoning: entity.reasoning,
      fragments: entity.fragments?.map((f) => ChatFragment(
        type: f.type,
        text: f.text,
        object: f.object,
      )).toList(),
    );
  }
}
