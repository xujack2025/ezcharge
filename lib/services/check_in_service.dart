import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class CheckInServiceContract {
  String? getCurrentUserPhoneNumber();

  Future<String?> getCustomerIdByPhoneNumber(String phoneNumber);

  Future<String> getReservationStatus(String customerId);
}

class CheckInService implements CheckInServiceContract {
  CheckInService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

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
  Future<String> getReservationStatus(String customerId) async {
    final doc = await _firestore
        .collection("reservation")
        .doc(customerId)
        .get();
    if (!doc.exists) {
      return "Ended";
    }

    final data = doc.data();
    return data?["Status"]?.toString() ?? "Ended";
  }
}
