import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:ezcharge/models/admin_model.dart';
import 'package:ezcharge/services/auth_service.dart';

class AuthViewmodel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService;

  AuthViewmodel({AuthService? authService})
    : _authService = authService ?? AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  AdminModel? _admin;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AdminModel? get admin => _admin;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<bool> verifyAdminOtp(
    String verificationId,
    String smsCode,
    String phoneNumber,
  ) async {
    _setLoading(true);
    _setError(null);

    try {
      final userCredential = await _authService.signInWithOtp(
        verificationId,
        smsCode,
      );

      if (userCredential.user != null) {
        final admin = await _authService.getAdminByPhoneNumber(phoneNumber);

        if (admin != null) {
          _admin = admin;
          _setLoading(false);
          return true; // 告诉 UI：成功了，可以跳转
        }
      }

      _setError("Admin records not found.");
      _setLoading(false);
      return false;
    } catch (e) {
      _setLoading(false);
      _setError("Invalid OTP or Connection Error.");
      return false;
    }
  }

  Future<void> sendAdminOtp(
    String phoneNumber, {
    required void Function(String verificationId) onCodeSent,
  }) async {
    if (phoneNumber.isEmpty || phoneNumber.length < 10) {
      _setError('Enter a valid phone number');
      return;
    }

    _setLoading(true);
    _setError(null);

    try {
      _admin = await _authService.getAdminByPhoneNumber(phoneNumber);

      if (_admin == null) {
        _setLoading(false);
        _setError('Admin phone number not found!');
        return;
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          _setLoading(false);
          _setError('Error: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          _setLoading(false);
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
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
