import 'dart:convert';
import 'package:frontend/features/goals/domain/models/habit.dart';

class HabitModel extends Habit {
  HabitModel({
    required super.id,
    super.userId,
    required super.title,
    super.description,
    required super.startDate,
    super.endDate,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    super.customProperties,
  });

  factory HabitModel.fromJson(Map<String, dynamic> json) {
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

    return HabitModel(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      status: json['status'] as String? ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      customProperties: customProps,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'custom_properties': customProperties,
    };
  }

  @override
  HabitModel copyWith({
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
    return HabitModel(
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
