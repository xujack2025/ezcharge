import 'package:ezcharge/models/notification_model.dart';
import 'package:ezcharge/services/notification_service.dart';
import 'package:ezcharge/viewmodels/application/notification_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeNotificationService implements NotificationServiceContract {
  FakeNotificationService({this.notifications = const []});

  final List<NotificationModel> notifications;
  String? markedNotificationId;
  DateTime readTime = DateTime(2026, 1, 1, 12);

  @override
  Future<List<NotificationModel>> fetchNotifications() async {
    return notifications;
  }

  @override
  Future<DateTime> markAsRead(String notificationId) async {
    markedNotificationId = notificationId;
    return readTime;
  }
}

void main() {
  final unreadNotification = NotificationModel(
    notificationID: "NTF1",
    title: "New charger",
    description: "A new charger is available.",
    createdTime: DateTime(2026),
  );

  group('ApplicationNotificationViewModel', () {
    test('loads notifications from service', () async {
      final service = FakeNotificationService(
        notifications: [unreadNotification],
      );
      final viewModel = ApplicationNotificationViewModel(
        notificationService: service,
      );

      await viewModel.loadNotifications();

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.notifications, [unreadNotification]);
      expect(viewModel.hasUnreadNotifications, isTrue);
    });

    test('marks notification as read and updates local state', () async {
      final service = FakeNotificationService(
        notifications: [unreadNotification],
      );
      final viewModel = ApplicationNotificationViewModel(
        notificationService: service,
      );

      await viewModel.loadNotifications();
      await viewModel.markAsRead("NTF1");

      expect(service.markedNotificationId, "NTF1");
      expect(viewModel.notifications.single.readTime, service.readTime);
      expect(viewModel.hasUnreadNotifications, isFalse);
    });
  });
}
