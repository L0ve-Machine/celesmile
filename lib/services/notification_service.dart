import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mysql_service.dart';
import 'auth_service.dart';

// Notification Types
enum NotificationType {
  newBooking,        // Provider receives when someone books their service
  bookingReminder,   // User receives 1 hour before their booking
  bookingConfirmed,  // User receives when provider confirms booking
  bookingCancelled,  // Both receive when booking is cancelled
  newCoupon,         // User receives when they get a new coupon
  couponExpiring,    // User receives when coupon is about to expire
  systemAnnouncement, // Admin announcements
}

// Notification Model
class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final String? link; // Optional link to navigate to
  final DateTime createdAt;
  final bool isRead;
  final String? relatedId; // booking_id, coupon_id, etc.
  final String? targetUserId; // Who should receive this notification
  final String? targetProviderId; // For provider notifications

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.link,
    required this.createdAt,
    this.isRead = false,
    this.relatedId,
    this.targetUserId,
    this.targetProviderId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'type': type.toString().split('.').last,
    'link': link,
    'created_at': createdAt.toIso8601String(),
    'is_read': isRead,
    'related_id': relatedId,
    'target_user_id': targetUserId,
    'target_provider_id': targetProviderId,
  };

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      type: NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => NotificationType.systemAnnouncement,
      ),
      link: json['link'],
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      relatedId: json['related_id'],
      targetUserId: json['target_user_id'],
      targetProviderId: json['target_provider_id'],
    );
  }
}

// Notification Service - Handles all notification logic
class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // In-memory storage for notifications (will be synced with server)
  final List<NotificationModel> _notifications = [];

  // Stream controller for real-time notification updates
  final StreamController<List<NotificationModel>> _notificationController =
      StreamController<List<NotificationModel>>.broadcast();

  Stream<List<NotificationModel>> get notificationStream => _notificationController.stream;

  // Timer for checking upcoming bookings
  Timer? _reminderTimer;

  // Initialize the service
  void initialize() {
    // Start checking for upcoming bookings every minute
    _reminderTimer?.cancel();
    _reminderTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkUpcomingBookings();
    });

    // Load existing notifications
    _loadNotifications();
  }

  // Request notification permission on first launch
  static Future<bool> requestNotificationPermission() async {
    // Check if we've already asked for permission
    final prefs = await SharedPreferences.getInstance();
    final hasAsked = prefs.getBool('notification_permission_asked') ?? false;

    if (hasAsked) {
      // Already asked, just return current status
      final status = await Permission.notification.status;
      return status.isGranted;
    }

    // Mark that we've asked
    await prefs.setBool('notification_permission_asked', true);

    // Request permission
    if (kIsWeb) {
      // Web doesn't support permission_handler
      return false;
    }

    final status = await Permission.notification.request();
    return status.isGranted;
  }

  // Check if notification permission is granted
  static Future<bool> isNotificationPermissionGranted() async {
    if (kIsWeb) return false;
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  // Check if this is first launch (permission not yet asked)
  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('notification_permission_asked') ?? false);
  }

  // Dispose
  void dispose() {
    _reminderTimer?.cancel();
    _notificationController.close();
  }

  // Load notifications from server
  Future<void> _loadNotifications() async {
    try {
      final userId = AuthService.currentUser;
      final providerId = AuthService.currentUserProviderId;

      if (userId != null) {
        final userNotifications = await MySQLService.instance.getUserNotifications(userId);
        _notifications.clear();
        _notifications.addAll(userNotifications.map((n) => NotificationModel.fromJson(n)));
      }

      if (providerId != null) {
        final providerNotifications = await MySQLService.instance.getProviderNotifications(providerId);
        for (var n in providerNotifications) {
          final notification = NotificationModel.fromJson(n);
          if (!_notifications.any((existing) => existing.id == notification.id)) {
            _notifications.add(notification);
          }
        }
      }

      // Sort by date, newest first
      _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _notificationController.add(_notifications);
    } catch (e) {
      print('Error loading notifications: $e');
    }
  }

  // Get all notifications for current user/provider
  List<NotificationModel> getNotifications() {
    return List.unmodifiable(_notifications);
  }

  // Get unread notification count
  int getUnreadCount() {
    return _notifications.where((n) => !n.isRead).length;
  }

  // Check if there are any unread notifications
  bool hasUnreadNotifications() {
    return _notifications.any((n) => !n.isRead);
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      final notification = _notifications[index];
      _notifications[index] = NotificationModel(
        id: notification.id,
        title: notification.title,
        message: notification.message,
        type: notification.type,
        link: notification.link,
        createdAt: notification.createdAt,
        isRead: true,
        relatedId: notification.relatedId,
        targetUserId: notification.targetUserId,
        targetProviderId: notification.targetProviderId,
      );
      _notificationController.add(_notifications);

      // Update on server
      await MySQLService.instance.markNotificationAsRead(notificationId);
    }
  }

  // Mark all as read
  Future<void> markAllAsRead() async {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        final notification = _notifications[i];
        _notifications[i] = NotificationModel(
          id: notification.id,
          title: notification.title,
          message: notification.message,
          type: notification.type,
          link: notification.link,
          createdAt: notification.createdAt,
          isRead: true,
          relatedId: notification.relatedId,
          targetUserId: notification.targetUserId,
          targetProviderId: notification.targetProviderId,
        );
      }
    }
    _notificationController.add(_notifications);

    // Update on server
    final userId = AuthService.currentUser;
    final providerId = AuthService.currentUserProviderId;
    if (userId != null) {
      await MySQLService.instance.markAllNotificationsAsRead(userId: userId);
    }
    if (providerId != null) {
      await MySQLService.instance.markAllNotificationsAsRead(providerId: providerId);
    }
  }

  // =====================================================
  // BOOKING NOTIFICATIONS
  // =====================================================

  // Send notification to provider when someone books their service
  Future<void> notifyProviderNewBooking({
    required String providerId,
    required String bookingId,
    required String customerName,
    required String serviceName,
    required DateTime bookingDate,
    required String timeSlot,
  }) async {
    final notification = NotificationModel(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: '新しい予約が入りました',
      message: '$customerNameさんから「$serviceName」の予約が入りました。\n日時: ${_formatDate(bookingDate)} $timeSlot',
      type: NotificationType.newBooking,
      createdAt: DateTime.now(),
      relatedId: bookingId,
      targetProviderId: providerId,
      link: '/provider-bookings',
    );

    await _saveNotification(notification);
    print('✅ Notification sent to provider $providerId for new booking');
  }

  // Send reminder to user 1 hour before their booking
  Future<void> notifyUserBookingReminder({
    required String userId,
    required String bookingId,
    required String serviceName,
    required String providerName,
    required DateTime bookingDate,
    required String timeSlot,
  }) async {
    final notification = NotificationModel(
      id: 'notif_reminder_${DateTime.now().millisecondsSinceEpoch}',
      title: 'まもなく予約の時間です',
      message: '「$serviceName」の予約が1時間後に始まります。\n担当: $providerName\n時間: $timeSlot',
      type: NotificationType.bookingReminder,
      createdAt: DateTime.now(),
      relatedId: bookingId,
      targetUserId: userId,
      link: '/booking-history',
    );

    await _saveNotification(notification);
    print('✅ Reminder notification sent to user $userId');
  }

  // Send notification when booking is confirmed
  Future<void> notifyUserBookingConfirmed({
    required String userId,
    required String bookingId,
    required String serviceName,
    required String providerName,
    required DateTime bookingDate,
    required String timeSlot,
  }) async {
    final notification = NotificationModel(
      id: 'notif_confirmed_${DateTime.now().millisecondsSinceEpoch}',
      title: '予約が確定しました',
      message: '「$serviceName」の予約が確定しました。\n担当: $providerName\n日時: ${_formatDate(bookingDate)} $timeSlot',
      type: NotificationType.bookingConfirmed,
      createdAt: DateTime.now(),
      relatedId: bookingId,
      targetUserId: userId,
      link: '/booking-history',
    );

    await _saveNotification(notification);
  }

  // Send notification when booking is cancelled
  Future<void> notifyBookingCancelled({
    String? userId,
    String? providerId,
    required String bookingId,
    required String serviceName,
    required DateTime bookingDate,
    required String reason,
  }) async {
    final message = '「$serviceName」の予約がキャンセルされました。\n日時: ${_formatDate(bookingDate)}\n理由: $reason';

    if (userId != null) {
      final userNotification = NotificationModel(
        id: 'notif_cancel_user_${DateTime.now().millisecondsSinceEpoch}',
        title: '予約がキャンセルされました',
        message: message,
        type: NotificationType.bookingCancelled,
        createdAt: DateTime.now(),
        relatedId: bookingId,
        targetUserId: userId,
        link: '/booking-history',
      );
      await _saveNotification(userNotification);
    }

    if (providerId != null) {
      final providerNotification = NotificationModel(
        id: 'notif_cancel_provider_${DateTime.now().millisecondsSinceEpoch}',
        title: '予約がキャンセルされました',
        message: message,
        type: NotificationType.bookingCancelled,
        createdAt: DateTime.now(),
        relatedId: bookingId,
        targetProviderId: providerId,
        link: '/provider-bookings',
      );
      await _saveNotification(providerNotification);
    }
  }

  // =====================================================
  // COUPON NOTIFICATIONS
  // =====================================================

  // Send notification when user receives a new coupon
  Future<void> notifyUserNewCoupon({
    required String userId,
    required String couponId,
    required String couponName,
    required int discountAmount,
    required DateTime expiryDate,
  }) async {
    final notification = NotificationModel(
      id: 'notif_coupon_${DateTime.now().millisecondsSinceEpoch}',
      title: '新しいクーポンを獲得しました！',
      message: '「$couponName」(¥$discountAmount OFF)を獲得しました。\n有効期限: ${_formatDate(expiryDate)}',
      type: NotificationType.newCoupon,
      createdAt: DateTime.now(),
      relatedId: couponId,
      targetUserId: userId,
      link: '/user-settings',
    );

    await _saveNotification(notification);
    print('✅ Coupon notification sent to user $userId');
  }

  // Send notification when coupon is about to expire
  Future<void> notifyUserCouponExpiring({
    required String userId,
    required String couponId,
    required String couponName,
    required int daysUntilExpiry,
  }) async {
    final notification = NotificationModel(
      id: 'notif_coupon_expiring_${DateTime.now().millisecondsSinceEpoch}',
      title: 'クーポンの有効期限が近づいています',
      message: '「$couponName」の有効期限が$daysUntilExpiry日後に切れます。お早めにご利用ください。',
      type: NotificationType.couponExpiring,
      createdAt: DateTime.now(),
      relatedId: couponId,
      targetUserId: userId,
      link: '/user-settings',
    );

    await _saveNotification(notification);
  }

  // =====================================================
  // HELPER METHODS
  // =====================================================

  // Check for upcoming bookings and send reminders
  Future<void> _checkUpcomingBookings() async {
    try {
      final userId = AuthService.currentUser;
      if (userId == null) return;

      final now = DateTime.now();
      final oneHourFromNow = now.add(const Duration(hours: 1));

      // Get user's upcoming bookings
      final bookings = await MySQLService.instance.getUserUpcomingBookings(userId);

      for (var booking in bookings) {
        final bookingDateTime = _parseBookingDateTime(
          booking['booking_date'],
          booking['time_slot'],
        );

        if (bookingDateTime != null) {
          // Check if booking is within the next hour (± 5 minutes)
          final difference = bookingDateTime.difference(now);
          if (difference.inMinutes >= 55 && difference.inMinutes <= 65) {
            // Check if reminder was already sent
            final reminderId = 'reminder_${booking['id']}';
            final alreadySent = _notifications.any((n) =>
              n.id.contains(reminderId) ||
              (n.relatedId == booking['id'] && n.type == NotificationType.bookingReminder)
            );

            if (!alreadySent) {
              await notifyUserBookingReminder(
                userId: userId,
                bookingId: booking['id'],
                serviceName: booking['service_name'] ?? 'サービス',
                providerName: booking['provider_name'] ?? 'プロバイダー',
                bookingDate: DateTime.parse(booking['booking_date']),
                timeSlot: booking['time_slot'] ?? '',
              );
            }
          }
        }
      }
    } catch (e) {
      print('Error checking upcoming bookings: $e');
    }
  }

  DateTime? _parseBookingDateTime(String? dateStr, String? timeSlot) {
    if (dateStr == null || timeSlot == null) return null;

    try {
      final date = DateTime.parse(dateStr.split('T')[0]);
      final timeParts = timeSlot.split(':');
      if (timeParts.length >= 2) {
        return DateTime(
          date.year,
          date.month,
          date.day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );
      }
    } catch (e) {
      print('Error parsing booking datetime: $e');
    }
    return null;
  }

  String _formatDate(DateTime date) {
    return '${date.year}年${date.month}月${date.day}日';
  }

  // Save notification locally and to server
  Future<void> _saveNotification(NotificationModel notification) async {
    _notifications.insert(0, notification);
    _notificationController.add(_notifications);

    // Save to server
    try {
      await MySQLService.instance.createNotification(notification.toJson());
    } catch (e) {
      print('Error saving notification to server: $e');
    }
  }

  // Add notification (for admin/system use)
  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    _notificationController.add(_notifications);
  }

  // Refresh notifications from server
  Future<void> refresh() async {
    await _loadNotifications();
  }
}
