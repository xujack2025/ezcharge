import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:ezcharge/models/admin_model.dart';
import 'package:ezcharge/services/auth_service.dart';

class AuthViewmodel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  AdminModel? _admin;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AdminModel? get admin => _admin;

  Future<void> sendAdminOtp(
    String phoneNumber, {
    required void Function(String verificationId) onCodeSent,
  }) async {
    if (phoneNumber.isEmpty || phoneNumber.length < 10) {
      _errorMessage = 'Enter a valid phone number';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 🔥 看到没有？这里直接用 Model，代码超级干净
      _admin = await _authService.getAdminByPhoneNumber(phoneNumber);

      if (_admin == null) {
        _isLoading = false;
        _errorMessage = 'Admin phone number not found!';
        notifyListeners();
        return;
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          _isLoading = false;
          _errorMessage = 'Error: ${e.message}';
          notifyListeners();
        },
        codeSent: (String verificationId, int? resendToken) {
          _isLoading = false;
          notifyListeners();
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error checking phone number: $e';
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
