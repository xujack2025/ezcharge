import 'package:ezcharge/models/profile_payment_card_model.dart';
import 'package:ezcharge/services/profile_payment_service.dart';
import 'package:ezcharge/viewmodels/application/reload_pin_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeProfilePaymentService implements ProfilePaymentServiceContract {
  ProfileReloadPinSendStatus sendStatus = ProfileReloadPinSendStatus.sent;
  ProfileWalletTopUpStatus topUpStatus = ProfileWalletTopUpStatus.success;
  Object? verifyError;
  String? receivedVerificationId;
  String? receivedOtp;
  double? receivedAmount;
  bool shouldSendCode = true;

  @override
  Future<ProfilePaymentMethodProfile?> fetchPaymentMethodProfile() async {
    return null;
  }

  @override
  Future<ProfilePaymentHistoryFeed?> watchPaymentHistory() async {
    return null;
  }

  @override
  Future<AddProfilePaymentCardStatus> addPaymentCard(
    ProfilePaymentCardInput card,
  ) async {
    return AddProfilePaymentCardStatus.success;
  }

  @override
  Future<ProfileWalletTopUpStatus> topUpWallet(double amount) async {
    return ProfileWalletTopUpStatus.success;
  }

  @override
  Future<ProfileReloadPinSendStatus> sendReloadPin({
    required void Function(String verificationId) onCodeSent,
    required void Function() onVerificationCompleted,
  }) async {
    if (shouldSendCode) {
      onCodeSent('verification-1');
    }
    return sendStatus;
  }

  @override
  Future<ProfileWalletTopUpStatus> verifyReloadPinAndTopUp({
    required String verificationId,
    required String otp,
    required double amount,
  }) async {
    final verifyError = this.verifyError;
    if (verifyError != null) throw verifyError;
    receivedVerificationId = verificationId;
    receivedOtp = otp;
    receivedAmount = amount;
    return topUpStatus;
  }
}

void main() {
  group('ReloadPinViewModel', () {
    test('sends reload pin and stores verification id', () async {
      final service = FakeProfilePaymentService();
      final viewModel = ReloadPinViewModel(
        topUpAmount: 50,
        paymentService: service,
      );

      await viewModel.sendReloadPin();

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.hasVerificationId, isTrue);
      expect(viewModel.errorMessage, isNull);
    });

    test('maps send failure to friendly error', () async {
      final service = FakeProfilePaymentService()
        ..sendStatus = ProfileReloadPinSendStatus.failed
        ..shouldSendCode = false;
      final viewModel = ReloadPinViewModel(
        topUpAmount: 50,
        paymentService: service,
      );

      await viewModel.sendReloadPin();

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.hasVerificationId, isFalse);
      expect(
        viewModel.errorMessage,
        'Unable to send reload PIN. Please try again.',
      );
    });

    test('rejects empty otp before calling service', () async {
      final service = FakeProfilePaymentService();
      final viewModel = ReloadPinViewModel(
        topUpAmount: 50,
        paymentService: service,
      );

      await viewModel.sendReloadPin();
      final result = await viewModel.verifyAndTopUp(' ');

      expect(result, ReloadPinResult.emptyOtp);
      expect(viewModel.isOtpValid, isFalse);
      expect(service.receivedOtp, isNull);
    });

    test('verifies otp and tops up through service', () async {
      final service = FakeProfilePaymentService();
      final viewModel = ReloadPinViewModel(
        topUpAmount: 75.50,
        paymentService: service,
      );

      await viewModel.sendReloadPin();
      final result = await viewModel.verifyAndTopUp(' 123456 ');

      expect(result, ReloadPinResult.success);
      expect(viewModel.isLoading, isFalse);
      expect(service.receivedVerificationId, 'verification-1');
      expect(service.receivedOtp, '123456');
      expect(service.receivedAmount, 75.50);
    });

    test('maps invalid otp to friendly result', () async {
      final service = FakeProfilePaymentService()
        ..verifyError = Exception('invalid');
      final viewModel = ReloadPinViewModel(
        topUpAmount: 50,
        paymentService: service,
      );

      await viewModel.sendReloadPin();
      final result = await viewModel.verifyAndTopUp('123456');

      expect(result, ReloadPinResult.invalidOtp);
      expect(viewModel.isOtpValid, isFalse);
      expect(viewModel.errorMessage, 'Invalid Reload OTP');
    });
  });
}
