import 'package:flutter/foundation.dart';

import '../../core/utils/app_logger.dart';
import '../../models/profile_payment_card_model.dart';
import '../../services/profile_payment_service.dart';

class PaymentMethodViewModel extends ChangeNotifier {
  PaymentMethodViewModel({ProfilePaymentServiceContract? paymentService})
    : _paymentService = paymentService ?? ProfilePaymentService();

  final ProfilePaymentServiceContract _paymentService;

  ProfilePaymentMethodProfile? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  ProfilePaymentMethodProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get walletBalance => _profile?.walletBalance ?? 0;
  String get cardNumber => _profile?.cardNumber ?? '';

  Future<void> loadPaymentMethodProfile() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _profile = await _paymentService.fetchPaymentMethodProfile();
      if (_profile == null) {
        _errorMessage = 'Customer payment profile was not found.';
      }
    } catch (e) {
      AppLogger.error('Error loading payment method view state: $e');
      _profile = null;
      _errorMessage = 'Unable to load payment methods. Please try again.';
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
