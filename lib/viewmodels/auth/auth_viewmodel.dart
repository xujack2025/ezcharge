import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:ezcharge/models/admin_model.dart';

class AuthViewmodel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      final querySnapshot = await _firestore
          .collection('admins')
          .where('PhoneNumber', isEqualTo: phoneNumber)
          .get();

      if (querySnapshot.docs.isEmpty) {
        _isLoading = false;
        _errorMessage = 'Admin phone number not found!';
        _admin = null;
        notifyListeners();
        return;
      }

      _admin = AdminModel.fromFirestore(querySnapshot.docs.first.data());

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
