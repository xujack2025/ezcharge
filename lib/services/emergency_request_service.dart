import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/emergency_request_model.dart';

class ActiveEmergencyRequest {
  const ActiveEmergencyRequest({required this.exists, this.requestId});

  final bool exists;
  final String? requestId;
}

abstract class EmergencyRequestServiceContract {
  String? getCurrentUserPhoneNumber();

  Future<String?> getCustomerIdByPhoneNumber(String phoneNumber);

  Stream<ActiveEmergencyRequest> watchActiveRequest(String customerId);

  Stream<List<EmergencyRequest>> watchRequests(String customerId);

  Future<void> createRequest(EmergencyRequest request);

  Future<void> updateRequestStatus(String requestID, String status);

  Future<String> uploadRequestImage(File image);

  Future<String> getPowerBankImageUrl();

  Future<String?> getDriverId(String requestId);

  Stream<String?> watchDriverId(String requestId);

  Future<void> startCharging(String requestID);

  Future<void> updateChargingComplete(String requestID, double kWhUsed);

  Future<void> processPayment(String requestID);
}

class EmergencyRequestService implements EmergencyRequestServiceContract {
  EmergencyRequestService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  static const List<String> _activeStatuses = [
    "Pending",
    "Upcoming",
    "Arrived",
    "Charging",
    "Payment",
  ];

  @override
  String? getCurrentUserPhoneNumber() {
    return _auth.currentUser?.phoneNumber;
  }

  @override
  Future<String?> getCustomerIdByPhoneNumber(String phoneNumber) async {
    final querySnapshot = await _firestore
        .collection("customers")
        .where("PhoneNumber", isEqualTo: phoneNumber)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return null;
    }

    final data = querySnapshot.docs.first.data();
    return data["CustomerID"]?.toString();
  }

  @override
  Stream<ActiveEmergencyRequest> watchActiveRequest(String customerId) {
    return _firestore
        .collection("emergency_requests")
        .where("CustomerID", isEqualTo: customerId)
        .where("status", whereIn: _activeStatuses)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            return const ActiveEmergencyRequest(exists: false);
          }

          return ActiveEmergencyRequest(
            exists: true,
            requestId: snapshot.docs.first.id,
          );
        });
  }

  @override
  Stream<List<EmergencyRequest>> watchRequests(String customerId) {
    return _firestore
        .collection("emergency_requests")
        .where("CustomerID", isEqualTo: customerId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => EmergencyRequest.fromMap(doc.data()))
              .toList(),
        );
  }

  @override
  Future<void> createRequest(EmergencyRequest request) async {
    await _firestore
        .collection("emergency_requests")
        .doc(request.requestID)
        .set(request.toMap());
  }

  @override
  Future<void> updateRequestStatus(String requestID, String status) async {
    await _firestore.collection("emergency_requests").doc(requestID).update({
      "status": status,
    });
  }

  @override
  Future<String> uploadRequestImage(File image) async {
    final fileName =
        "requests/RQImage${DateTime.now().millisecondsSinceEpoch}.jpg";
    final ref = _storage.ref().child(fileName);
    final taskSnapshot = await ref.putFile(image);
    return taskSnapshot.ref.getDownloadURL();
  }

  @override
  Future<String> getPowerBankImageUrl() {
    return _storage.ref("images/power_bank.png").getDownloadURL();
  }

  @override
  Future<String?> getDriverId(String requestId) async {
    final requestSnapshot = await _firestore
        .collection("emergency_requests")
        .doc(requestId)
        .get();

    if (!requestSnapshot.exists) {
      return null;
    }

    final data = requestSnapshot.data();
    return data?["driverID"]?.toString();
  }

  @override
  Stream<String?> watchDriverId(String requestId) {
    return _firestore
        .collection("emergency_requests")
        .doc(requestId)
        .snapshots()
        .map((snapshot) => snapshot.data()?["driverID"]?.toString());
  }

  @override
  Future<void> startCharging(String requestID) async {
    await updateRequestStatus(requestID, "Charging");
  }

  @override
  Future<void> updateChargingComplete(String requestID, double kWhUsed) async {
    const baseFee = 8.0;
    const perKWhCharge = 1.5;
    final totalCost = baseFee + (kWhUsed * perKWhCharge);

    await _firestore.collection("emergency_requests").doc(requestID).update({
      "kWhUsed": kWhUsed,
      "estimatedCost": totalCost,
      "status": "Payment",
    });
  }

  @override
  Future<void> processPayment(String requestID) async {
    await updateRequestStatus(requestID, "Completed");
  }
}
