import 'package:flutter/foundation.dart';

import '../../core/utils/app_logger.dart';
import '../../services/profile_payment_service.dart';

enum ReloadPinResult {
  success,
  emptyOtp,
  missingVerification,
  customerNotFound,
  invalidOtp,
  failed,
}

class ReloadPinViewModel extends ChangeNotifier {
  ReloadPinViewModel({
    required double topUpAmount,
    ProfilePaymentServiceContract? paymentService,
  }) : _topUpAmount = topUpAmount,
       _paymentService = paymentService ?? ProfilePaymentService();

  final double _topUpAmount;
  final ProfilePaymentServiceContract _paymentService;

  bool _isLoading = false;
  bool _isOtpValid = true;
  String? _errorMessage;
  String _verificationId = '';

  bool get isLoading => _isLoading;
  bool get isOtpValid => _isOtpValid;
  String? get errorMessage => _errorMessage;
  bool get hasVerificationId => _verificationId.isNotEmpty;

  Future<void> sendReloadPin() async {
    _setLoading(true);
    _errorMessage = null;
    _isOtpValid = true;

    try {
      final status = await _paymentService.sendReloadPin(
        onCodeSent: (verificationId) {
          _verificationId = verificationId;
          _setLoading(false);
        },
        onVerificationCompleted: () {
          _setLoading(false);
        },
      );

      switch (status) {
        case ProfileReloadPinSendStatus.sent:
          if (!hasVerificationId) {
            _setLoading(false);
          }
        case ProfileReloadPinSendStatus.customerNotFound:
          _errorMessage = 'Customer profile was not found.';
          _setLoading(false);
        case ProfileReloadPinSendStatus.failed:
          _errorMessage = 'Unable to send reload PIN. Please try again.';
          _setLoading(false);
      }
    } catch (e) {
      AppLogger.error('Error sending reload PIN view state: $e');
      _errorMessage = 'Unable to send reload PIN. Please try again.';
      _setLoading(false);
    }
  }

  Future<ReloadPinResult> verifyAndTopUp(String otp) async {
    final trimmedOtp = otp.trim();
    if (trimmedOtp.isEmpty) {
      _isOtpValid = false;
      _errorMessage = 'Please enter the reload PIN.';
      notifyListeners();
      return ReloadPinResult.emptyOtp;
    }

    if (_verificationId.isEmpty) {
      _errorMessage = 'Reload PIN was not sent. Please try again.';
      notifyListeners();
      return ReloadPinResult.missingVerification;
    }

    _setLoading(true);
    _errorMessage = null;
    _isOtpValid = true;

    try {
      final status = await _paymentService.verifyReloadPinAndTopUp(
        verificationId: _verificationId,
        otp: trimmedOtp,
        amount: _topUpAmount,
      );

      switch (status) {
        case ProfileWalletTopUpStatus.success:
          return ReloadPinResult.success;
        case ProfileWalletTopUpStatus.customerNotFound:
          _errorMessage = 'Customer payment profile was not found.';
          return ReloadPinResult.customerNotFound;
      }
    } catch (e) {
      AppLogger.error('Error verifying reload PIN view state: $e');
      _isOtpValid = false;
      _errorMessage = 'Invalid Reload OTP';
      return ReloadPinResult.invalidOtp;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
