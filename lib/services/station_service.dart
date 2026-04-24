import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:ezcharge/core/utils/app_logger.dart';
import 'package:ezcharge/models/charging_bay_model.dart';
import 'package:ezcharge/models/charging_station_model.dart';

class StationService {
  final _db = FirebaseFirestore.instance;

  Stream<List<ChargingStation>> getChargingStations() {
    return _db.collection('station').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              return ChargingStation.fromFirestore(doc);
            } catch (e) {
              AppLogger.error('Error parsing station ${doc.id}: $e');
              return null;
            }
          })
          .whereType<ChargingStation>()
          .toList();
    });
  }

  Stream<List<ChargingBay>> getChargingBays(String stationID) {
    return _db
        .collection('station')
        .doc(stationID)
        .collection('charger')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                try {
                  return ChargingBay.fromFirestore(doc);
                } catch (e) {
                  AppLogger.error(
                    'Error parsing charging bay ${doc.id} in station $stationID: $e',
                  );
                  return null;
                }
              })
              .whereType<ChargingBay>()
              .toList();
        });
  }

  Future<String> getReservationStatus(String customerId) async {
    final doc = await _db.collection("reservation").doc(customerId).get();
    return doc.exists ? (doc["Status"] ?? "") : "";
  }
}
