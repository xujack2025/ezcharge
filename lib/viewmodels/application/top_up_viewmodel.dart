import 'package:flutter/foundation.dart';

import '../../core/utils/app_logger.dart';
import '../../models/profile_payment_card_model.dart';
import '../../services/profile_payment_service.dart';

enum TopUpPaymentMethod { card, reloadPin }

enum TopUpResult { success, invalidAmount, customerNotFound, failed }

class TopUpViewModel extends ChangeNotifier {
  TopUpViewModel({ProfilePaymentServiceContract? paymentService})
    : _paymentService = paymentService ?? ProfilePaymentService();

  final ProfilePaymentServiceContract _paymentService;

  ProfilePaymentMethodProfile? _profile;
  bool _isLoading = false;
  bool _isProcessingTopUp = false;
  String? _errorMessage;
  String _amountText = '';
  TopUpPaymentMethod? _selectedPaymentMethod;

  ProfilePaymentMethodProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isProcessingTopUp => _isProcessingTopUp;
  String? get errorMessage => _errorMessage;
  String get amountText => _amountText;
  TopUpPaymentMethod? get selectedPaymentMethod => _selectedPaymentMethod;
  double get walletBalance => _profile?.walletBalance ?? 0;
  String get cardNumber => _profile?.cardNumber ?? '';
  bool get hasCard => cardNumber.isNotEmpty;
  bool get isCardSelected => _selectedPaymentMethod == TopUpPaymentMethod.card;
  bool get isReloadPinSelected =>
      _selectedPaymentMethod == TopUpPaymentMethod.reloadPin;
  bool get canSubmit =>
      _amountText.trim().isNotEmpty &&
      _selectedPaymentMethod != null &&
      !_isProcessingTopUp;

  double? get selectedAmount {
    final amount = double.tryParse(_amountText.trim());
    if (amount == null || amount <= 0) return null;
    return amount;
  }

  Future<void> loadTopUpProfile() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _profile = await _paymentService.fetchPaymentMethodProfile();
      if (_profile == null) {
        _errorMessage = 'Customer payment profile was not found.';
      }
    } catch (e) {
      AppLogger.error('Error loading top-up view state: $e');
      _profile = null;
      _errorMessage = 'Unable to load top-up details. Please try again.';
    } finally {
      _setLoading(false);
    }
  }

  void setAmountText(String value) {
    if (_amountText == value) return;
    _amountText = value;
    notifyListeners();
  }

  void selectQuickAmount(int amount) {
    setAmountText(amount.toString());
  }

  void selectPaymentMethod(TopUpPaymentMethod method) {
    if (method == TopUpPaymentMethod.card && !hasCard) return;
    _selectedPaymentMethod = method;
    notifyListeners();
  }

  void clearPaymentMethod() {
    if (_selectedPaymentMethod == null) return;
    _selectedPaymentMethod = null;
    notifyListeners();
  }

  Future<TopUpResult> topUpWithCard() async {
    final amount = selectedAmount;
    if (amount == null) {
      _errorMessage = 'Enter a valid top-up amount.';
      notifyListeners();
      return TopUpResult.invalidAmount;
    }

    _setProcessingTopUp(true);
    _errorMessage = null;

    try {
      final status = await _paymentService.topUpWallet(amount);
      switch (status) {
        case ProfileWalletTopUpStatus.success:
          return TopUpResult.success;
        case ProfileWalletTopUpStatus.customerNotFound:
          _errorMessage = 'Customer payment profile was not found.';
          return TopUpResult.customerNotFound;
      }
    } catch (e) {
      AppLogger.error('Error topping up wallet view state: $e');
      _errorMessage = 'Unable to update wallet. Please try again.';
      return TopUpResult.failed;
    } finally {
      _setProcessingTopUp(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setProcessingTopUp(bool value) {
    _isProcessingTopUp = value;
    notifyListeners();
  }
}
