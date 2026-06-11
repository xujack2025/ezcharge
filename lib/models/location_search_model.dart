import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationSuggestion {
  const LocationSuggestion({required this.placeId, required this.description});

  final String placeId;
  final String description;
}

class LocationSelection {
  const LocationSelection({required this.location, required this.address});

  final LatLng location;
  final String address;
}
