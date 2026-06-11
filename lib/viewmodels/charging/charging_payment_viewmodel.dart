import 'package:flutter/foundation.dart';

import '../../core/utils/app_logger.dart';
import '../../models/charging_checkout_model.dart';
import '../../services/charging_payment_service.dart';

enum ChargingPaymentResult { success, insufficientBalance, noCustomer, failed }

enum ChargingPaymentHistoryResult { success, noDetails, failed }

class ChargingPaymentViewModel extends ChangeNotifier {
  ChargingPaymentViewModel({ChargingPaymentServiceContract? paymentService})
    : _paymentService = paymentService ?? ChargingPaymentService();

  final ChargingPaymentServiceContract _paymentService;

  ChargingPaymentSummaryDetails? _summaryDetails;
  ChargingPaymentProfile? _profile;
  ChargingPaymentHistoryDetails? _historyDetails;
  ChargingPaymentHistoryDetail? _historyDetail;
  ChargingPaymentMethod? _selectedMethod;
  bool _isLoading = false;
  bool _isProcessing = false;
  bool _isCreatingHistory = false;
  String? _errorMessage;

  ChargingPaymentSummaryDetails? get summaryDetails => _summaryDetails;
  ChargingPaymentProfile? get profile => _profile;
  ChargingPaymentHistoryDetails? get historyDetails => _historyDetails;
  ChargingPaymentHistoryDetail? get historyDetail => _historyDetail;
  ChargingPaymentMethod? get selectedMethod => _selectedMethod;
  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  bool get isCreatingHistory => _isCreatingHistory;
  String? get errorMessage => _errorMessage;

  String get stationName => _summaryDetails?.stationName ?? '';
  String get chargerName => _summaryDetails?.chargerName ?? '';
  String get chargerType => _summaryDetails?.chargerType ?? '';
  String get stationImageUrl => _summaryDetails?.stationImageUrl ?? '';
  double get walletBalance => _profile?.walletBalance ?? 0;
  String? get cardNumber => _profile?.cardNumber;

  double subtotal({required double chargingCost, required double penaltyCost}) {
    return chargingCost + penaltyCost;
  }

  double totalAfterDiscount({
    required double chargingCost,
    required double penaltyCost,
    required double rewardDiscount,
  }) {
    final total =
        subtotal(chargingCost: chargingCost, penaltyCost: penaltyCost) -
        rewardDiscount;
    return total < 0 ? 0 : total;
  }

  Future<void> loadSummaryDetails() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _summaryDetails = await _paymentService.fetchPaymentSummaryDetails();
      if (_summaryDetails == null) {
        _errorMessage = 'Failed to load payment details.';
      }
    } catch (e) {
      AppLogger.error('Error loading payment summary details: $e');
      _summaryDetails = null;
      _errorMessage = 'Failed to load payment details.';
    } finally {
      _setLoading(false);
    }
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
      AppLogger.error('Error loading payment profile: $e');
      _profile = null;
      _errorMessage = 'Failed to load payment methods.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadPaymentHistoryDetails() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _historyDetails = await _paymentService.fetchPaymentHistoryDetails();
      if (_historyDetails == null) {
        _errorMessage = 'Failed to load payment receipt details.';
      }
    } catch (e) {
      AppLogger.error('Error loading payment history details: $e');
      _historyDetails = null;
      _errorMessage = 'Failed to load payment receipt details.';
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
      AppLogger.error('Error loading payment history detail: $e');
      _historyDetail = null;
      _errorMessage = 'Failed to load payment receipt details.';
    } finally {
      _setLoading(false);
    }
  }

  void selectPaymentMethod(ChargingPaymentMethod method) {
    _selectedMethod = method;
    notifyListeners();
  }

  Future<ChargingPaymentResult> processPayment({
    required double totalAmount,
    required String rewardId,
    required int rewardPoints,
  }) async {
    final profile = _profile;
    final selectedMethod = _selectedMethod;
    if (profile == null) return ChargingPaymentResult.noCustomer;
    if (selectedMethod == null) return ChargingPaymentResult.failed;

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
        case ChargingPaymentProcessStatus.success:
          _profile = ChargingPaymentProfile(
            customerId: profile.customerId,
            walletBalance: result.walletBalance,
            pointBalance: profile.pointBalance - rewardPoints,
            cardNumber: profile.cardNumber,
          );
          return ChargingPaymentResult.success;
        case ChargingPaymentProcessStatus.insufficientBalance:
          _profile = ChargingPaymentProfile(
            customerId: profile.customerId,
            walletBalance: result.walletBalance,
            pointBalance: profile.pointBalance,
            cardNumber: profile.cardNumber,
          );
          return ChargingPaymentResult.insufficientBalance;
        case ChargingPaymentProcessStatus.customerNotFound:
          _errorMessage = 'Customer payment profile was not found.';
          return ChargingPaymentResult.noCustomer;
        case ChargingPaymentProcessStatus.failed:
          _errorMessage = 'Payment failed. Try again!';
          return ChargingPaymentResult.failed;
      }
    } catch (e) {
      AppLogger.error('Error processing payment: $e');
      _errorMessage = 'Payment failed. Try again!';
      return ChargingPaymentResult.failed;
    } finally {
      _setProcessing(false);
    }
  }

  String selectedPaymentMethodLabel() {
    return _selectedMethod == ChargingPaymentMethod.wallet
        ? 'EZCHARGE Wallet'
        : 'Credit Card';
  }

  Future<(ChargingPaymentHistoryResult, String?)> createPaymentHistory({
    required String paymentMethod,
    required double totalAmount,
  }) async {
    final details = _historyDetails;
    if (details == null) {
      return (ChargingPaymentHistoryResult.noDetails, null);
    }

    _setCreatingHistory(true);
    _errorMessage = null;

    try {
      final paymentId = await _paymentService.createPaymentHistoryRecord(
        details: details,
        paymentMethod: paymentMethod,
        totalAmount: totalAmount,
      );
      return (ChargingPaymentHistoryResult.success, paymentId);
    } catch (e) {
      AppLogger.error('Error creating payment history: $e');
      _errorMessage = 'Failed to create payment record.';
      return (ChargingPaymentHistoryResult.failed, null);
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
