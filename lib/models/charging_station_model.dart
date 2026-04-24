import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ezcharge/models/charging_bay_model.dart';

enum CapacityStatus { optimal, highdemand, overloaded, undefined }

class ChargingStation {
  final String stationID;
  final String stationName;
  final String description;
  final String nearby;
  final String location;
  final String latitude;
  final String longitude;
  final String imageUrl;
  final int capacity;
  final int occupiedBays;
  final List<ChargingBay> chargingBays;

  ChargingStation({
    required this.stationID,
    required this.stationName,
    required this.description,
    required this.nearby,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.capacity,
    required this.imageUrl,
    required this.chargingBays,
    this.occupiedBays = 0,
  });

  CapacityStatus get capacityStatus {
    if (capacity == 0) return CapacityStatus.undefined;
    double ratio = occupiedBays / capacity;
    if (ratio >= 1.0) return CapacityStatus.overloaded;
    if (ratio >= 0.8) return CapacityStatus.highdemand;
    return CapacityStatus.optimal;
  }

  factory ChargingStation.fromFirestore(DocumentSnapshot doc) {
    final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    final List<dynamic> chargerData = data['charger'] ?? [];
    final List<ChargingBay> parsedBays = chargerData.map((bayMap) {
      return ChargingBay.fromFirestore(bayMap);
    }).toList();

    return ChargingStation(
      stationID: data['StationID'] ?? '',
      stationName: data['StationName'] ?? '',
      description: data['Description'] ?? '',
      nearby: data['Nearby'] ?? '',
      location: data['Location'] ?? '',
      latitude: data['Latitude'] ?? '',
      longitude: data['Longitude'] ?? '',
      capacity: data['Capacity'] ?? 0,
      imageUrl: data['ImageUrl'] ?? '',
      chargingBays: parsedBays,
      occupiedBays: data['OccupiedBays'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'StationName': stationName,
      'Description': description,
      'Nearby': nearby,
      'Location': location,
      'Latitude': latitude,
      'Longitude': longitude,
      'Capacity': capacity,
      'ImageUrl': imageUrl,
      'OccupiedBays': occupiedBays,
      'charger': chargingBays.map((bay) => bay.toMap()).toList(),
    };
  }
}
