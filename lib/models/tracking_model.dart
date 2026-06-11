import 'package:google_maps_flutter/google_maps_flutter.dart';

class DriverTrackingInfo {
  const DriverTrackingInfo({
    required this.location,
    required this.name,
    required this.phoneNumber,
  });

  final LatLng location;
  final String name;
  final String phoneNumber;
}

class RequestTrackingInfo {
  const RequestTrackingInfo({
    required this.status,
    required this.customerLocation,
    required this.chargingStartTime,
    required this.totalCost,
    required this.chargingFormattedTime,
  });

  final String status;
  final LatLng? customerLocation;
  final DateTime? chargingStartTime;
  final double totalCost;
  final String chargingFormattedTime;
}
