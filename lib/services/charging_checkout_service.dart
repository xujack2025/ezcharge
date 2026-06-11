import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/charging_checkout_model.dart';
import 'auth_service.dart';

abstract class ChargingCheckoutServiceContract {
  Future<ChargingCheckoutDetails?> fetchCheckoutDetails();

  Future<void> createAttendanceRecord({
    required ChargingCheckoutDetails details,
    required String duration,
    required double chargingCost,
    required double penaltyCost,
    DateTime? checkedOutAt,
  });
}

class ChargingCheckoutService implements ChargingCheckoutServiceContract {
  ChargingCheckoutService({
    AuthServiceContract? authService,
    FirebaseFirestore? firestore,
  }) : _authService = authService ?? AuthService(),
       _firestore = firestore ?? FirebaseFirestore.instance;

  final AuthServiceContract _authService;
  final FirebaseFirestore _firestore;

  @override
  Future<ChargingCheckoutDetails?> fetchCheckoutDetails() async {
    final customerId = await _authService.getCurrentCustomerId();
    if (customerId == null || customerId.isEmpty) return null;

    final reservationDoc = await _firestore
        .collection('Reservation')
        .doc(customerId)
        .get();
    if (!reservationDoc.exists) return null;

    final reservation = reservationDoc.data() ?? {};
    final stationId = reservation['StationID']?.toString() ?? '';
    final chargerId = reservation['ChargerID']?.toString() ?? '';

    final stationDoc = await _firestore
        .collection('Station')
        .doc(stationId)
        .get();
    final chargerDoc = await _firestore
        .collection('Station')
        .doc(stationId)
        .collection('Charger')
        .doc(chargerId)
        .get();

    final station = stationDoc.data() ?? {};
    final charger = chargerDoc.data() ?? {};

    return ChargingCheckoutDetails(
      customerId: customerId,
      chargerId: chargerId,
      stationId: stationId,
      reservationId: reservation['ReservationID']?.toString() ?? '',
      reservationStatus: reservation['Status']?.toString() ?? '',
      stationName: station['StationName']?.toString() ?? '',
      chargerName: charger['ChargerName']?.toString() ?? '',
      chargerType: charger['ChargerType']?.toString() ?? '',
      currentType: charger['CurrentType']?.toString() ?? '',
      chargerVoltage: _parseDouble(charger['ChargerVoltage']),
      pricePerVoltage: _parseDouble(charger['PricePerVoltage']),
      startTime: _parseDateTime(reservation['StartTime']),
    );
  }

  @override
  Future<void> createAttendanceRecord({
    required ChargingCheckoutDetails details,
    required String duration,
    required double chargingCost,
    required double penaltyCost,
    DateTime? checkedOutAt,
  }) async {
    final sessionId = 'SSN${DateTime.now().millisecondsSinceEpoch}';
    final checkOutTime = checkedOutAt ?? DateTime.now();
    final energyUsed = details.chargerVoltage * _durationHours(duration);
    final totalCost = chargingCost + penaltyCost;

    await _firestore.collection('Attendance').doc(sessionId).set({
      'CheckInTime': Timestamp.fromDate(details.startTime),
      'CheckOutTime': Timestamp.fromDate(checkOutTime),
      'ChargerType': details.chargerType,
      'ChargerVoltage': _formatLegacyNumber(details.chargerVoltage),
      'CurrentType': details.currentType,
      'Duration': duration,
      'CustomerID': details.customerId,
      'EnergyUsed': double.parse(energyUsed.toStringAsFixed(2)),
      'ReservationID': details.reservationId,
      'SessionID': sessionId,
      'SlotID': details.chargerId,
      'StationID': details.stationId,
      'TotalCost': double.parse(totalCost.toStringAsFixed(2)),
    });

    await _firestore
        .collection('Station')
        .doc(details.stationId)
        .collection('Charger')
        .doc(details.chargerId)
        .update({'Status': 'Available'});
  }

  static DateTime _parseDateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  static double _parseDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _formatLegacyNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  static double _durationHours(String duration) {
    final parts = duration.split(':');
    if (parts.length != 3) return 0;

    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    final seconds = int.tryParse(parts[2]) ?? 0;
    return Duration(
          hours: hours,
          minutes: minutes,
          seconds: seconds,
        ).inSeconds /
        3600;
  }
}
