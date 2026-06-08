import 'package:flutter/material.dart';

import '../../core/utils/app_logger.dart';
import '../../models/admin_model.dart';
import '../../models/customer_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/station_service.dart';
import '../../views/auth/otp_screen.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;
  final StationService _stationService;

  AuthViewModel({AuthService? authService, StationService? stationService})
    : _stationService = stationService ?? StationService(),
      _authService = authService ?? AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  AdminModel? _admin;
  CustomerModel? _customer;
  String _authStatus = "";
  String _reservationStatus = "";
  String _fullPhoneNumber = "";

  String get fullPhoneNumber => _fullPhoneNumber;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AdminModel? get admin => _admin;
  CustomerModel? get customer => _customer;
  String get customerId => _customer?.id ?? "";
  bool get isAuthenticated => _authStatus == "Pass";
  bool get hasActiveReservation =>
      _reservationStatus == "Upcoming" || _reservationStatus == "Active";

  set fullPhoneNumber(String value) {
    _fullPhoneNumber = value;
    notifyListeners();
  }

  void _updateStatus(bool loading, String? error) {
    _isLoading = loading;
    _errorMessage = error;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<void> syncUserStatus() async {
    if (_customer == null) {
      AppLogger.error("Sync failed: No customer data found in memory.");
      return;
    }

    _updateStatus(true, null);

    try {
      final String currentId = _customer!.id;

      final results = await Future.wait([
        _authService.getAuthStatus(currentId),
        _stationService.getReservationStatus(currentId),
      ]);

      _authStatus = results[0];
      _reservationStatus = results[1];

      AppLogger.info("Status synced for user: $currentId");
      _updateStatus(false, null);
    } catch (e) {
      AppLogger.error("Sync error: $e");
      _updateStatus(false, "Failed to sync status: $e");
    }
  }

  Future<void> submitPhoneNumber(
    BuildContext context,
    String fullPhoneNumber,
    UserRole role,
  ) async {
    if (fullPhoneNumber.isEmpty) return;

    _updateStatus(true, null);

    await requestOtp(
      fullPhoneNumber,
      role,
      onCodeSent: (verificationId) {
        _updateStatus(false, null);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPScreen(
              phoneNumber: fullPhoneNumber,
              verificationID: verificationId,
              role: role,
            ),
          ),
        );
      },
    );
  }

  Future<void> requestOtp(
    String phoneNumber,
    UserRole role, {
    required void Function(String verificationId) onCodeSent,
  }) async {
    _updateStatus(true, null);

    try {
      await _authService.sendOtp(
        phoneNumber,
        role,
        onCodeSent: (verificationId) {
          onCodeSent(verificationId);
          _updateStatus(false, null);
        },
        onVerificationCompleted: () {
          _updateStatus(false, null);
        },
        onError: (message) {
          _updateStatus(false, message);
        },
      );
    } catch (e) {
      _updateStatus(false, "Error checking phone number: $e");
    }
  }

  Future<bool> verifyOtp(
    String verificationId,
    String smsCode,
    String phoneNumber,
    UserRole role,
  ) async {
    _updateStatus(true, null);

    try {
      final userCredential = await _authService.signInWithOtp(
        verificationId,
        smsCode,
      );

      if (userCredential.user != null) {
        final user = await _authService.getUserByPhoneNumber(phoneNumber, role);

        if (user is AdminModel) {
          _admin = user;
          _customer = null;
        } else if (user is CustomerModel) {
          _customer = user;
          _admin = null;
        }

        if (_admin != null || _customer != null) {
          _updateStatus(false, null);
          return true;
        }
      }

      _updateStatus(false, "User record not found.");
      return false;
    } catch (e) {
      _updateStatus(false, "Invalid OTP.");
      return false;
    }
  }

  Future<void> fetchCurrentUser(String phoneNumber, UserRole role) async {
    _updateStatus(true, null);

    try {
      final user = await _authService.getUserByPhoneNumber(phoneNumber, role);

      if (user is AdminModel) {
        _admin = user;
        _customer = null;
      } else if (user is CustomerModel) {
        _customer = user;
        _admin = null;
      } else {
        AppLogger.info("No user found with phone: $phoneNumber");
        _admin = null;
        _customer = null;
      }
      _updateStatus(false, null);
    } catch (e) {
      AppLogger.error("Failed to fetch user: $e");
      _updateStatus(false, 'Failed to fetch user: $e');
    }
  }

  void clearError() {
    _updateStatus(false, null);
  }
}
