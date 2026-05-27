import '../../../../features/goals/domain/models/phase.dart';
import 'dart:convert';

class Goal {
  final String id;
  final String userId;
  final String title;
  final String? currentState;
  final DateTime startDate;
  final DateTime? endDate;
  final String status; // active, completed, etc.
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Phase>? phases;
  final String? icon;
  final Map<String, dynamic>? customProperties;

  Goal({
    required this.id,
    required this.userId,
    required this.title,
    this.currentState,
    required this.startDate,
    this.endDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.phases,
    this.icon,
    this.customProperties,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      currentState: json['current_state'] as String?,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      phases: json['phases'] != null
          ? (json['phases'] as List)
                .map((p) => Phase.fromJson(p as Map<String, dynamic>))
                .toList()
          : null,
      icon: json['icon'] as String?,
      customProperties: json['custom_properties'] != null
          ? (json['custom_properties'] is String
              ? jsonDecode(json['custom_properties'] as String)
                  as Map<String, dynamic>
              : json['custom_properties'] as Map<String, dynamic>)
          : null,
    );
  }

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
      'phases': phases?.map((p) => p.toJson()).toList() ?? [],
      'icon': icon,
      'custom_properties': customProperties,
    };
  }

  Goal copyWith({
    String? id,
    String? userId,
    String? title,
    String? currentState,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Phase>? phases,
    String? icon,
    Map<String, dynamic>? customProperties,
  }) {
    return Goal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      currentState: currentState ?? this.currentState,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      phases: phases ?? this.phases,
      icon: icon ?? this.icon,
      customProperties: customProperties ?? this.customProperties,
    );
  }
}
