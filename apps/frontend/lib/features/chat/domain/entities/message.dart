class MessageFragment {
  final String type; // 'text' or 'object'
  final String? text;
  final Map<String, dynamic>? object;

  MessageFragment({
    required this.type,
    this.text,
    this.object,
  });
}

class Message {
  final String id;
  final String threadId;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime createdAt;
  final bool isUser;
  final Map<String, dynamic>? pendingAction;
  final List<Map<String, dynamic>>? pendingActions;
  final List<String>? followUps;
  final String? reasoning;
  final List<MessageFragment>? fragments;

  Message({
    required this.id,
    required this.threadId,
    required this.role,
    required this.content,
    required this.createdAt,
    this.pendingAction,
    this.pendingActions,
    this.followUps,
    this.reasoning,
    this.fragments,
  }) : isUser = role == 'user';
}
