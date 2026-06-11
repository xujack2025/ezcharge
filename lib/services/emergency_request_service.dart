import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/emergency_request_model.dart';
import 'auth_service.dart';

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
    AuthServiceContract? authService,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _authService = authService ?? AuthService(),
       _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final AuthServiceContract _authService;
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
    return _authService.getCurrentUserPhoneNumber();
  }

  @override
  Future<String?> getCustomerIdByPhoneNumber(String phoneNumber) async {
    final customer = await _authService.getCustomerByPhoneNumber(phoneNumber);
    return customer?.id;
  }

  @override
  Stream<ActiveEmergencyRequest> watchActiveRequest(String customerId) {
    return _firestore
        .collection("EmergencyRequests")
        .where("CustomerID", isEqualTo: customerId)
        .where("Status", whereIn: _activeStatuses)
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
        .collection("EmergencyRequests")
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
        .collection("EmergencyRequests")
        .doc(request.requestID)
        .set(request.toMap());
  }

  @override
  Future<void> updateRequestStatus(String requestID, String status) async {
    await _firestore.collection("EmergencyRequests").doc(requestID).update({
      "Status": status,
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
        .collection("EmergencyRequests")
        .doc(requestId)
        .get();

    if (!requestSnapshot.exists) {
      return null;
    }

    final data = requestSnapshot.data();
    return data?["DriverID"]?.toString();
  }

  @override
  Stream<String?> watchDriverId(String requestId) {
    return _firestore
        .collection("EmergencyRequests")
        .doc(requestId)
        .snapshots()
        .map((snapshot) => snapshot.data()?["DriverID"]?.toString());
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

    await _firestore.collection("EmergencyRequests").doc(requestID).update({
      "KWhUsed": kWhUsed,
      "EstimatedCost": totalCost,
      "Status": "Payment",
    });
  }

  @override
  Future<void> processPayment(String requestID) async {
    await updateRequestStatus(requestID, "Completed");
  }
}
