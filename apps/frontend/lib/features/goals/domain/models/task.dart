import 'package:flutter/material.dart';

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
  final String? userId;
  final String? goalId;
  final String? phaseId;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final bool isCompleted;
  final String? priority; // HIGH, MEDIUM, LOW
  final String? status; // todo, in_progress, done
  final DateTime createdAt;
  final String? parentTaskId;

  // Calendar Fields
  final DateTime? startTime;
  final bool isEvent;
  final Color? color;

  // Dynamic Data
  final Map<String, dynamic>? customProperties;
  final String? recurrenceRule;

  Task({
    required this.id,
    this.userId,
    this.goalId,
    this.phaseId,
    required this.title,
    this.description,
    this.dueDate,
    required this.isCompleted,
    this.priority,
    this.status,
    required this.createdAt,
    this.parentTaskId,
    this.startTime,
    this.isEvent = false,
    this.color,
    this.customProperties,
    this.recurrenceRule,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    final rawIsCompleted = json['is_completed'];
    final isCompleted = rawIsCompleted == true || rawIsCompleted == 1;
    final status = _normalizeTaskStatus(
      json['status'] as String?,
      isCompleted: isCompleted,
    );
    return Task(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      goalId: json['goal_id'] as String?,
      phaseId: json['phase_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      isCompleted: isCompleted,
      priority: json['priority'] as String?,
      status: status,
      parentTaskId: json['parent_task_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'] as String)
          : null,
      isEvent: json['is_event'] ?? false,
      color: json['color'] != null ? Color(json['color'] as int) : null,
      customProperties: json['custom_properties'] as Map<String, dynamic>?,
      recurrenceRule: json['recurrence_rule'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'goal_id': goalId,
      'phase_id': phaseId,
      'title': title,
      'description': description,
      'due_date': dueDate?.toIso8601String(),
      'is_completed': isCompleted,
      'priority': priority,
      'status': status,
      'parent_task_id': parentTaskId,
      'created_at': createdAt.toIso8601String(),
      'start_time': startTime?.toIso8601String(),
      'is_event': isEvent,
      'color': color?.toARGB32(),
      'custom_properties': customProperties,
      'recurrence_rule': recurrenceRule,
    };
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
    String? parentTaskId,
    DateTime? createdAt,
    DateTime? startTime,
    bool? isEvent,
    Color? color,
    Map<String, dynamic>? customProperties,
    String? recurrenceRule,
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
      parentTaskId: parentTaskId ?? this.parentTaskId,
      createdAt: createdAt ?? this.createdAt,
      startTime: startTime ?? this.startTime,
      isEvent: isEvent ?? this.isEvent,
      color: color ?? this.color,
      customProperties: customProperties ?? this.customProperties,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
    );
  }
}
