import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/charging_session_model.dart';
import 'auth_service.dart';

abstract class ChargingSessionServiceContract {
  Future<ChargingSessionInfo?> fetchCurrentSession();

  Future<void> endReservation(String customerId);
}

class ChargingSessionService implements ChargingSessionServiceContract {
  ChargingSessionService({
    AuthServiceContract? authService,
    FirebaseFirestore? firestore,
  }) : _authService = authService ?? AuthService(),
       _firestore = firestore ?? FirebaseFirestore.instance;

  final AuthServiceContract _authService;
  final FirebaseFirestore _firestore;

  @override
  Future<ChargingSessionInfo?> fetchCurrentSession() async {
    final customerId = await _authService.getCurrentCustomerId();
    if (customerId == null || customerId.isEmpty) {
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
