import 'package:frontend/core/common/domain/models/goal.dart';

class GoalModel extends Goal {
  GoalModel({
    required super.id,
    required super.userId,
    required super.title,
    super.currentState,
    required super.startDate,
    super.endDate,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    super.phases,
    super.icon,
    super.customProperties,
  });

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    return GoalModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      currentState: json['current_state'] as String?,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : DateTime.now(),
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
      icon: json['icon'] as String?,
      customProperties: json['custom_properties'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'current_state': currentState,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'icon': icon,
      'custom_properties': customProperties,
    };
  }
}
