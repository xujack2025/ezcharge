import 'package:ezcharge/models/profile_payment_card_model.dart';
import 'package:ezcharge/services/profile_payment_service.dart';
import 'package:ezcharge/viewmodels/application/add_card_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeProfilePaymentService implements ProfilePaymentServiceContract {
  AddProfilePaymentCardStatus status = AddProfilePaymentCardStatus.success;
  Object? error;
  ProfilePaymentCardInput? receivedCard;

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
    final error = this.error;
    if (error != null) throw error;
    receivedCard = card;
    return status;
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
  group('AddCardViewModel', () {
    test('adds card through service', () async {
      final service = FakeProfilePaymentService();
      final viewModel = AddCardViewModel(paymentService: service);

      final result = await viewModel.addCard(
        cardNumber: ' 4111111111111111 ',
        expiredDate: ' 12/30 ',
        cvv: ' 123 ',
      );

      expect(result, AddCardResult.success);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNull);
      expect(service.receivedCard?.cardNumber, '4111111111111111');
      expect(service.receivedCard?.expiredDate, '12/30');
      expect(service.receivedCard?.cvv, '123');
    });

    test('does not call service when a required field is empty', () async {
      final service = FakeProfilePaymentService();
      final viewModel = AddCardViewModel(paymentService: service);

      final result = await viewModel.addCard(
        cardNumber: '',
        expiredDate: '12/30',
        cvv: '123',
      );

      expect(result, AddCardResult.emptyFields);
      expect(service.receivedCard, isNull);
      expect(viewModel.errorMessage, 'Please fill in all fields!');
    });

    test('maps missing customer to friendly result', () async {
      final service = FakeProfilePaymentService()
        ..status = AddProfilePaymentCardStatus.customerNotFound;
      final viewModel = AddCardViewModel(paymentService: service);

      final result = await viewModel.addCard(
        cardNumber: '4111111111111111',
        expiredDate: '12/30',
        cvv: '123',
      );

      expect(result, AddCardResult.customerNotFound);
      expect(viewModel.errorMessage, 'Customer profile was not found.');
    });

    test('maps duplicate card to duplicate result', () async {
      final service = FakeProfilePaymentService()
        ..status = AddProfilePaymentCardStatus.duplicate;
      final viewModel = AddCardViewModel(paymentService: service);

      final result = await viewModel.addCard(
        cardNumber: '4111111111111111',
        expiredDate: '12/30',
        cvv: '123',
      );

      expect(result, AddCardResult.duplicate);
      expect(viewModel.errorMessage, 'This card is already registered!');
    });

    test('maps service failure to friendly result', () async {
      final service = FakeProfilePaymentService()
        ..error = Exception('firestore');
      final viewModel = AddCardViewModel(paymentService: service);

      final result = await viewModel.addCard(
        cardNumber: '4111111111111111',
        expiredDate: '12/30',
        cvv: '123',
      );

      expect(result, AddCardResult.failed);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, 'Failed to add card. Try again!');
    });
  });
}
