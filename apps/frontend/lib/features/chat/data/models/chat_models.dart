class ChatFragment {
  final String type; // 'text' or 'object'
  final String? text;
  final Map<String, dynamic>? object;

  ChatFragment({
    required this.type,
    this.text,
    this.object,
  });

  factory ChatFragment.text(String text) => ChatFragment(type: 'text', text: text);
  factory ChatFragment.object(Map<String, dynamic> object) => ChatFragment(type: 'object', object: object);
}

class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isLoading;
  final Map<String, dynamic>? pendingAction;
  final List<Map<String, dynamic>>? pendingActions;
  final List<String>? followUps;
  final String? reasoning;
  final List<ChatFragment>? fragments;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isLoading = false,
    this.pendingAction,
    this.pendingActions,
    this.followUps,
    this.reasoning,
    this.fragments,
  });

  ChatMessage copyWith({
    String? id,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    bool? isLoading,
    Map<String, dynamic>? pendingAction,
    List<Map<String, dynamic>>? pendingActions,
    List<String>? followUps,
    String? reasoning,
    List<ChatFragment>? fragments,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
      pendingAction: pendingAction ?? this.pendingAction,
      pendingActions: pendingActions ?? this.pendingActions,
      followUps: followUps ?? this.followUps,
      reasoning: reasoning ?? this.reasoning,
      fragments: fragments ?? this.fragments,
    );
  }
}

class QuotaStatus {
  final String role;
  final bool isPro;
  final int aiCredits;
  final int dailyCount;
  final int dailyLimit;
  final int monthlyCount;
  final int monthlyLimit;

  QuotaStatus({
    required this.role,
    required this.isPro,
    required this.aiCredits,
    required this.dailyCount,
    required this.dailyLimit,
    required this.monthlyCount,
    required this.monthlyLimit,
  });

  factory QuotaStatus.fromJson(Map<String, dynamic> json) {
    return QuotaStatus(
      role: json['role'] ?? 'free',
      isPro: json['is_pro'] ?? false,
      aiCredits: json['ai_credits'] ?? 0,
      dailyCount: json['daily_count'] ?? 0,
      dailyLimit: json['daily_limit'] ?? 5,
      monthlyCount: json['monthly_count'] ?? 0,
      monthlyLimit: json['monthly_limit'] ?? 500,
    );
  }

  factory QuotaStatus.initial() => QuotaStatus(
        role: 'free',
        isPro: false,
        aiCredits: 0,
        dailyCount: 0,
        dailyLimit: 5,
        monthlyCount: 0,
        monthlyLimit: 500,
      );

  QuotaStatus copyWith({
    String? role,
    bool? isPro,
    int? aiCredits,
    int? dailyCount,
    int? dailyLimit,
    int? monthlyCount,
    int? monthlyLimit,
  }) {
    return QuotaStatus(
      role: role ?? this.role,
      isPro: isPro ?? this.isPro,
      aiCredits: aiCredits ?? this.aiCredits,
      dailyCount: dailyCount ?? this.dailyCount,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      monthlyCount: monthlyCount ?? this.monthlyCount,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
    );
  }
}


