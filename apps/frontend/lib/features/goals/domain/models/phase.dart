import 'task.dart';

class Phase {
  final String id;
  final String goalId;
  final String title;
  final String? description;
  final int orderIndex;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final List<Task>? tasks;

  Phase({
    required this.id,
    required this.goalId,
    required this.title,
    this.description,
    required this.orderIndex,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.tasks,
  });

  factory Phase.fromJson(Map<String, dynamic> json) {
    return Phase(
      id: json['id'] as String,
      goalId: json['goal_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      orderIndex: json['order_index'] as int,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      status: json['status'] as String? ?? 'active',
      tasks: json['tasks'] != null
          ? (json['tasks'] as List)
              .map((t) => Task.fromJson(t as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'goal_id': goalId,
      'title': title,
      'description': description,
      'order_index': orderIndex,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'status': status,
      'tasks': tasks?.map((t) => t.toJson()).toList(),
    };
  }
}

