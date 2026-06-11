import 'package:flutter/foundation.dart';

import '../core/utils/app_logger.dart';
import '../models/emergency_payment_model.dart';
import '../services/payment_service.dart';

enum EmergencyPaymentResult { success, insufficientBalance, noCustomer, failed }

enum EmergencyPaymentHistoryResult { success, noDetails, failed }

class EmergencyPaymentViewModel extends ChangeNotifier {
  EmergencyPaymentViewModel({EmergencyPaymentServiceContract? paymentService})
    : _paymentService = paymentService ?? EmergencyPaymentService();

  final EmergencyPaymentServiceContract _paymentService;

  EmergencyPaymentProfile? _profile;
  EmergencyPaymentMethod? _selectedMethod;
  EmergencyPaymentSuccessDetails? _successDetails;
  EmergencyPaymentHistoryDetail? _historyDetail;
  bool _isLoading = false;
  bool _isProcessing = false;
  bool _isCreatingHistory = false;
  String? _errorMessage;

  EmergencyPaymentProfile? get profile => _profile;
  EmergencyPaymentMethod? get selectedMethod => _selectedMethod;
  EmergencyPaymentSuccessDetails? get successDetails => _successDetails;
  EmergencyPaymentHistoryDetail? get historyDetail => _historyDetail;
  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  bool get isCreatingHistory => _isCreatingHistory;
  String? get errorMessage => _errorMessage;
  double get walletBalance => _profile?.walletBalance ?? 0;
  String? get cardNumber => _profile?.cardNumber;

  double totalAfterDiscount({
    required double chargingCost,
    required double rewardDiscount,
  }) {
    final total = chargingCost - rewardDiscount;
    return total < 0 ? 0 : total;
  }

  Future<void> loadPaymentProfile() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _profile = await _paymentService.fetchPaymentProfile();
      if (_profile == null) {
        _errorMessage = 'Customer payment profile was not found.';
      }
    } catch (e) {
      AppLogger.error('Error loading emergency payment profile: $e');
      _profile = null;
      _errorMessage = 'Failed to load payment methods.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadSuccessDetails() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _successDetails = await _paymentService.fetchSuccessDetails();
      if (_successDetails == null) {
        _errorMessage = 'Failed to load request payment details.';
      }
    } catch (e) {
      AppLogger.error('Error loading emergency payment success details: $e');
      _successDetails = null;
      _errorMessage = 'Failed to load request payment details.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadPaymentHistoryDetail({
    required String accountId,
    required String paymentId,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _historyDetail = await _paymentService.fetchPaymentHistoryDetail(
        accountId: accountId,
        paymentId: paymentId,
      );
      if (_historyDetail == null) {
        _errorMessage = 'Failed to load payment receipt details.';
      }
    } catch (e) {
      AppLogger.error('Error loading emergency payment history detail: $e');
      _historyDetail = null;
      _errorMessage = 'Failed to load payment receipt details.';
    } finally {
      _setLoading(false);
    }
  }

  void selectPaymentMethod(EmergencyPaymentMethod method) {
    _selectedMethod = method;
    notifyListeners();
  }

  Future<EmergencyPaymentResult> processPayment({
    required double totalAmount,
    required String rewardId,
    required int rewardPoints,
  }) async {
    final profile = _profile;
    final selectedMethod = _selectedMethod;
    if (profile == null) return EmergencyPaymentResult.noCustomer;
    if (selectedMethod == null) return EmergencyPaymentResult.failed;

    _setProcessing(true);
    _errorMessage = null;

    try {
      final result = await _paymentService.processPayment(
        customerId: profile.customerId,
        totalAmount: totalAmount,
        method: selectedMethod,
        rewardId: rewardId,
        rewardPoints: rewardPoints,
      );

      switch (result.status) {
        case EmergencyPaymentProcessStatus.success:
          _profile = EmergencyPaymentProfile(
            customerId: profile.customerId,
            walletBalance: result.walletBalance,
            pointBalance: profile.pointBalance - rewardPoints,
            cardNumber: profile.cardNumber,
          );
          return EmergencyPaymentResult.success;
        case EmergencyPaymentProcessStatus.insufficientBalance:
          _profile = EmergencyPaymentProfile(
            customerId: profile.customerId,
            walletBalance: result.walletBalance,
            pointBalance: profile.pointBalance,
            cardNumber: profile.cardNumber,
          );
          return EmergencyPaymentResult.insufficientBalance;
        case EmergencyPaymentProcessStatus.customerNotFound:
          _errorMessage = 'Customer payment profile was not found.';
          return EmergencyPaymentResult.noCustomer;
        case EmergencyPaymentProcessStatus.failed:
          _errorMessage = 'Payment failed. Try again!';
          return EmergencyPaymentResult.failed;
      }
    } catch (e) {
      AppLogger.error('Error processing emergency payment: $e');
      _errorMessage = 'Payment failed. Try again!';
      return EmergencyPaymentResult.failed;
    } finally {
      _setProcessing(false);
    }
  }

  String selectedPaymentMethodLabel() {
    return _selectedMethod == EmergencyPaymentMethod.wallet
        ? 'EZCHARGE Wallet'
        : 'Credit Card';
  }

  Future<(EmergencyPaymentHistoryResult, String?)> createPaymentHistory({
    required String paymentMethod,
    required double totalAmount,
  }) async {
    final details = _successDetails;
    if (details == null) {
      return (EmergencyPaymentHistoryResult.noDetails, null);
    }

    _setCreatingHistory(true);
    _errorMessage = null;

    try {
      final paymentId = await _paymentService.createPaymentHistoryRecord(
        details: details,
        paymentMethod: paymentMethod,
        totalAmount: totalAmount,
      );
      return (EmergencyPaymentHistoryResult.success, paymentId);
    } catch (e) {
      AppLogger.error('Error creating emergency payment history: $e');
      _errorMessage = 'Failed to create payment record.';
      return (EmergencyPaymentHistoryResult.failed, null);
    } finally {
      _setCreatingHistory(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setProcessing(bool value) {
    _isProcessing = value;
    notifyListeners();
  }

  void _setCreatingHistory(bool value) {
    _isCreatingHistory = value;
    notifyListeners();
  }
}
