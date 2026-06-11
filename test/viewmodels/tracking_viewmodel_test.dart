import 'package:ezcharge/models/tracking_model.dart';
import 'package:ezcharge/services/tracking_service.dart';
import 'package:ezcharge/viewmodels/tracking_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class _FakeTrackingService implements TrackingServiceContract {
  int? etaMinutes = 12;
  List<LatLng> routePoints = const [LatLng(1, 2), LatLng(3, 4)];
  Object? etaError;
  Object? routeError;

  @override
  Stream<DriverTrackingInfo?> watchDriver(String driverId) {
    return const Stream.empty();
  }

  @override
  Stream<RequestTrackingInfo?> watchRequest(String requestId) {
    return const Stream.empty();
  }

  @override
  Future<int?> fetchEtaMinutes({
    required LatLng driverLocation,
    required LatLng customerLocation,
  }) async {
    final error = etaError;
    if (error != null) throw error;
    return etaMinutes;
  }

  @override
  Future<List<LatLng>> fetchRoutePoints({
    required LatLng driverLocation,
    required LatLng customerLocation,
  }) async {
    final error = routeError;
    if (error != null) throw error;
    return routePoints;
  }
}

void main() {
  test('calculateEta delegates to tracking service', () async {
    final service = _FakeTrackingService();
    final viewModel = TrackingViewModel(trackingService: service);

    final eta = await viewModel.calculateEta(
      driverLocation: const LatLng(1, 2),
      customerLocation: const LatLng(3, 4),
    );

    expect(eta, 12);
  });

  test('loadRoutePoints delegates to tracking service', () async {
    final service = _FakeTrackingService();
    final viewModel = TrackingViewModel(trackingService: service);

    final points = await viewModel.loadRoutePoints(
      driverLocation: const LatLng(1, 2),
      customerLocation: const LatLng(3, 4),
    );

    expect(points, const [LatLng(1, 2), LatLng(3, 4)]);
  });

  test('returns empty route when service throws', () async {
    final service = _FakeTrackingService()..routeError = Exception('route');
    final viewModel = TrackingViewModel(trackingService: service);

    final points = await viewModel.loadRoutePoints(
      driverLocation: const LatLng(1, 2),
      customerLocation: const LatLng(3, 4),
    );

    expect(points, isEmpty);
  });
}
