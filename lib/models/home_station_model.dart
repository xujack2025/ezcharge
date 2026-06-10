import 'package:cloud_firestore/cloud_firestore.dart';

class HomeStation {
  const HomeStation({
    required this.stationId,
    required this.stationName,
    required this.description,
    required this.capacity,
    required this.nearby,
    required this.imageUrl,
    required this.currentTypes,
    this.latitude,
    this.longitude,
  });

  final String stationId;
  final String stationName;
  final String description;
  final int capacity;
  final Object? nearby;
  final String imageUrl;
  final List<String> currentTypes;
  final double? latitude;
  final double? longitude;

  String get nearbyLabel {
    final value = nearby;
    if (value is List) {
      return value.map((item) => item.toString()).join(", ");
    }
    return value?.toString() ?? "";
  }

  bool matchesSearch(String query) {
    if (query.isEmpty) return true;
    return stationName.toLowerCase().contains(query.toLowerCase());
  }

  bool matchesPower(String power) {
    if (power.isEmpty) return true;
    return currentTypes.contains(power);
  }

  bool matchesNearby(List<String> filters) {
    if (filters.isEmpty) return true;

    final value = nearby;
    if (value is String) {
      return filters.any(
        (filter) => value.toLowerCase().contains(filter.toLowerCase()),
      );
    }

    if (value is List) {
      return filters.any((filter) => value.contains(filter));
    }

    return false;
  }

  factory HomeStation.fromFirestore(
    DocumentSnapshot stationDoc, {
    required List<String> currentTypes,
  }) {
    final data = stationDoc.data() as Map<String, dynamic>;
    final coordinates = _parseCoordinates(data);

    return HomeStation(
      stationId: data["StationID"]?.toString() ?? stationDoc.id,
      stationName: data["StationName"]?.toString() ?? "",
      description: data["Description"]?.toString() ?? "",
      capacity: (data["Capacity"] as num?)?.toInt() ?? 0,
      nearby: data["Nearby"],
      imageUrl:
          data["ImageUrl"]?.toString() ?? "https://via.placeholder.com/80",
      currentTypes: currentTypes,
      latitude: coordinates.$1,
      longitude: coordinates.$2,
    );
  }

  static (double?, double?) _parseCoordinates(Map<String, dynamic> data) {
    final rawLocation = data["Location"];
    if (rawLocation is GeoPoint) {
      return (rawLocation.latitude, rawLocation.longitude);
    }

    final latitude = double.tryParse(data["Latitude"]?.toString() ?? "");
    final longitude = double.tryParse(data["Longitude"]?.toString() ?? "");
    return (latitude, longitude);
  }
}
