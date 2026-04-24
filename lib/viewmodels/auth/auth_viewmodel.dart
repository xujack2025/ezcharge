import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:ezcharge/models/admin_model.dart';
import 'package:ezcharge/models/customer_model.dart';
import 'package:ezcharge/models/user_model.dart';
import 'package:ezcharge/services/auth_service.dart';

class AuthViewmodel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService;

  AuthViewmodel({AuthService? authService})
    : _authService = authService ?? AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  AdminModel? _admin;
  CustomerModel? _customer;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AdminModel? get admin => _admin;
  CustomerModel? get customer => _customer;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
    debugPrint("DEBUG: isLoading is now $value at ${DateTime.now()}");
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
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

  void clearError() {
    _setError(null);
  }
}
