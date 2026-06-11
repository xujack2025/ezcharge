import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ezcharge/models/customer_model.dart';
import 'package:ezcharge/services/profile_service.dart';
import 'package:ezcharge/viewmodels/application/profile_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeProfileService implements ProfileServiceContract {
  CustomerProfileData? profile;
  Object? error;

  @override
  Future<CustomerProfileData?> fetchCurrentCustomerProfile() async {
    final error = this.error;
    if (error != null) throw error;
    return profile;
  }
}

void main() {
  CustomerModel customer({
    String firstName = 'Jane',
    String lastName = 'Tan',
    double walletBalance = 120,
    int pointBalance = 40,
  }) {
    return CustomerModel(
      id: 'CUS1',
      firstName: firstName,
      lastName: lastName,
      gender: 'Female',
      walletBalance: walletBalance,
      pointBalance: pointBalance,
      dateOfBirth: '2000-01-01',
      createdAt: Timestamp.fromMillisecondsSinceEpoch(0),
      email: 'jane@example.com',
      phone: '+60123456789',
    );
  }

  group('ProfileViewModel', () {
    test('loads current customer profile state', () async {
      final service = FakeProfileService()
        ..profile = CustomerProfileData(
          customer: customer(),
          authenticationStatus: 'Pending',
        );
      final viewModel = ProfileViewModel(profileService: service);

      await viewModel.loadProfile();

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.customerName, 'Jane Tan');
      expect(viewModel.accountId, 'CUS1');
      expect(viewModel.walletBalance, 120);
      expect(viewModel.pointBalance, 40);
      expect(viewModel.authenticationStatus, 'Pending');
    });

    test('exposes friendly error when customer profile is missing', () async {
      final service = FakeProfileService();
      final viewModel = ProfileViewModel(profileService: service);

      await viewModel.loadProfile();

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.customer, isNull);
      expect(viewModel.errorMessage, 'Customer profile not found.');
      expect(viewModel.customerName, 'Loading...');
      expect(viewModel.accountId, '00000000');
      expect(viewModel.walletBalance, 0);
      expect(viewModel.pointBalance, 0);
      expect(viewModel.authenticationStatus, '');
    });

    test('maps service failure to profile error state', () async {
      final service = FakeProfileService()..error = Exception('firestore');
      final viewModel = ProfileViewModel(profileService: service);

      await viewModel.loadProfile();

      expect(viewModel.isLoading, isFalse);
      expect(
        viewModel.errorMessage,
        'Unable to load profile. Please try again.',
      );
      expect(viewModel.walletBalance, 0);
    });
  });
}
