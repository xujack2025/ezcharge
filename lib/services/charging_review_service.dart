import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../models/charging_review_model.dart';

abstract class ChargingReviewServiceContract {
  Future<ChargingReviewUser?> fetchCurrentReviewUser();

  Future<void> submitReview({
    required String customerId,
    required String stationId,
    required int rating,
    required String comment,
    DateTime? submittedAt,
  });
}

class ChargingReviewService implements ChargingReviewServiceContract {
  ChargingReviewService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Future<ChargingReviewUser?> fetchCurrentReviewUser() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null || userId.isEmpty) return null;

    final userDoc = await _firestore.collection('Customers').doc(userId).get();
    if (!userDoc.exists) return null;

    final data = userDoc.data() ?? {};
    final firstName = data['FirstName']?.toString() ?? '';
    final lastName = data['LastName']?.toString() ?? '';

    return ChargingReviewUser(
      customerId: data['CustomerID']?.toString() ?? userDoc.id,
      username: '$firstName $lastName'.trim(),
    );
  }

  @override
  Future<void> submitReview({
    required String customerId,
    required String stationId,
    required int rating,
    required String comment,
    DateTime? submittedAt,
  }) async {
    final now = submittedAt ?? DateTime.now();
    final ratingId = 'RTG${now.millisecondsSinceEpoch}';

    await _firestore
        .collection('Customers')
        .doc(customerId)
        .collection('Rating')
        .doc(ratingId)
        .set({
          'RatingID': ratingId,
          'StationID': stationId,
          'CustomerID': customerId,
          'Rating': rating,
          'Comments': comment,
          'RatingDate': DateFormat('yyyy-MM-dd HH:mm:ss').format(now),
        });
  }
}
