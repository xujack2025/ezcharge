import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String notificationID;
  final String title;
  final String description;
  final DateTime createdTime;
  final DateTime? readTime;

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
      createdTime: _parseDateTime(data['CreatedTime']) ?? DateTime.now(),
      readTime: _parseDateTime(data['ReadTime']),
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

  bool get isRead => readTime != null;

  NotificationModel copyWith({DateTime? readTime}) {
    return NotificationModel(
      notificationID: notificationID,
      title: title,
      description: description,
      createdTime: createdTime,
      readTime: readTime ?? this.readTime,
    );
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}
