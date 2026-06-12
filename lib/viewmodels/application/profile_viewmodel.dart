import 'package:flutter/foundation.dart';

import '../../core/utils/app_logger.dart';
import '../../models/customer_model.dart';
import '../../services/profile_service.dart';

enum ProfileUpdateResult { success, noCustomer, invalidEmail, failed }

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({ProfileServiceContract? profileService})
    : _profileService = profileService ?? ProfileService();

  final ProfileServiceContract _profileService;

  CustomerModel? _customer;
  String _authenticationStatus = '';
  bool _isLoading = false;
  String? _errorMessage;

  CustomerModel? get customer => _customer;
  String get authenticationStatus => _authenticationStatus;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get customerName {
    final customer = _customer;
    if (customer == null) return 'Loading...';

    final fullName = '${customer.firstName} ${customer.lastName}'.trim();
    return fullName.isEmpty ? 'Customer' : fullName;
  }

  String get accountId => _customer?.id ?? '00000000';
  double get walletBalance => _customer?.walletBalance ?? 0;
  int get pointBalance => _customer?.pointBalance ?? 0;
  String get firstName => _customer?.firstName ?? '';
  String get lastName => _customer?.lastName ?? '';
  String get email => _customer?.email ?? '';
  String get phone => _customer?.phone ?? '';
  String get gender => _customer?.gender ?? '';
  String get dateOfBirth => _customer?.dateOfBirth ?? '';

  Future<void> loadProfile() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final profile = await _profileService.fetchCurrentCustomerProfile();
      if (profile == null) {
        _customer = null;
        _authenticationStatus = '';
        _errorMessage = 'Customer profile not found.';
        return;
      }

      _customer = profile.customer;
      _authenticationStatus = profile.authenticationStatus;
    } catch (e) {
      AppLogger.error('Error loading profile view state: $e');
      _errorMessage = 'Unable to load profile. Please try again.';
    } finally {
      _setLoading(false);
    }
  }

  Future<ProfileUpdateResult> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String? gender,
    required String? dateOfBirth,
  }) async {
    final customer = _customer;
    if (customer == null || customer.id.isEmpty) {
      _errorMessage = 'Customer profile not found.';
      notifyListeners();
      return ProfileUpdateResult.noCustomer;
    }

    final trimmedEmail = email.trim();
    if (!trimmedEmail.endsWith('@gmail.com')) {
      _errorMessage = 'Invalid email address.';
      notifyListeners();
      return ProfileUpdateResult.invalidEmail;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      await _profileService.updateCustomerProfile(
        CustomerProfileUpdate(
          customerId: customer.id,
          firstName: firstName.trim(),
          lastName: lastName.trim(),
          email: trimmedEmail,
          gender: gender,
          dateOfBirth: dateOfBirth,
        ),
      );
      await loadProfile();
      return ProfileUpdateResult.success;
    } catch (e) {
      AppLogger.error('Error updating profile view state: $e');
      _errorMessage = 'Failed to update profile.';
      return ProfileUpdateResult.failed;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
