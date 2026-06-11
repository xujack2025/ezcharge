import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/charging_reservation_charger_model.dart';

abstract class ChargingReservationServiceContract {
  Future<String?> getCurrentCustomerId();

  Future<List<ChargingReservationCharger>> fetchChargers(String stationId);

  Future<bool> isSlotTaken({
    required String chargerId,
    required DateTime startTime,
  });

  Future<void> createReservation({
    required String customerId,
    required String stationId,
    required String chargerId,
    required DateTime startTime,
  });
}

class ChargingReservationService implements ChargingReservationServiceContract {
  ChargingReservationService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Future<String?> getCurrentCustomerId() async {
    final phoneNumber = _auth.currentUser?.phoneNumber;
    if (phoneNumber == null || phoneNumber.isEmpty) {
      return null;
    }

    final snapshot = await _firestore
        .collection("Customers")
        .where("PhoneNumber", isEqualTo: phoneNumber)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return snapshot.docs.first.data()["CustomerID"]?.toString();
  }

  @override
  Future<List<ChargingReservationCharger>> fetchChargers(
    String stationId,
  ) async {
    final snapshot = await _firestore
        .collection("Station")
        .doc(stationId)
        .collection("Charger")
        .get();

    return snapshot.docs.map(ChargingReservationCharger.fromFirestore).toList();
  }

  @override
  Future<bool> isSlotTaken({
    required String chargerId,
    required DateTime startTime,
  }) async {
    final snapshot = await _firestore
        .collection("Reservation")
        .where("ChargerID", isEqualTo: chargerId)
        .get();
    final selectedTimestamp = Timestamp.fromDate(startTime);

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final storedTimestamp = data["StartTime"];
      if (storedTimestamp is Timestamp &&
          storedTimestamp.seconds == selectedTimestamp.seconds) {
        return true;
      }
    }

    return false;
  }

  @override
  Future<void> createReservation({
    required String customerId,
    required String stationId,
    required String chargerId,
    required DateTime startTime,
  }) async {
    final reservationId = "RSV${DateTime.now().millisecondsSinceEpoch}";

    await _firestore.collection("Reservation").doc(customerId).set({
      "ReservationID": reservationId,
      "ChargerID": chargerId,
      "StationID": stationId,
      "StartTime": Timestamp.fromDate(startTime),
      "ReservedTime": DateTime.now(),
      "Status": "Upcoming",
      "CustomerID": customerId,
    });
  }
}
