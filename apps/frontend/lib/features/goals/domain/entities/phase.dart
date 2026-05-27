class Phase {
  final String id;
  final String goalId;
  final String title;
  final int order;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isCompleted;

  Phase({
    required this.id,
    required this.goalId,
    required this.title,
    required this.order,
    this.startDate,
    this.endDate,
    this.isCompleted = false,
  });
}
