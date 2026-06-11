import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/utils/app_logger.dart';
import '../models/customer_model.dart';

class CustomerProfileData {
  const CustomerProfileData({
    required this.customer,
    required this.authenticationStatus,
  });

  final CustomerModel customer;
  final String authenticationStatus;
}

abstract class ProfileServiceContract {
  Future<CustomerProfileData?> fetchCurrentCustomerProfile();
}

class ProfileService implements ProfileServiceContract {
  ProfileService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Future<CustomerProfileData?> fetchCurrentCustomerProfile() async {
    final phoneNumber = _auth.currentUser?.phoneNumber;
    if (phoneNumber == null || phoneNumber.isEmpty) {
      AppLogger.info('Cannot load profile without a signed-in phone number.');
      return null;
    }

    try {
      final customerSnapshot = await _firestore
          .collection('Customers')
          .where('PhoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (customerSnapshot.docs.isEmpty) {
        AppLogger.info('No customer profile found for phone: $phoneNumber');
        return null;
      }

      final customer = CustomerModel.fromFirestore(
        customerSnapshot.docs.first.data(),
      );
      final authStatus = await _fetchAuthenticationStatus(customer.id);

      return CustomerProfileData(
        customer: customer,
        authenticationStatus: authStatus,
      );
    } catch (e) {
      AppLogger.error('Error loading customer profile: $e');
      rethrow;
    }
  }

  Future<String> _fetchAuthenticationStatus(String customerId) async {
    if (customerId.isEmpty) return '';

    final doc = await _firestore
        .collection('Customers')
        .doc(customerId)
        .collection('Authenticate')
        .doc('authentication')
        .get();

    if (!doc.exists) return '';
    final data = doc.data();
    return data?['Status']?.toString() ?? '';
  }
}
