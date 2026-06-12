import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/app_logger.dart';
import '../models/customer_model.dart';
import 'auth_service.dart';

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

  Future<void> updateCustomerProfile(CustomerProfileUpdate update);
}

class CustomerProfileUpdate {
  const CustomerProfileUpdate({
    required this.customerId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.gender,
    required this.dateOfBirth,
  });

  final String customerId;
  final String firstName;
  final String lastName;
  final String email;
  final String? gender;
  final String? dateOfBirth;

  Map<String, dynamic> toFirestore() {
    return {
      'FirstName': firstName,
      'LastName': lastName,
      'EmailAddress': email,
      'Gender': gender,
      'DateOfBirth': dateOfBirth,
    };
  }
}

class ProfileService implements ProfileServiceContract {
  ProfileService({
    AuthServiceContract? authService,
    FirebaseFirestore? firestore,
  }) : _authService = authService ?? AuthService(),
       _firestore = firestore ?? FirebaseFirestore.instance;

  final AuthServiceContract _authService;
  final FirebaseFirestore _firestore;

  @override
  Future<CustomerProfileData?> fetchCurrentCustomerProfile() async {
    final phoneNumber = _authService.getCurrentUserPhoneNumber();
    if (phoneNumber == null || phoneNumber.isEmpty) {
      AppLogger.info('Cannot load profile without a signed-in phone number.');
      return null;
    }

    try {
      final customer = await _authService.getCustomerByPhoneNumber(phoneNumber);
      if (customer == null) {
        AppLogger.info('No customer profile found for phone: $phoneNumber');
        return null;
      }

      final authStatus = await _authService.getAuthStatus(customer.id);

      return CustomerProfileData(
        customer: customer,
        authenticationStatus: authStatus,
      );
    } catch (e) {
      AppLogger.error('Error loading customer profile: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateCustomerProfile(CustomerProfileUpdate update) async {
    try {
      await _firestore
          .collection('Customers')
          .doc(update.customerId)
          .update(update.toFirestore());
      AppLogger.info('Updated customer profile: ${update.customerId}');
    } catch (e) {
      AppLogger.error('Error updating customer profile: $e');
      rethrow;
    }
  }
}
