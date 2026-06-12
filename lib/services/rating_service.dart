import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../core/utils/app_logger.dart';
import '../models/customer_rating_model.dart';

abstract class RatingServiceContract {
  Future<RatingCustomer?> fetchCurrentCustomer();

  Future<List<RatingChargerBay>> fetchChargingBays(String stationId);

  Future<void> submitComplaint({
    required String stationId,
    required String chargerId,
    required String chargerName,
    required String reason,
    required String description,
    File? image,
  });

  Future<void> submitReview({
    required String stationId,
    required int rating,
    required String reviewText,
  });

  Stream<List<CustomerReview>> watchCurrentCustomerReviews();

  Future<void> updateReview({
    required String reviewId,
    required String reviewText,
    required int rating,
  });

  Future<void> deleteReview(String reviewId);

  Stream<List<CustomerComplaint>> watchCurrentCustomerComplaints();
}

class RatingCustomerNotFoundException implements Exception {
  const RatingCustomerNotFoundException();
}

class RatingService implements RatingServiceContract {
  RatingService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  @override
  Future<RatingCustomer?> fetchCurrentCustomer() async {
    final phoneNumber = _auth.currentUser?.phoneNumber;
    if (phoneNumber == null || phoneNumber.isEmpty) return null;

    final querySnapshot = await _firestore
        .collection('Customers')
        .where('PhoneNumber', isEqualTo: phoneNumber)
        .limit(1)
        .get();
    if (querySnapshot.docs.isEmpty) return null;

    final data = querySnapshot.docs.first.data();
    final firstName = data['FirstName']?.toString() ?? '';
    final lastName = data['LastName']?.toString() ?? '';
    final displayName = '$firstName $lastName'.trim();
    return RatingCustomer(
      customerId: data['CustomerID']?.toString() ?? querySnapshot.docs.first.id,
      displayName: displayName.isEmpty ? 'Guest' : displayName,
    );
  }

  @override
  Future<List<RatingChargerBay>> fetchChargingBays(String stationId) async {
    final querySnapshot = await _firestore
        .collection('Station')
        .doc(stationId)
        .collection('Charger')
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      return RatingChargerBay(
        chargerId: data['ChargerID']?.toString() ?? doc.id,
        chargerName: data['ChargerName']?.toString() ?? 'Unknown Bay',
      );
    }).toList();
  }

  @override
  Future<void> submitComplaint({
    required String stationId,
    required String chargerId,
    required String chargerName,
    required String reason,
    required String description,
    File? image,
  }) async {
    final customer = await _requireCurrentCustomer();
    final complaintId = await _generateComplaintId(customer.customerId);
    final complaintDocId = '${customer.customerId}-$complaintId';
    final imageUrl = image == null
        ? ''
        : await _uploadComplaintImage(
            stationId: stationId,
            complaintDocId: complaintDocId,
            image: image,
          );

    await _firestore
        .collection('Customers')
        .doc(customer.customerId)
        .collection('complaints')
        .doc(complaintDocId)
        .set({
          'ComplaintID': complaintId,
          'CustomerID': customer.customerId,
          'StationID': stationId,
          'SlotID': chargerId,
          'ChargerBay': chargerName,
          'Reason': reason,
          'Description': description,
          'ImageUrl': imageUrl,
          'ComplaintDate': FieldValue.serverTimestamp(),
          'resolvedAt': null,
          'AdminID': null,
          'AssignedStaffID': null,
          'Status': 'Pending',
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  @override
  Future<void> submitReview({
    required String stationId,
    required int rating,
    required String reviewText,
  }) async {
    final customer = await _requireCurrentCustomer();
    final reviewId = await _generateReviewId();

    await _firestore.collection('Reviews').doc(reviewId).set({
      'ReviewID': reviewId,
      'StationID': stationId,
      'CustomerID': customer.customerId,
      'CustomerName': customer.displayName,
      'Rating': rating,
      'ReviewText': reviewText,
      'ReviewDate': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<CustomerReview>> watchCurrentCustomerReviews() async* {
    final customer = await _requireCurrentCustomer();
    yield* _firestore
        .collection('Reviews')
        .where('CustomerID', isEqualTo: customer.customerId)
        .orderBy('ReviewDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => CustomerReview.fromFirestore(
                  documentId: doc.id,
                  data: doc.data(),
                ),
              )
              .toList(),
        );
  }

  @override
  Future<void> updateReview({
    required String reviewId,
    required String reviewText,
    required int rating,
  }) async {
    await _firestore.collection('Reviews').doc(reviewId).update({
      'ReviewText': reviewText,
      'Rating': rating,
    });
  }

  @override
  Future<void> deleteReview(String reviewId) {
    return _firestore.collection('Reviews').doc(reviewId).delete();
  }

  @override
  Stream<List<CustomerComplaint>> watchCurrentCustomerComplaints() async* {
    final customer = await _requireCurrentCustomer();
    yield* _firestore
        .collection('Customers')
        .doc(customer.customerId)
        .collection('complaints')
        .orderBy('ComplaintDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => CustomerComplaint.fromFirestore(
                  documentId: doc.id,
                  data: doc.data(),
                ),
              )
              .toList(),
        );
  }

  Future<RatingCustomer> _requireCurrentCustomer() async {
    final customer = await fetchCurrentCustomer();
    if (customer == null) {
      throw const RatingCustomerNotFoundException();
    }
    return customer;
  }

  Future<String> _generateComplaintId(String customerId) async {
    final complaintSnapshot = await _firestore
        .collection('Customers')
        .doc(customerId)
        .collection('complaints')
        .orderBy('ComplaintID', descending: true)
        .limit(1)
        .get();

    if (complaintSnapshot.docs.isEmpty) return 'CMP0001';
    final lastComplaintId = complaintSnapshot.docs.first['ComplaintID']
        ?.toString();
    final match = RegExp(r'CMP(\d+)$').firstMatch(lastComplaintId ?? '');
    if (match == null) return 'CMP0001';

    final lastNumber = int.parse(match.group(1)!);
    return 'CMP${(lastNumber + 1).toString().padLeft(4, '0')}';
  }

  Future<String> _generateReviewId() async {
    final lastReviewSnapshot = await _firestore
        .collection('Reviews')
        .orderBy('ReviewID', descending: true)
        .limit(1)
        .get();

    if (lastReviewSnapshot.docs.isEmpty) return 'RVW0001';
    final lastReviewId = lastReviewSnapshot.docs.first['ReviewID']?.toString();
    final match = RegExp(r'RVW(\d{4})$').firstMatch(lastReviewId ?? '');
    if (match == null) return 'RVW0001';

    final lastNumber = int.parse(match.group(1)!);
    return 'RVW${(lastNumber + 1).toString().padLeft(4, '0')}';
  }

  Future<String> _uploadComplaintImage({
    required String stationId,
    required String complaintDocId,
    required File image,
  }) async {
    try {
      final storageRef = _storage.ref().child(
        'complaints/$stationId/$complaintDocId.jpg',
      );
      final snapshot = await storageRef.putFile(image);
      return snapshot.ref.getDownloadURL();
    } catch (e) {
      AppLogger.error('Error uploading complaint image: $e');
      rethrow;
    }
  }
}
