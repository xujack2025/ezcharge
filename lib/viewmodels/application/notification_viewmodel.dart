import 'package:flutter/foundation.dart';

import '../../core/utils/app_logger.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';

class ApplicationNotificationViewModel extends ChangeNotifier {
  ApplicationNotificationViewModel({
    NotificationServiceContract? notificationService,
  }) : _notificationService = notificationService ?? NotificationService();

  final NotificationServiceContract _notificationService;

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasUnreadNotifications =>
      _notifications.any((notification) => !notification.isRead);

  Future<void> loadNotifications() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _notifications = await _notificationService.fetchNotifications();
    } catch (e) {
      AppLogger.error("Error fetching notifications: $e");
      _errorMessage = "Failed to load notifications.";
      _notifications = [];
    } finally {
      _setLoading(false);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final readTime = await _notificationService.markAsRead(notificationId);
      _notifications = _notifications.map((notification) {
        if (notification.notificationID != notificationId) {
          return notification;
        }
        return notification.copyWith(readTime: readTime);
      }).toList();
      notifyListeners();
    } catch (e) {
      AppLogger.error("Error marking notification as read: $e");
      _errorMessage = "Failed to update notification.";
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
