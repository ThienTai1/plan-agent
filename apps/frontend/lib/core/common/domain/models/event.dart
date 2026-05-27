import 'package:flutter/material.dart';

class Event {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final Color? color;
  final bool isAllDay;
  final DateTime createdAt;
  final DateTime updatedAt;

  Event({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.location,
    this.color,
    this.isAllDay = false,
    required this.createdAt,
    required this.updatedAt,
  });
}
