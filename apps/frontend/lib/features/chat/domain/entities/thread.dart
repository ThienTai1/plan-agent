class Thread {
  final String id;
  final String? title;
  final DateTime createdAt;
  final DateTime updatedAt;

  Thread({
    required this.id,
    this.title,
    required this.createdAt,
    required this.updatedAt,
  });
}
