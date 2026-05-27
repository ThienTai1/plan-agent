import 'package:flutter/material.dart';

class GoalTask {
  final String id;
  final String title;
  final String? description;
  final String? phaseId; // Optional link to a Phase
  final String? goalId; // Optional direct link to a Goal
  final DateTime? startTime;
  final DateTime? endTime;
  final bool isCompleted;
  final bool isEvent; // Differentiates betweeen a Task and a Calendar Event
  final Color? color;

  GoalTask({
    required this.id,
    required this.title,
    this.description,
    this.phaseId,
    this.goalId,
    this.startTime,
    this.endTime,
    this.isCompleted = false,
    this.isEvent = false,
    this.color,
  });
}
