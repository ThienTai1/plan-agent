String _normalizeTaskStatus(String? rawStatus, {required bool isCompleted}) {
  final status = rawStatus?.trim().toLowerCase();
  if (isCompleted || status == 'completed' || status == 'done') {
    return 'done';
  }
  if (status == 'in_progress' || status == 'in-progress') {
    return 'in_progress';
  }
  if (status == 'pending' ||
      status == 'todo' ||
      status == null ||
      status.isEmpty) {
    return 'todo';
  }
  return status;
}

class Task {
  final String id;
  final String userId;
  final String? goalId;
  final String? phaseId;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final bool isCompleted;
  final String? priority; // HIGH, MEDIUM, LOW
  final String? status; // todo, in_progress, done
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? parentTaskId;
  final Map<String, dynamic>? customProperties;

  Task({
    required this.id,
    required this.userId,
    this.goalId,
    this.phaseId,
    required this.title,
    this.description,
    this.dueDate,
    required this.isCompleted,
    this.priority,
    this.status,
    required this.createdAt,
    required this.updatedAt,
    this.parentTaskId,
    this.customProperties,
  });

  factory Task.fromPersistence({
    required String id,
    required String userId,
    String? goalId,
    String? phaseId,
    String? parentTaskId,
    required String title,
    String? description,
    DateTime? dueDate,
    required bool isCompleted,
    String? priority,
    String? status,
    required DateTime createdAt,
    required DateTime updatedAt,
    Map<String, dynamic>? customProperties,
  }) {
    final normalizedStatus = _normalizeTaskStatus(
      status,
      isCompleted: isCompleted,
    );
    return Task(
      id: id,
      userId: userId,
      goalId: goalId,
      phaseId: phaseId,
      title: title,
      description: description,
      dueDate: dueDate,
      isCompleted: normalizedStatus == 'done',
      priority: priority,
      status: normalizedStatus,
      createdAt: createdAt,
      updatedAt: updatedAt,
      parentTaskId: parentTaskId,
      customProperties: customProperties,
    );
  }

  Task copyWith({
    String? id,
    String? userId,
    String? goalId,
    String? phaseId,
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
    String? priority,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? parentTaskId,
    Map<String, dynamic>? customProperties,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      goalId: goalId ?? this.goalId,
      phaseId: phaseId ?? this.phaseId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      customProperties: customProperties ?? this.customProperties,
    );
  }
}
