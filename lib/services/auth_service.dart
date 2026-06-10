import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/utils/app_logger.dart';
import '../models/admin_model.dart';
import '../models/customer_model.dart';
import '../models/user_model.dart';

abstract class AuthServiceContract {
  Future<UserCredential> signInWithOtp(String verificationId, String smsCode);

  Future<void> sendOtp(
    String phoneNumber,
    UserRole role, {
    required void Function(String verificationId) onCodeSent,
    required void Function() onVerificationCompleted,
    required void Function(String message) onError,
  });

  Future<UserModel?> getUserByPhoneNumber(String phoneNumber, UserRole role);

  Future<AdminModel?> getAdminByPhoneNumber(String phoneNumber);

  Future<CustomerModel?> getCustomerByPhoneNumber(String phoneNumber);

  Future<String> getAuthStatus(String customerId);

  String? getCurrentUserPhoneNumber();

  Future<void> signout();
}

class AuthService implements AuthServiceContract {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<UserCredential> signInWithOtp(
    String verificationId,
    String smsCode,
  ) async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await _auth.signInWithCredential(credential);
  }

  @override
  Future<void> sendOtp(
    String phoneNumber,
    UserRole role, {
    required void Function(String verificationId) onCodeSent,
    required void Function() onVerificationCompleted,
    required void Function(String message) onError,
  }) async {
    final userData = await getUserByPhoneNumber(phoneNumber, role);

    if (userData == null) {
      onError(
        '${role == UserRole.admin ? "Admin" : "Customer"} phone number not found!',
      );
      return;
    }

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 30),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          onVerificationCompleted();
        },
        verificationFailed: (FirebaseAuthException e) {
          onError('Error: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      onError('Error checking phone number: $e');
    }
  }

  @override
  Future<UserModel?> getUserByPhoneNumber(
    String phoneNumber,
    UserRole role,
  ) async {
    return role == UserRole.admin
        ? await getAdminByPhoneNumber(phoneNumber)
        : await getCustomerByPhoneNumber(phoneNumber);
  }

  @override
  Future<AdminModel?> getAdminByPhoneNumber(String phoneNumber) async {
    try {
      final querySnapshot = await _firestore
          .collection('admins')
          .where('PhoneNumber', isEqualTo: phoneNumber)
          .get();

      if (querySnapshot.docs.isEmpty) {
        AppLogger.info("No admin found with phone number: $phoneNumber");
        return null;
      }

      final adminData = querySnapshot.docs.first.data();
      final admin = AdminModel.fromFirestore(adminData);
      AppLogger.debug("Admin Model successfully created: ${admin.firstName}");
      return admin;
    } catch (e) {
      AppLogger.error("Error fetching admin by phone number: $e");
      return null;
    }
  }

  @override
  Future<CustomerModel?> getCustomerByPhoneNumber(String phoneNumber) async {
    try {
      final querySnapshot = await _firestore
          .collection('customers')
          .where('PhoneNumber', isEqualTo: phoneNumber)
          .get();

      if (querySnapshot.docs.isEmpty) {
        AppLogger.info("No customer found with phone number: $phoneNumber");
        return null;
      }

      final customerData = querySnapshot.docs.first.data();
      final customer = CustomerModel.fromFirestore(customerData);
      AppLogger.debug(
        "Customer Model successfully created: ${customer.firstName}",
      );
      return customer;
    } catch (e) {
      AppLogger.error("Error fetching customer by phone number: $e");
      return null;
    }
  }

  @override
  Future<String> getAuthStatus(String customerId) async {
    final querySnapshot = await _firestore
        .collection("customers")
        .doc(customerId)
        .collection("authenticate")
        .doc("authentication")
        .get();
    return querySnapshot.exists ? querySnapshot["Status"] : "";
  }

  @override
  String? getCurrentUserPhoneNumber() {
    return _auth.currentUser?.phoneNumber;
  }

  @override
  Future<void> signout() async {
    try {
      await _auth.signOut();
      AppLogger.info("User Signed Out");
    } catch (e) {
      AppLogger.error("Unexpected error during sign-out: $e");
    }
  }
}
