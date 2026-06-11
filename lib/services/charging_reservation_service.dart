import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/charging_reservation_charger_model.dart';
import 'auth_service.dart';

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
  ChargingReservationService({
    AuthServiceContract? authService,
    FirebaseFirestore? firestore,
  }) : _authService = authService ?? AuthService(),
       _firestore = firestore ?? FirebaseFirestore.instance;

  final AuthServiceContract _authService;
  final FirebaseFirestore _firestore;

  @override
  Future<String?> getCurrentCustomerId() async {
    return _authService.getCurrentCustomerId();
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
