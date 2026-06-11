import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/utils/app_logger.dart';
import '../../models/charging_reservation_charger_model.dart';
import '../../models/charging_station_detail_model.dart';
import '../../services/charging_station_detail_service.dart';

enum ChargingStationReserveIntent {
  allowed,
  authenticationRequired,
  existingReservation,
}

class ChargingStationDetailViewModel extends ChangeNotifier {
  ChargingStationDetailViewModel({
    ChargingStationDetailServiceContract? stationDetailService,
  }) : _stationDetailService =
           stationDetailService ?? ChargingStationDetailService();

  final ChargingStationDetailServiceContract _stationDetailService;

  ChargingStationDetail? _station;
  List<ChargingReservationCharger> _chargers = [];
  List<ChargingStationReview> _reviews = [];
  ChargingStationAccess _access = const ChargingStationAccess(
    customerId: "",
    authenticationStatus: "",
    reservationStatus: "",
  );
  List<double> _busyTimes = List.filled(24, 0.0);
  String _trafficStatus = "Same as usual";
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<DateTime>>? _attendanceSubscription;

  ChargingStationDetail? get station => _station;
  List<ChargingReservationCharger> get chargers => List.unmodifiable(_chargers);
  List<ChargingStationReview> get reviews => List.unmodifiable(_reviews);
  List<double> get busyTimes => List.unmodifiable(_busyTimes);
  String get trafficStatus => _trafficStatus;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get canReserve => _access.canReserve;
  int get currentHour => DateTime.now().hour;

  Future<void> load(String stationId) async {
    _setLoading(true);
    _errorMessage = null;

    await _attendanceSubscription?.cancel();
    _attendanceSubscription = _stationDetailService
        .watchAttendanceCheckIns(stationId)
        .listen(
          _updateBusyTimes,
          onError: (Object error) {
            AppLogger.error("Error watching station attendance: $error");
            _trafficStatus = "No data available";
            notifyListeners();
          },
        );

    try {
      final results = await Future.wait<Object?>([
        _stationDetailService.fetchStationDetail(stationId),
        _stationDetailService.fetchReviews(stationId),
        _stationDetailService.fetchReservationAccess(),
      ]);

      final detail = results[0] as ChargingStationDetailData?;
      _station = detail?.station;
      _chargers = detail?.chargers ?? [];
      _reviews = results[1] as List<ChargingStationReview>;
      _access = results[2] as ChargingStationAccess;

      if (detail == null) {
        _errorMessage = "Station not found.";
      }
    } catch (e) {
      AppLogger.error("Error loading station details: $e");
      _station = null;
      _chargers = [];
      _reviews = [];
      _errorMessage = "Failed to load station details.";
    } finally {
      _setLoading(false);
    }
  }

  ChargingStationReserveIntent getReserveIntent() {
    if (_access.authenticationStatus != "Pass") {
      return ChargingStationReserveIntent.authenticationRequired;
    }

    if (_access.hasBlockingReservation) {
      return ChargingStationReserveIntent.existingReservation;
    }

    return ChargingStationReserveIntent.allowed;
  }

  void _updateBusyTimes(List<DateTime> checkIns) {
    if (checkIns.isEmpty) {
      _busyTimes = List.filled(24, 0.2);
      _trafficStatus = "No data available";
      notifyListeners();
      return;
    }

    final hourlyUsage = List<double>.filled(24, 0.0);
    for (final checkInTime in checkIns) {
      hourlyUsage[checkInTime.hour] += 1;
    }

    final maxUsage = hourlyUsage.reduce((a, b) => a > b ? a : b);
    final totalUsage = hourlyUsage.reduce((a, b) => a + b);
    final avgUsage = totalUsage > 0 ? totalUsage / 24 : 0;

    _busyTimes = maxUsage > 0
        ? hourlyUsage.map((value) => (value / maxUsage) * 10).toList()
        : List.filled(24, 0.2);
    _trafficStatus = totalUsage == 0
        ? "No data available"
        : (hourlyUsage[currentHour] >= avgUsage * 1.2
              ? "Busy time"
              : (hourlyUsage[currentHour] <= avgUsage * 0.8
                    ? "Less people"
                    : "Same as usual"));
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _attendanceSubscription?.cancel();
    super.dispose();
  }
}
