import 'package:ezcharge/models/profile_payment_card_model.dart';
import 'package:ezcharge/services/profile_payment_service.dart';
import 'package:ezcharge/viewmodels/application/top_up_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeProfilePaymentService implements ProfilePaymentServiceContract {
  ProfilePaymentMethodProfile? profile;
  Object? loadError;
  Object? topUpError;
  ProfileWalletTopUpStatus topUpStatus = ProfileWalletTopUpStatus.success;
  double? receivedTopUpAmount;

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
    final topUpError = this.topUpError;
    if (topUpError != null) throw topUpError;
    receivedTopUpAmount = amount;
    return topUpStatus;
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
  group('TopUpViewModel', () {
    test('loads wallet balance and card number', () async {
      final service = FakeProfilePaymentService()
        ..profile = const ProfilePaymentMethodProfile(
          customerId: 'CUS1',
          walletBalance: 45.25,
          cardNumber: '4111111111111111',
        );
      final viewModel = TopUpViewModel(paymentService: service);

      await viewModel.loadTopUpProfile();

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.walletBalance, 45.25);
      expect(viewModel.cardNumber, '4111111111111111');
      expect(viewModel.hasCard, isTrue);
    });

    test('maps missing profile to friendly error', () async {
      final service = FakeProfilePaymentService();
      final viewModel = TopUpViewModel(paymentService: service);

      await viewModel.loadTopUpProfile();

      expect(viewModel.profile, isNull);
      expect(viewModel.errorMessage, 'Customer payment profile was not found.');
    });

    test('maps load failure to friendly error', () async {
      final service = FakeProfilePaymentService()
        ..loadError = Exception('firestore');
      final viewModel = TopUpViewModel(paymentService: service);

      await viewModel.loadTopUpProfile();

      expect(viewModel.profile, isNull);
      expect(
        viewModel.errorMessage,
        'Unable to load top-up details. Please try again.',
      );
    });

    test('selects quick amount and card method', () async {
      final service = FakeProfilePaymentService()
        ..profile = const ProfilePaymentMethodProfile(
          customerId: 'CUS1',
          walletBalance: 10,
          cardNumber: '4111111111111111',
        );
      final viewModel = TopUpViewModel(paymentService: service);

      await viewModel.loadTopUpProfile();
      viewModel.selectQuickAmount(100);
      viewModel.selectPaymentMethod(TopUpPaymentMethod.card);

      expect(viewModel.amountText, '100');
      expect(viewModel.selectedAmount, 100);
      expect(viewModel.isCardSelected, isTrue);
      expect(viewModel.canSubmit, isTrue);
    });

    test('does not select card method without a saved card', () async {
      final service = FakeProfilePaymentService()
        ..profile = const ProfilePaymentMethodProfile(
          customerId: 'CUS1',
          walletBalance: 10,
        );
      final viewModel = TopUpViewModel(paymentService: service);

      await viewModel.loadTopUpProfile();
      viewModel.selectPaymentMethod(TopUpPaymentMethod.card);

      expect(viewModel.selectedPaymentMethod, isNull);
    });

    test('does not call service when amount is invalid', () async {
      final service = FakeProfilePaymentService();
      final viewModel = TopUpViewModel(paymentService: service)
        ..setAmountText('0')
        ..selectPaymentMethod(TopUpPaymentMethod.reloadPin);

      final result = await viewModel.topUpWithCard();

      expect(result, TopUpResult.invalidAmount);
      expect(service.receivedTopUpAmount, isNull);
      expect(viewModel.errorMessage, 'Enter a valid top-up amount.');
    });

    test('tops up wallet through service', () async {
      final service = FakeProfilePaymentService();
      final viewModel = TopUpViewModel(paymentService: service)
        ..setAmountText('75.50');

      final result = await viewModel.topUpWithCard();

      expect(result, TopUpResult.success);
      expect(viewModel.isProcessingTopUp, isFalse);
      expect(viewModel.errorMessage, isNull);
      expect(service.receivedTopUpAmount, 75.50);
    });

    test('maps missing customer during top-up to friendly result', () async {
      final service = FakeProfilePaymentService()
        ..topUpStatus = ProfileWalletTopUpStatus.customerNotFound;
      final viewModel = TopUpViewModel(paymentService: service)
        ..setAmountText('50');

      final result = await viewModel.topUpWithCard();

      expect(result, TopUpResult.customerNotFound);
      expect(viewModel.errorMessage, 'Customer payment profile was not found.');
    });

    test('maps top-up failure to friendly result', () async {
      final service = FakeProfilePaymentService()
        ..topUpError = Exception('firestore');
      final viewModel = TopUpViewModel(paymentService: service)
        ..setAmountText('50');

      final result = await viewModel.topUpWithCard();

      expect(result, TopUpResult.failed);
      expect(viewModel.isProcessingTopUp, isFalse);
      expect(
        viewModel.errorMessage,
        'Unable to update wallet. Please try again.',
      );
    });
  });
}
