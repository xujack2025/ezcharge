import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/charging_checkout_model.dart';
import 'auth_service.dart';

abstract class CheckInServiceContract {
  String? getCurrentUserPhoneNumber();

  Future<String?> getCustomerIdByPhoneNumber(String phoneNumber);

  Future<String> getReservationStatus(String customerId);

  Future<ChargingCheckInDetails?> fetchCheckInDetails();

  Future<void> checkIn(ChargingCheckInDetails details);
}

class CheckInService implements CheckInServiceContract {
  CheckInService({
    AuthServiceContract? authService,
    FirebaseFirestore? firestore,
  }) : _authService = authService ?? AuthService(),
       _firestore = firestore ?? FirebaseFirestore.instance;

  final AuthServiceContract _authService;
  final FirebaseFirestore _firestore;

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
  Future<String> getReservationStatus(String customerId) async {
    final doc = await _firestore
        .collection("Reservation")
        .doc(customerId)
        .get();
    if (!doc.exists) {
      return "Ended";
    }

    final data = doc.data();
    return data?["Status"]?.toString() ?? "Ended";
  }

  @override
  Future<ChargingCheckInDetails?> fetchCheckInDetails() async {
    final phoneNumber = getCurrentUserPhoneNumber();
    if (phoneNumber == null || phoneNumber.isEmpty) return null;

    final customerId = await getCustomerIdByPhoneNumber(phoneNumber);
    if (customerId == null || customerId.isEmpty) return null;

    final reservationDoc = await _firestore
        .collection("Reservation")
        .doc(customerId)
        .get();
    if (!reservationDoc.exists) return null;

    final reservation = reservationDoc.data() ?? {};
    final stationId = reservation["StationID"]?.toString() ?? "";
    final chargerId = reservation["ChargerID"]?.toString() ?? "";
    final reservationStatus = reservation["Status"]?.toString() ?? "";

    var stationName = "";
    var chargerName = "";
    var chargerType = "";
    var pricePerVoltage = 0.0;
    if (reservationStatus == "Upcoming") {
      final results = await Future.wait([
        _firestore.collection("Station").doc(stationId).get(),
        _firestore
            .collection("Station")
            .doc(stationId)
            .collection("Charger")
            .doc(chargerId)
            .get(),
      ]);
      final station = results[0].data() ?? {};
      final charger = results[1].data() ?? {};
      stationName = station["StationName"]?.toString() ?? "";
      chargerName = charger["ChargerName"]?.toString() ?? "";
      chargerType = charger["ChargerType"]?.toString() ?? "";
      pricePerVoltage = _parseDouble(charger["PricePerVoltage"]);
    }

    return ChargingCheckInDetails(
      customerId: customerId,
      chargerId: chargerId,
      stationId: stationId,
      reservationStatus: reservationStatus,
      stationName: stationName,
      chargerName: chargerName,
      chargerType: chargerType,
      pricePerVoltage: pricePerVoltage,
      startTime: _parseDateTime(reservation["StartTime"]),
    );
  }

  @override
  Future<void> checkIn(ChargingCheckInDetails details) async {
    await _firestore.collection("Reservation").doc(details.customerId).update({
      "Status": "Active",
    });

    await _firestore
        .collection("Station")
        .doc(details.stationId)
        .collection("Charger")
        .doc(details.chargerId)
        .update({"Status": "Occupied"});
  }

  static DateTime _parseDateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  static double _parseDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? "") ?? 0;
  }
}
