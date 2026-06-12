import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/utils/app_logger.dart';
import '../../models/profile_account_model.dart';
import '../../services/profile_account_service.dart';

enum ProfileCancelReservationResult { success, customerNotFound, failed }

class ProfileActivityViewModel extends ChangeNotifier {
  ProfileActivityViewModel({ProfileAccountServiceContract? accountService})
    : _accountService = accountService ?? ProfileAccountService();

  final ProfileAccountServiceContract _accountService;

  Timer? _uiTimer;
  ProfileActivityData? _activity;
  bool _isLoading = false;
  String? _errorMessage;

  ProfileActivityData? get activity => _activity;
  ProfileReservationActivity? get reservation => _activity?.reservation;
  List<ProfileEndedAttendance> get endedAttendances =>
      _activity?.endedAttendances ?? const [];
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasUpcomingReservation => reservation?.status == 'Upcoming';
  bool get hasActiveReservation => reservation?.status == 'Active';

  Future<void> loadActivity() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _activity = await _accountService.fetchActivity();
      if (_activity == null) {
        _errorMessage = 'Customer profile was not found.';
      }
      _startUiTimer();
    } catch (e) {
      AppLogger.error('Error loading profile activity view state: $e');
      _activity = null;
      _errorMessage = 'Unable to load charging activity. Please try again.';
    } finally {
      _setLoading(false);
    }
  }

  Future<ProfileCancelReservationResult> cancelReservation() async {
    try {
      await _accountService.cancelReservation();
      await loadActivity();
      return ProfileCancelReservationResult.success;
    } on ProfileAccountCustomerNotFoundException {
      _errorMessage = 'Customer profile was not found.';
      notifyListeners();
      return ProfileCancelReservationResult.customerNotFound;
    } catch (e) {
      AppLogger.error('Error cancelling profile reservation: $e');
      _errorMessage = 'Unable to cancel reservation. Please try again.';
      notifyListeners();
      return ProfileCancelReservationResult.failed;
    }
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    super.dispose();
  }

  void _startUiTimer() {
    _uiTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
    });
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
