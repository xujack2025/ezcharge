import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/utils/app_logger.dart';
import '../models/tracking_model.dart';
import '../services/tracking_service.dart';

class TrackingViewModel extends ChangeNotifier {
  TrackingViewModel({TrackingServiceContract? trackingService})
    : _trackingService = trackingService ?? TrackingService();

  final TrackingServiceContract _trackingService;

  Stream<DriverTrackingInfo?> watchDriver(String driverId) {
    return _trackingService.watchDriver(driverId);
  }

  Stream<RequestTrackingInfo?> watchRequest(String requestId) {
    return _trackingService.watchRequest(requestId);
  }

  Future<int?> calculateEta({
    required LatLng driverLocation,
    required LatLng customerLocation,
  }) async {
    try {
      return await _trackingService.fetchEtaMinutes(
        driverLocation: driverLocation,
        customerLocation: customerLocation,
      );
    } catch (e) {
      AppLogger.error('Error fetching tracking ETA: $e');
      return null;
    }
  }

  Future<List<LatLng>> loadRoutePoints({
    required LatLng driverLocation,
    required LatLng customerLocation,
  }) async {
    try {
      return await _trackingService.fetchRoutePoints(
        driverLocation: driverLocation,
        customerLocation: customerLocation,
      );
    } catch (e) {
      AppLogger.error('Error fetching tracking route: $e');
      return [];
    }
  }
}
