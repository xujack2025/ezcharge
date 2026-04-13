import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
