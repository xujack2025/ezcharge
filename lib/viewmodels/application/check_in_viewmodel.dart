import 'package:flutter/material.dart';

import '../../core/utils/app_logger.dart';
import '../../services/check_in_service.dart';

enum CheckInScanResult { upcoming, active, unavailable, empty }

class CheckInViewModel extends ChangeNotifier {
  CheckInViewModel({CheckInServiceContract? checkInService})
    : _checkInService = checkInService ?? CheckInService();

  final CheckInServiceContract _checkInService;

  String _customerId = "";
  String _reservationStatus = "";
  bool _isLoading = false;
  String? _errorMessage;

  String get customerId => _customerId;
  String get reservationStatus => _reservationStatus;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadReservationStatus() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final phoneNumber = _checkInService.getCurrentUserPhoneNumber();
      if (phoneNumber == null || phoneNumber.isEmpty) {
        _reservationStatus = "Ended";
        return;
      }

      final customerId = await _checkInService.getCustomerIdByPhoneNumber(
        phoneNumber,
      );
      if (customerId == null || customerId.isEmpty) {
        _reservationStatus = "Ended";
        return;
      }

      _customerId = customerId;
      _reservationStatus = await _checkInService.getReservationStatus(
        customerId,
      );
    } catch (e) {
      AppLogger.error("Error loading check-in reservation: $e");
      _errorMessage = "Failed to load your reservation.";
      _reservationStatus = "Ended";
    } finally {
      _setLoading(false);
    }
  }

  CheckInScanResult resolveScan(String scannedData) {
    if (scannedData.isEmpty) {
      return CheckInScanResult.empty;
    }

    if (_reservationStatus == "Upcoming") {
      return CheckInScanResult.upcoming;
    }

    if (_reservationStatus == "Active") {
      return CheckInScanResult.active;
    }

    return CheckInScanResult.unavailable;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
