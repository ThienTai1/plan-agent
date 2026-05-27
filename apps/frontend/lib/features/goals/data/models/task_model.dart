import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/features/goals/domain/models/task.dart';

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

class TaskModel extends Task {
  TaskModel({
    required super.id,
    super.userId, // Added userId
    required super.title,
    super.description,
    super.phaseId,
    super.goalId,
    super.parentTaskId,
    super.startTime, // For events
    super.dueDate, // Mapped to due_date for tasks
    required super.isCompleted,
    super.isEvent,
    super.color,
    required super.createdAt,
    super.priority,
    super.status,
    super.customProperties,
    super.recurrenceRule,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    // Handle raw database row parsing for custom_properties
    Map<String, dynamic> customProps = {};
    final rawCustom = json['custom_properties'];
    if (rawCustom is Map<String, dynamic>) {
      customProps = rawCustom;
    } else if (rawCustom is String && rawCustom.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawCustom);
        if (decoded is Map<String, dynamic>) {
          customProps = decoded;
        }
      } catch (_) {}
    }
    // Safer decoding in TaskModel since it might not have dart:convert
    // Actually, TaskModel.fromJson is often used where row mapping is needed.
    // Let's refine the logic to be robust against raw SQL rows.

    final statusRaw = json['status'] as String?;

    // Handle is_completed from SQL (int 0/1) or JSON (bool)
    final rawIsCompleted = json['is_completed'];
    bool isCompleted = false;
    if (rawIsCompleted is bool) {
      isCompleted = rawIsCompleted;
    } else if (rawIsCompleted is int) {
      isCompleted = rawIsCompleted == 1;
    }

    // Derived completion state
    final effectiveStatus = _normalizeTaskStatus(
      statusRaw,
      isCompleted: isCompleted,
    );
    final effectiveIsCompleted = effectiveStatus == 'done';

    return TaskModel(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      description: json['description'],
      goalId: json['goal_id'],
      parentTaskId: json['parent_task_id'],
      phaseId: json['phase_id'] ?? customProps['phase_id'],
      startTime: customProps['start_time'] != null
          ? DateTime.parse(customProps['start_time'])
          : null,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'])
          : null,
      isCompleted: effectiveIsCompleted,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      isEvent: customProps['is_event'] ?? false,
      color: customProps['color'] != null ? Color(customProps['color']) : null,
      priority: json['priority'],
      status: effectiveStatus,
      customProperties: customProps,
      recurrenceRule: json['recurrence_rule'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final props = Map<String, dynamic>.from(customProperties ?? {});
    if (phaseId != null) props['phase_id'] = phaseId;
    if (startTime != null) props['start_time'] = startTime!.toIso8601String();
    props['is_event'] = isEvent;
    if (color != null) props['color'] = color!.toARGB32();

    return {
      'id': id,
      'user_id': userId, // Add userId
      'title': title,
      'description': description,
      'goal_id': goalId,
      'parent_task_id': parentTaskId,
      'due_date': dueDate?.toIso8601String(),
      'is_completed': isCompleted,
      'priority': priority,
      'status': status,
      // Store extra fields in custom_properties
      'custom_properties': props,
      'created_at': createdAt.toIso8601String(),
      'recurrence_rule': recurrenceRule,
    };
  }

  @override
  TaskModel copyWith({
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
    return TaskModel(
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
      // TaskModel specific
      // Note: TaskModel constructor handles mapping these to/from customProperties/super fields
      // But here we just pass them potentially new values
      startTime: startTime ?? this.startTime,
      isEvent: isEvent ?? this.isEvent,
      color: color ?? this.color,
      customProperties: customProperties ?? this.customProperties,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
    );
  }
}
