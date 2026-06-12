import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ezcharge/models/customer_model.dart';
import 'package:ezcharge/services/profile_service.dart';
import 'package:ezcharge/viewmodels/application/profile_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeProfileService implements ProfileServiceContract {
  CustomerProfileData? profile;
  Object? error;
  Object? updateError;
  CustomerProfileUpdate? updatedProfile;

  @override
  Future<CustomerProfileData?> fetchCurrentCustomerProfile() async {
    final error = this.error;
    if (error != null) throw error;
    return profile;
  }

  @override
  Future<void> updateCustomerProfile(CustomerProfileUpdate update) async {
    final updateError = this.updateError;
    if (updateError != null) throw updateError;
    updatedProfile = update;
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

    test('updates editable profile fields through service', () async {
      final service = FakeProfileService()
        ..profile = CustomerProfileData(
          customer: customer(),
          authenticationStatus: 'Pass',
        );
      final viewModel = ProfileViewModel(profileService: service);

      await viewModel.loadProfile();
      final result = await viewModel.updateProfile(
        firstName: ' June ',
        lastName: ' Lim ',
        email: ' june@gmail.com ',
        gender: 'Female',
        dateOfBirth: '1/1/2000',
      );

      expect(result, ProfileUpdateResult.success);
      expect(service.updatedProfile?.customerId, 'CUS1');
      expect(service.updatedProfile?.firstName, 'June');
      expect(service.updatedProfile?.lastName, 'Lim');
      expect(service.updatedProfile?.email, 'june@gmail.com');
      expect(service.updatedProfile?.gender, 'Female');
      expect(service.updatedProfile?.dateOfBirth, '1/1/2000');
      expect(viewModel.errorMessage, isNull);
    });

    test('does not update when customer profile is missing', () async {
      final service = FakeProfileService();
      final viewModel = ProfileViewModel(profileService: service);

      final result = await viewModel.updateProfile(
        firstName: 'June',
        lastName: 'Lim',
        email: 'june@gmail.com',
        gender: 'Female',
        dateOfBirth: '1/1/2000',
      );

      expect(result, ProfileUpdateResult.noCustomer);
      expect(service.updatedProfile, isNull);
      expect(viewModel.errorMessage, 'Customer profile not found.');
    });

    test('rejects invalid email before calling service', () async {
      final service = FakeProfileService()
        ..profile = CustomerProfileData(
          customer: customer(),
          authenticationStatus: 'Pass',
        );
      final viewModel = ProfileViewModel(profileService: service);

      await viewModel.loadProfile();
      final result = await viewModel.updateProfile(
        firstName: 'June',
        lastName: 'Lim',
        email: 'june@example.com',
        gender: 'Female',
        dateOfBirth: '1/1/2000',
      );

      expect(result, ProfileUpdateResult.invalidEmail);
      expect(service.updatedProfile, isNull);
      expect(viewModel.errorMessage, 'Invalid email address.');
    });

    test('maps update service failure to friendly result', () async {
      final service = FakeProfileService()
        ..profile = CustomerProfileData(
          customer: customer(),
          authenticationStatus: 'Pass',
        )
        ..updateError = Exception('firestore');
      final viewModel = ProfileViewModel(profileService: service);

      await viewModel.loadProfile();
      final result = await viewModel.updateProfile(
        firstName: 'June',
        lastName: 'Lim',
        email: 'june@gmail.com',
        gender: 'Female',
        dateOfBirth: '1/1/2000',
      );

      expect(result, ProfileUpdateResult.failed);
      expect(viewModel.errorMessage, 'Failed to update profile.');
    });
  });
}
