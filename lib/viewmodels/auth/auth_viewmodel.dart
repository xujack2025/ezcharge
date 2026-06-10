import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/utils/app_logger.dart';
import '../../models/admin_model.dart';
import '../../models/customer_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/startup_service.dart';
import '../../services/station_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthServiceContract _authService;
  final StationReservationServiceContract? _stationService;
  final StartupServiceContract _startupService;

  AuthViewModel({
    AuthServiceContract? authService,
    StationReservationServiceContract? stationService,
    StartupServiceContract? startupService,
  }) : _stationService = stationService,
       _authService = authService ?? AuthService(),
       _startupService = startupService ?? StartupService();

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
    _updateStatus(true, null);

    try {
      final customer = await _ensureCurrentCustomer();
      if (customer == null) {
        AppLogger.error("Sync failed: No customer data found.");
        _authStatus = "";
        _reservationStatus = "";
        _updateStatus(false, "Customer profile not found.");
        return;
      }

      final String currentId = customer.id;

      final results = await Future.wait([
        _authService.getAuthStatus(currentId),
        (_stationService ?? StationService()).getReservationStatus(currentId),
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

  Future<CustomerModel?> _ensureCurrentCustomer() async {
    if (_customer != null) return _customer;

    final phoneNumber = _authService.getCurrentUserPhoneNumber();
    if (phoneNumber == null || phoneNumber.isEmpty) {
      AppLogger.error("Sync failed: No authenticated phone number found.");
      return null;
    }

    final customer = await _authService.getCustomerByPhoneNumber(phoneNumber);
    _customer = customer;
    _admin = null;
    return customer;
  }

  Future<String?> submitPhoneNumber(
    String fullPhoneNumber,
    UserRole role,
  ) async {
    if (fullPhoneNumber.isEmpty) return null;

    return requestOtp(fullPhoneNumber, role);
  }

  Future<String?> requestOtp(String phoneNumber, UserRole role) async {
    _updateStatus(true, null);
    final completer = Completer<String?>();

    void completeRequest(String? verificationId) {
      if (!completer.isCompleted) {
        completer.complete(verificationId);
      }
    }

    try {
      await _authService.sendOtp(
        phoneNumber,
        role,
        onCodeSent: (verificationId) {
          _updateStatus(false, null);
          completeRequest(verificationId);
        },
        onVerificationCompleted: () {
          _updateStatus(false, null);
          completeRequest(null);
        },
        onError: (message) {
          _updateStatus(false, message);
          completeRequest(null);
        },
      );
    } catch (e) {
      _updateStatus(false, "Error checking phone number: $e");
      completeRequest(null);
    }

    return completer.future.timeout(
      const Duration(seconds: 31),
      onTimeout: () {
        _updateStatus(false, "OTP request timed out.");
        return null;
      },
    );
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
          await _startupService.setLoggedIn(true, role: role);
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

  Future<void> signOut() async {
    _updateStatus(true, null);

    try {
      await _authService.signout();
      await _startupService.setLoggedIn(false);
      _admin = null;
      _customer = null;
      _authStatus = "";
      _reservationStatus = "";
      _fullPhoneNumber = "";
      _updateStatus(false, null);
    } catch (e) {
      AppLogger.error("Failed to sign out: $e");
      _updateStatus(false, "Failed to sign out.");
    }
  }
}
