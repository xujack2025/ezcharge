import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/notification_model.dart';

abstract class NotificationServiceContract {
  Future<List<NotificationModel>> fetchNotifications();

  Future<DateTime> markAsRead(String notificationId);
}

class NotificationService implements NotificationServiceContract {
  NotificationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<List<NotificationModel>> fetchNotifications() async {
    final snapshot = await _firestore
        .collection("Notifications")
        .orderBy("CreatedTime", descending: true)
        .get();

    return snapshot.docs
        .map((doc) => NotificationModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<DateTime> markAsRead(String notificationId) async {
    final readTime = DateTime.now();
    await _firestore.collection("Notifications").doc(notificationId).update({
      "ReadTime": readTime,
    });
    return readTime;
  }
}
