import 'package:ezcharge/models/profile_payment_card_model.dart';
import 'package:ezcharge/services/profile_payment_service.dart';
import 'package:ezcharge/viewmodels/application/payment_method_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeProfilePaymentService implements ProfilePaymentServiceContract {
  ProfilePaymentMethodProfile? profile;
  Object? loadError;

  @override
  Future<ProfilePaymentMethodProfile?> fetchPaymentMethodProfile() async {
    final loadError = this.loadError;
    if (loadError != null) throw loadError;
    return profile;
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
    return ProfileReloadPinSendStatus.sent;
  }

  @override
  Future<ProfileWalletTopUpStatus> verifyReloadPinAndTopUp({
    required String verificationId,
    required String otp,
    required double amount,
  }) async {
    return ProfileWalletTopUpStatus.success;
  }
}

void main() {
  group('PaymentMethodViewModel', () {
    test('loads wallet balance and card number', () async {
      final service = FakeProfilePaymentService()
        ..profile = const ProfilePaymentMethodProfile(
          customerId: 'CUS1',
          walletBalance: 88.50,
          cardNumber: '4111111111111111',
        );
      final viewModel = PaymentMethodViewModel(paymentService: service);

      await viewModel.loadPaymentMethodProfile();

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.walletBalance, 88.50);
      expect(viewModel.cardNumber, '4111111111111111');
    });

    test('exposes friendly error when profile is missing', () async {
      final service = FakeProfilePaymentService();
      final viewModel = PaymentMethodViewModel(paymentService: service);

      await viewModel.loadPaymentMethodProfile();

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.profile, isNull);
      expect(viewModel.walletBalance, 0);
      expect(viewModel.cardNumber, isEmpty);
      expect(viewModel.errorMessage, 'Customer payment profile was not found.');
    });

    test('maps service failure to friendly error', () async {
      final service = FakeProfilePaymentService()
        ..loadError = Exception('firestore');
      final viewModel = PaymentMethodViewModel(paymentService: service);

      await viewModel.loadPaymentMethodProfile();

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.profile, isNull);
      expect(
        viewModel.errorMessage,
        'Unable to load payment methods. Please try again.',
      );
    });
  });
}
