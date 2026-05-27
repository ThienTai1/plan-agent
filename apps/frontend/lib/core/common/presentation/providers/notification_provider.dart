import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/common/domain/models/notification_model.dart';
import 'package:uuid/uuid.dart';

class NotificationNotifier extends Notifier<List<NotificationModel>> {
  @override
  List<NotificationModel> build() {
    // Initial mock notifications for demonstration
    return [
      NotificationModel(
        id: const Uuid().v4(),
        title: 'Welcome to Neural Canvas',
        message: 'Master your day with the daily timeline and goal tracking.',
        type: NotificationType.info,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        isRead: false,
      ),
      NotificationModel(
        id: const Uuid().v4(),
        title: 'New Goal Created',
        message: '\"Implement specialized list filters\" is now active.',
        type: NotificationType.success,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: false,
      ),
      NotificationModel(
        id: const Uuid().v4(),
        title: 'Task Overdue',
        message: 'The task \"Fix filter providers\" was due 2 hours ago.',
        type: NotificationType.warning,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: true,
      ),
    ];
  }

  void addNotification({
    required String title,
    required String message,
    NotificationType type = NotificationType.info,
  }) {
    final newNotification = NotificationModel(
      id: const Uuid().v4(),
      title: title,
      message: message,
      type: type,
      timestamp: DateTime.now(),
    );
    state = [newNotification, ...state];
  }

  void markAsRead(String id) {
    state = [
      for (final n in state)
        if (n.id == id) n.copyWith(isRead: true) else n,
    ];
  }

  void markAllAsRead() {
    state = [
      for (final n in state) n.copyWith(isRead: true),
    ];
  }

  void removeNotification(String id) {
    state = state.where((n) => n.id != id).toList();
  }

  void clearAll() {
    state = [];
  }
}

final notificationProvider =
    NotifierProvider<NotificationNotifier, List<NotificationModel>>(() {
  return NotificationNotifier();
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationProvider);
  return notifications.where((n) => !n.isRead).length;
});
