import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/charging_session_model.dart';

abstract class ChargingSessionServiceContract {
  Future<ChargingSessionInfo?> fetchCurrentSession();

  Future<void> endReservation(String customerId);
}

class ChargingSessionService implements ChargingSessionServiceContract {
  ChargingSessionService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Future<ChargingSessionInfo?> fetchCurrentSession() async {
    final phoneNumber = _auth.currentUser?.phoneNumber;
    if (phoneNumber == null || phoneNumber.isEmpty) {
      return null;
    }

    final customerSnapshot = await _firestore
        .collection("Customers")
        .where("PhoneNumber", isEqualTo: phoneNumber)
        .limit(1)
        .get();

    if (customerSnapshot.docs.isEmpty) {
      return null;
    }

    final customerId =
        customerSnapshot.docs.first.data()["CustomerID"]?.toString() ?? "";
    if (customerId.isEmpty) {
      return null;
    }

    final reservationDoc = await _firestore
        .collection("Reservation")
        .doc(customerId)
        .get();
    if (!reservationDoc.exists) {
      return ChargingSessionInfo(
        customerId: customerId,
        stationId: "",
        chargerId: "",
        stationName: "",
        chargerName: "",
        chargerType: "",
      );
    }

    final reservation = reservationDoc.data() ?? {};
    final stationId = reservation["StationID"]?.toString() ?? "";
    final chargerId = reservation["ChargerID"]?.toString() ?? "";

    final results = await Future.wait([
      _firestore.collection("Station").doc(stationId).get(),
      _firestore
          .collection("Station")
          .doc(stationId)
          .collection("Charger")
          .doc(chargerId)
          .get(),
    ]);

    final stationData = results[0].data() ?? {};
    final chargerData = results[1].data() ?? {};

    return ChargingSessionInfo(
      customerId: customerId,
      stationId: stationId,
      chargerId: chargerId,
      stationName: stationData["StationName"]?.toString() ?? "",
      chargerName: chargerData["ChargerName"]?.toString() ?? "",
      chargerType: chargerData["ChargerType"]?.toString() ?? "",
    );
  }

  @override
  Future<void> endReservation(String customerId) async {
    if (customerId.isEmpty) {
      return;
    }

    await _firestore.collection("Reservation").doc(customerId).update({
      "Status": "Ended",
    });
  }
}
