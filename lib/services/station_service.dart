import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/app_logger.dart';
import '../models/charging_bay_model.dart';
import '../models/charging_station_model.dart';

abstract class StationReservationServiceContract {
  Future<String> getReservationStatus(String customerId);
}

class StationService implements StationReservationServiceContract {
  final _db = FirebaseFirestore.instance;

  /// CRUD Operations for Charging Stations and Bays
  /// Retreive all stations with real-time updates
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

  /// Add new station to Firestore
  Future<void> addChargingStation(ChargingStation station) async {
    try {
      await _db.collection('station').add(station.toMap());
      AppLogger.info('Charging station added successfully: ${station.toMap()}');
    } catch (e) {
      AppLogger.error('Error adding charging station: $e');
    }
  }

  /// Update existing station in Firestore
  Future<void> updateChargingStation(ChargingStation station) async {
    try {
      await _db
          .collection('station')
          .doc(station.stationID)
          .update(station.toMap());
      AppLogger.info(
        'Charging station update successfully: ${station.toMap()}',
      );
    } catch (e) {
      AppLogger.error('Error update charging station: $e');
    }
  }

  /// Delete station from Firestore
  Future<void> deleteChargingStation(ChargingStation station) async {
    try {
      await _db.collection('station').doc(station.stationID).delete();
      AppLogger.info(
        'Charging station deleted successfully: ${station.toMap()}',
      );
    } catch (e) {
      AppLogger.error('Error delete charging station: $e');
    }
  }

  /// Soft delete station by setting isDeleted flag and status
  Future<void> softDeleteChargingStation(String stationID) async {
    try {
      await _db.collection('station').doc(stationID).update({
        'isDeleted': true,
        'status': StationStatus.deleted.name,
        'deletedAt': FieldValue.serverTimestamp(),
      });
      AppLogger.info('Station soft-deleted successfully: $stationID');
    } catch (e) {
      AppLogger.error('Error deleting charging station: $e');
    }
  }

  /// CRUD Operations for Charging Bays
  /// Retrieve bays for a station with real-time updates
  Stream<List<ChargingBay>> getChargingBays(String stationID) {
    return _db
        .collection('station')
        .doc(stationID)
        .collection('Charger')
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

  /// Add new charging bay to a station
  Future<void> addChargingBay(String stationID, ChargingBay bay) async {
    try {
      await _db
          .collection('station')
          .doc(stationID)
          .collection('Charger')
          .doc(bay.chargerID)
          .set({
            ...bay.toMap(),
            "Status": bay.status.name,
          }, SetOptions(merge: true));
      AppLogger.info(
        'Charging bay added successfully to station $stationID: ${bay.toMap}',
      );
    } catch (e) {
      AppLogger.error('Error adding charging bay to station $stationID: $e');
    }
  }

  /// Update existing charging bay in a station
  Future<void> updateChargingBay(String stationID, ChargingBay bay) async {
    try {
      await _db
          .collection('station')
          .doc(stationID)
          .collection('Charger')
          .doc(bay.chargerID)
          .update(bay.toMap());
      AppLogger.info(
        'Charging bay updated successfully in station $stationID: ${bay.toMap()}',
      );
    } catch (e) {
      AppLogger.error('Error updating charging bay in station $stationID: $e');
    }
  }

  /// Delete charging bay from a station
  Future<void> deleteChargingBay(String stationID, String chargerID) async {
    try {
      await _db
          .collection('station')
          .doc(stationID)
          .collection('Charger')
          .doc(chargerID)
          .delete();
      AppLogger.info(
        'Charging bay deleted successfully from station $stationID: $chargerID',
      );
    } catch (e) {
      AppLogger.error(
        'Error deleting charging bay from station $stationID: $e',
      );
    }
  }

  /// Soft delete charging bay by setting isDeleted flag and status
  Future<void> softDeleteChargingBay(String stationID, String chargerID) async {
    try {
      await _db
          .collection('station')
          .doc(stationID)
          .collection('Charger')
          .doc(chargerID)
          .update({
            'isDeleted': true,
            'status': BayStatus.outofservice.name,
            'deletedAt': FieldValue.serverTimestamp(),
          });
      AppLogger.info(
        'Charging bay soft-deleted successfully from station $stationID: $chargerID',
      );
    } catch (e) {
      AppLogger.error(
        'Error deleting charging bay from station $stationID: $e',
      );
    }
  }

  /// Check reservation status for customers
  @override
  Future<String> getReservationStatus(String customerId) async {
    final doc = await _db.collection("reservation").doc(customerId).get();
    return doc.exists ? (doc["Status"] ?? "") : "";
  }
}
