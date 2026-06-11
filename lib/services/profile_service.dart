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
}

class ProfileService implements ProfileServiceContract {
  ProfileService({
    AuthServiceContract? authService,
  }) : _authService = authService ?? AuthService();

  final AuthServiceContract _authService;

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
}
