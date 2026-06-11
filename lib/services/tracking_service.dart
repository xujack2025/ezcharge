import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../models/tracking_model.dart';
import '../secrets.dart';

abstract class TrackingServiceContract {
  Stream<DriverTrackingInfo?> watchDriver(String driverId);

  Stream<RequestTrackingInfo?> watchRequest(String requestId);

  Future<int?> fetchEtaMinutes({
    required LatLng driverLocation,
    required LatLng customerLocation,
  });

  Future<List<LatLng>> fetchRoutePoints({
    required LatLng driverLocation,
    required LatLng customerLocation,
  });
}

class TrackingService implements TrackingServiceContract {
  TrackingService({FirebaseFirestore? firestore, http.Client? httpClient})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _httpClient = httpClient ?? http.Client();

  final FirebaseFirestore _firestore;
  final http.Client _httpClient;

  @override
  Stream<DriverTrackingInfo?> watchDriver(String driverId) {
    return _firestore.collection('Drivers').doc(driverId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) return null;

      final data = snapshot.data() ?? {};
      final location = _parseLatLng(data['Location'] ?? data['location']);
      if (location == null) return null;

      return DriverTrackingInfo(
        location: location,
        name: data['FirstName']?.toString() ?? 'Unknown',
        phoneNumber: data['PhoneNumber']?.toString() ?? 'N/A',
      );
    });
  }

  @override
  Stream<RequestTrackingInfo?> watchRequest(String requestId) {
    return _firestore
        .collection('EmergencyRequests')
        .doc(requestId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return null;

          final data = snapshot.data() ?? {};
          return RequestTrackingInfo(
            status: data['Status']?.toString() ?? 'Unknown',
            customerLocation: _parseLatLng(
              data['Location'] ?? data['location'],
            ),
            chargingStartTime: _parseDateTime(data['chargingStartTime']),
            totalCost: _parseDouble(data['totalCost']),
            chargingFormattedTime:
                data['chargingFormattedTime']?.toString() ?? '00:00:00',
          );
        });
  }

  @override
  Future<int?> fetchEtaMinutes({
    required LatLng driverLocation,
    required LatLng customerLocation,
  }) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/distancematrix/json'
      '?units=metric'
      '&origins=${driverLocation.latitude},${driverLocation.longitude}'
      '&destinations=${customerLocation.latitude},${customerLocation.longitude}'
      '&key=${Secrets.googleMapsApiKey}',
    );

    final response = await _httpClient.get(url);
    if (response.statusCode != 200) return null;

    final data = json.decode(response.body) as Map<String, dynamic>;
    final rows = data['rows'];
    if (rows is! List || rows.isEmpty) return null;

    final elements = rows.first['elements'];
    if (elements is! List || elements.isEmpty) return null;

    final duration = elements.first['duration'];
    if (duration is! Map<String, dynamic>) return null;

    final seconds = duration['value'];
    if (seconds is! num) return null;
    return seconds ~/ 60;
  }

  @override
  Future<List<LatLng>> fetchRoutePoints({
    required LatLng driverLocation,
    required LatLng customerLocation,
  }) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=${driverLocation.latitude},${driverLocation.longitude}'
      '&destination=${customerLocation.latitude},${customerLocation.longitude}'
      '&key=${Secrets.googleMapsApiKey}',
    );

    final response = await _httpClient.get(url);
    if (response.statusCode != 200) return [];

    final data = json.decode(response.body) as Map<String, dynamic>;
    final routes = data['routes'];
    if (routes is! List || routes.isEmpty) return [];

    final overviewPolyline = routes.first['overview_polyline'];
    if (overviewPolyline is! Map<String, dynamic>) return [];

    final encodedPolyline = overviewPolyline['points'];
    if (encodedPolyline is! String || encodedPolyline.isEmpty) return [];

    return PolylinePoints.decodePolyline(
      encodedPolyline,
    ).map((point) => LatLng(point.latitude, point.longitude)).toList();
  }

  static LatLng? _parseLatLng(Object? value) {
    if (value is GeoPoint) {
      return LatLng(value.latitude, value.longitude);
    }
    return null;
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static double _parseDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
