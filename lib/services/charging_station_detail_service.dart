import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/charging_reservation_charger_model.dart';
import '../models/charging_station_detail_model.dart';

abstract class ChargingStationDetailServiceContract {
  Future<ChargingStationDetailData?> fetchStationDetail(String stationId);

  Future<List<ChargingStationReview>> fetchReviews(String stationId);

  Stream<List<DateTime>> watchAttendanceCheckIns(String stationId);

  Future<ChargingStationAccess> fetchReservationAccess();
}

class ChargingStationDetailService
    implements ChargingStationDetailServiceContract {
  ChargingStationDetailService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Future<ChargingStationDetailData?> fetchStationDetail(
    String stationId,
  ) async {
    final stationDoc = await _firestore
        .collection("Station")
        .doc(stationId)
        .get();
    if (!stationDoc.exists) {
      return null;
    }

    final chargerSnapshot = await _firestore
        .collection("Station")
        .doc(stationId)
        .collection("Charger")
        .get();

    final chargers = chargerSnapshot.docs
        .map(ChargingReservationCharger.fromFirestore)
        .toList();
    final availableChargers = chargers
        .where((charger) => charger.isAvailable)
        .length;
    final storedStation = ChargingStationDetail.fromFirestore(stationDoc);
    final station = storedStation.copyWith(capacity: availableChargers);

    if (storedStation.capacity != availableChargers) {
      await _firestore.collection("Station").doc(stationId).update({
        "Capacity": availableChargers,
      });
    }

    return ChargingStationDetailData(station: station, chargers: chargers);
  }

  @override
  Future<List<ChargingStationReview>> fetchReviews(String stationId) async {
    final snapshot = await _firestore
        .collection("Reviews")
        .where("StationID", isEqualTo: stationId)
        .orderBy("ReviewDate", descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ChargingStationReview.fromMap(doc.data()))
        .toList();
  }

  @override
  Stream<List<DateTime>> watchAttendanceCheckIns(String stationId) {
    return _firestore
        .collection("Attendance")
        .where("StationID", isEqualTo: stationId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => doc.data()["CheckInTime"])
              .whereType<Timestamp>()
              .map((timestamp) => timestamp.toDate())
              .toList(),
        );
  }

  @override
  Future<ChargingStationAccess> fetchReservationAccess() async {
    final phoneNumber = _auth.currentUser?.phoneNumber;
    if (phoneNumber == null || phoneNumber.isEmpty) {
      return const ChargingStationAccess(
        customerId: "",
        authenticationStatus: "",
        reservationStatus: "",
      );
    }

    final customerSnapshot = await _firestore
        .collection("Customers")
        .where("PhoneNumber", isEqualTo: phoneNumber)
        .limit(1)
        .get();

    if (customerSnapshot.docs.isEmpty) {
      return const ChargingStationAccess(
        customerId: "",
        authenticationStatus: "",
        reservationStatus: "",
      );
    }

    final customerId =
        customerSnapshot.docs.first.data()["CustomerID"]?.toString() ?? "";
    if (customerId.isEmpty) {
      return const ChargingStationAccess(
        customerId: "",
        authenticationStatus: "",
        reservationStatus: "",
      );
    }

    final results = await Future.wait([
      _firestore
          .collection("Customers")
          .doc(customerId)
          .collection("Authenticate")
          .doc("authentication")
          .get(),
      _firestore.collection("Reservation").doc(customerId).get(),
    ]);

    return ChargingStationAccess(
      customerId: customerId,
      authenticationStatus: results[0].data()?["Status"]?.toString() ?? "",
      reservationStatus: results[1].data()?["Status"]?.toString() ?? "",
    );
  }
}
