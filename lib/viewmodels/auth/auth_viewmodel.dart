import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ezcharge/core/utils/app_logger.dart';
import 'package:ezcharge/services/station_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:ezcharge/models/admin_model.dart';
import 'package:ezcharge/models/customer_model.dart';
import 'package:ezcharge/models/user_model.dart';
import 'package:ezcharge/services/auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
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

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AdminModel? get admin => _admin;
  CustomerModel? get customer => _customer;
  bool get isAuthenticated => _authStatus == "Pass";
  bool get hasActiveReservation =>
      _reservationStatus == "Upcoming" || _reservationStatus == "Active";

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<void> syncUserStatus(String phoneNumber) async {
    _setLoading(true);
    _setError(null);

    _customer = await _authService.getCustomerByPhoneNumber(phoneNumber);

    if (_customer != null) {
      _authStatus = await _authService.getAuthStatus(_customer!.id);
      _reservationStatus = await _stationService.getReservationStatus(
        _customer!.id,
      );
    }

    _setLoading(false);
  }

  Future<bool> verifyOtp(
    String verificationId,
    String smsCode,
    String phoneNumber,
    UserRole role,
  ) async {
    _setLoading(true);
    _setError(null);

    try {
      final userCredential = await _authService.signInWithOtp(
        verificationId,
        smsCode,
      );

      if (userCredential.user != null) {
        if (role == UserRole.admin) {
          _admin = await _authService.getAdminByPhoneNumber(phoneNumber);
          _customer = null;
        } else {
          _customer = await _authService.getCustomerByPhoneNumber(phoneNumber);
          _admin = null;
        }

        if (_admin != null || _customer != null) {
          _setLoading(false);
          return true;
        }
      }

      _setError("User record not found.");
      _setLoading(false);
      return false;
    } catch (e) {
      _setLoading(false);
      _setError("Invalid OTP.");
      return false;
    }
  }

  Future<void> sendOtp(
    String phoneNumber,
    UserRole role, {
    required void Function(String verificationId) onCodeSent,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final userData = (role == UserRole.admin)
          ? await _authService.getAdminByPhoneNumber(phoneNumber)
          : await _authService.getCustomerByPhoneNumber(phoneNumber);

      if (userData == null) {
        _setLoading(false);
        _setError(
          '${role == UserRole.admin ? "Admin" : "Customer"} phone number not found!',
        );
        return;
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 30),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          _setLoading(false);
        },
        verificationFailed: (FirebaseAuthException e) {
          _setLoading(false);
          _setError('Error: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          _setLoading(false);
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _setLoading(false);
        },
      );
    } catch (e) {
      _setLoading(false);
      _setError('Error checking phone number: $e');
    }
  }

  Future<void> fetchCurrentUser(String phoneNumber, UserRole role) async {
    _setLoading(true);

    try {
      final collectionName = role == UserRole.admin ? "admins" : "customers";

      final querySnapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .where('PhoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();

        if (role == UserRole.admin) {
          _admin = AdminModel.fromFirestore(data);
        } else {
          _customer = CustomerModel.fromFirestore(data);
        }
      } else {
        AppLogger.info("No user found with phone: $phoneNumber");
        _admin = null;
        _customer = null;
      }
    } catch (e) {
      AppLogger.error("Failed to fetch user: $e");
    } finally {
      // 3. 无论成功失败，最后都要关闭 Loading
      _setLoading(false);
      notifyListeners();
    }
  }

  void clearError() {
    _setError(null);
  }
}
