import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/utils/app_logger.dart';
import '../../models/charging_checkout_model.dart';
import '../../services/check_in_service.dart';
import '../../services/image_picker_service.dart';

enum CheckInScanResult { upcoming, active, unavailable, empty }

enum CheckInSubmitResult { success, notReady, noReservation, failed }

class CheckInViewModel extends ChangeNotifier {
  CheckInViewModel({
    CheckInServiceContract? checkInService,
    ImagePickerServiceContract? imagePickerService,
  }) : _checkInService = checkInService ?? CheckInService(),
       _imagePickerService = imagePickerService ?? ImagePickerService();

  final CheckInServiceContract _checkInService;
  final ImagePickerServiceContract _imagePickerService;

  String _customerId = "";
  String _reservationStatus = "";
  ChargingCheckInDetails? _checkInDetails;
  File? _selectedImage;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  String get customerId => _customerId;
  String get reservationStatus => _reservationStatus;
  ChargingCheckInDetails? get checkInDetails => _checkInDetails;
  File? get selectedImage => _selectedImage;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
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

  Future<File?> pickImageFromGallery() async {
    final image = await _imagePickerService.pickImage(AppImageSource.gallery);
    if (image == null) return null;

    _selectedImage = image;
    notifyListeners();
    return image;
  }

  Future<void> loadCheckInDetails() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _checkInDetails = await _checkInService.fetchCheckInDetails();
      _customerId = _checkInDetails?.customerId ?? "";
      _reservationStatus = _checkInDetails?.reservationStatus ?? "Ended";
      if (_checkInDetails == null) {
        _errorMessage = "No upcoming reservation was found.";
      }
    } catch (e) {
      AppLogger.error("Error loading check-in details: $e");
      _checkInDetails = null;
      _reservationStatus = "Ended";
      _errorMessage = "Failed to load your reservation.";
    } finally {
      _setLoading(false);
    }
  }

  Future<CheckInSubmitResult> submitCheckIn() async {
    final details = _checkInDetails;
    if (details == null) {
      _errorMessage = "No upcoming reservation was found.";
      notifyListeners();
      return CheckInSubmitResult.noReservation;
    }

    if (!details.canCheckIn) {
      _errorMessage = "Now isn't your check-in time!";
      notifyListeners();
      return CheckInSubmitResult.notReady;
    }

    _setSubmitting(true);
    _errorMessage = null;

    try {
      await _checkInService.checkIn(details);
      _reservationStatus = "Active";
      return CheckInSubmitResult.success;
    } catch (e) {
      AppLogger.error("Error during check-in: $e");
      _errorMessage = "Check-in failed. Try again!";
      return CheckInSubmitResult.failed;
    } finally {
      _setSubmitting(false);
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

  void _setSubmitting(bool value) {
    _isSubmitting = value;
    notifyListeners();
  }
}
