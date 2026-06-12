import 'package:cloud_firestore/cloud_firestore.dart';

class RatingCustomer {
  const RatingCustomer({required this.customerId, required this.displayName});

  final String customerId;
  final String displayName;
}

class RatingChargerBay {
  const RatingChargerBay({required this.chargerId, required this.chargerName});

  final String chargerId;
  final String chargerName;
}

class CustomerReview {
  const CustomerReview({
    required this.reviewId,
    required this.reviewText,
    required this.rating,
    this.reviewDate,
  });

  final String reviewId;
  final String reviewText;
  final int rating;
  final DateTime? reviewDate;

  factory CustomerReview.fromFirestore({
    required String documentId,
    required Map<String, dynamic> data,
  }) {
    return CustomerReview(
      reviewId: data['ReviewID']?.toString() ?? documentId,
      reviewText: data['ReviewText']?.toString() ?? '',
      rating: (data['Rating'] as num?)?.toInt() ?? 0,
      reviewDate: _dateTimeFromValue(data['ReviewDate']),
    );
  }
}

class CustomerComplaint {
  const CustomerComplaint({
    required this.documentId,
    required this.complaintId,
    required this.reason,
    required this.description,
    required this.status,
    required this.imageUrl,
    required this.chargerBay,
    this.complaintDate,
  });

  final String documentId;
  final String complaintId;
  final String reason;
  final String description;
  final String status;
  final String imageUrl;
  final String chargerBay;
  final DateTime? complaintDate;

  factory CustomerComplaint.fromFirestore({
    required String documentId,
    required Map<String, dynamic> data,
  }) {
    return CustomerComplaint(
      documentId: documentId,
      complaintId: data['ComplaintID']?.toString() ?? documentId,
      reason: data['Reason']?.toString() ?? '',
      description: data['Description']?.toString() ?? '',
      status: data['Status']?.toString() ?? 'Pending',
      imageUrl: data['ImageUrl']?.toString() ?? '',
      chargerBay: data['ChargerBay']?.toString() ?? '',
      complaintDate: _dateTimeFromValue(data['ComplaintDate']),
    );
  }
}

DateTime? _dateTimeFromValue(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}
