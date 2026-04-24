import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String notificationID;
  final String title;
  final String description;
  final DateTime createdTime;
  final String? readTime;

  NotificationModel({
    required this.notificationID,
    required this.title,
    required this.description,
    required this.createdTime,
    this.readTime,
  });

  factory NotificationModel.fromFirestore(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return NotificationModel(
      notificationID: documentId,
      title: data['Title'] ?? '',
      description: data['Description'] ?? '',
      createdTime: (data['CreatedTime'] as Timestamp).toDate(),
      readTime: data['ReadTime'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'NotificationID': notificationID,
      'Title': title,
      'Description': description,
      'CreatedTime': createdTime,
      'ReadTime': readTime,
    };
  }
}
