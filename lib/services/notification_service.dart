// Notification Model
class NotificationModel {
  final String id;
  final String message;
  final String? link; // Optional link to navigate to
  final DateTime createdAt;
  final bool isActive;

  NotificationModel({
    required this.id,
    required this.message,
    this.link,
    required this.createdAt,
    required this.isActive,
  });
}

// Notification Service - Admin manages notifications
class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // In-memory storage for notifications
  // In a real app, this would be fetched from Firebase/API
  final List<NotificationModel> _notifications = [];

  // Get active notifications
  List<NotificationModel> getActiveNotifications() {
    return _notifications
        .where((notification) => notification.isActive)
        .toList();
  }

  // Check if there are any active notifications
  bool hasActiveNotifications() {
    return _notifications.any((notification) => notification.isActive);
  }

  // Add notification (for testing purposes)
  // In production, this would be done through admin panel
  void addNotification(NotificationModel notification) {
    _notifications.add(notification);
  }

  // Example: To add a notification, call this method from your admin panel:
  // NotificationService().addNotification(
  //   NotificationModel(
  //     id: '1',
  //     message: '「ミニミ宅割」についてのお知らせ',
  //     createdAt: DateTime.now(),
  //     isActive: true,
  //   ),
  // );
}
