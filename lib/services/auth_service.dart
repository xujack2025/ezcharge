import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ezcharge/core/utils/app_logger.dart';
import 'package:ezcharge/models/admin_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      AppLogger.debug(
        "Admin Model successfully created: ${admin.firstName}",
      );
      return admin;
    } catch (e) {
      AppLogger.error("Error fetching admin by phone number: $e");
      return null;
    }
  }

  // 📌 Sign Out User
  Future<void> signout() async {
    try {
      await _auth.signOut();
      log("User Signed Out");
    } catch (e) {
      log("Unexpected error during sign-out: $e");
    }
  }
}
