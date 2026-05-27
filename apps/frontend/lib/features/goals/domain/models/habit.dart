class Habit {
  final String id;
  final String? userId;
  final String title;
  final String? description;
  final DateTime startDate;
  final DateTime? endDate;
  final String status; // active, paused, archived
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Custom properties for habit-specific data
  // completions: List<String> (ISO dates)
  // streak: int
  // recurrenceRule: String (daily, weekly, etc.)
  final Map<String, dynamic>? customProperties;

  Habit({
    required this.id,
    this.userId,
    required this.title,
    this.description,
    required this.startDate,
    this.endDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.customProperties,
  });

  // Helper getters
  List<String> get completions => 
      List<String>.from(customProperties?['completions'] ?? []);
      
  int get streak => customProperties?['streak'] ?? 0;
  
  String get recurrenceRule => customProperties?['recurrence_rule'] ?? 'daily';

  Habit copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? customProperties,
  }) {
    return Habit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customProperties: customProperties ?? this.customProperties,
    );
  }
}
