import 'dart:async';

import 'package:ezcharge/models/profile_payment_card_model.dart';
import 'package:ezcharge/services/profile_payment_service.dart';
import 'package:ezcharge/viewmodels/application/payment_history_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeProfilePaymentService implements ProfilePaymentServiceContract {
  ProfilePaymentHistoryFeed? feed;
  Object? loadError;

  @override
  Future<ProfilePaymentMethodProfile?> fetchPaymentMethodProfile() async {
    return null;
  }

  @override
  Future<ProfilePaymentHistoryFeed?> watchPaymentHistory() async {
    final loadError = this.loadError;
    if (loadError != null) throw loadError;
    return feed;
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
  group('PaymentHistoryViewModel', () {
    test('loads payment history stream', () async {
      final controller = StreamController<List<ProfilePaymentHistoryItem>>();
      final service = FakeProfilePaymentService()
        ..feed = ProfilePaymentHistoryFeed(
          customerId: 'CUS1',
          items: controller.stream,
        );
      final viewModel = PaymentHistoryViewModel(paymentService: service);

      await viewModel.loadPaymentHistory();
      controller.add([
        ProfilePaymentHistoryItem(
          paymentId: 'PAY1',
          stationName: 'Station A',
          chargerName: 'Charger 1',
          chargerType: 'AC',
          duration: '30 min',
          paymentMethod: 'Wallet',
          totalCost: 12.5,
          paidTime: DateTime(2026),
        ),
      ]);
      await pumpEventQueue();

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.customerId, 'CUS1');
      expect(viewModel.items, hasLength(1));
      expect(viewModel.items.first.paymentId, 'PAY1');
      expect(viewModel.errorMessage, isNull);

      await controller.close();
      viewModel.dispose();
    });

    test('maps missing customer to friendly error', () async {
      final service = FakeProfilePaymentService();
      final viewModel = PaymentHistoryViewModel(paymentService: service);

      await viewModel.loadPaymentHistory();

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.items, isEmpty);
      expect(viewModel.errorMessage, 'No account ID found.');
    });

    test('maps stream errors to friendly error', () async {
      final controller = StreamController<List<ProfilePaymentHistoryItem>>();
      final service = FakeProfilePaymentService()
        ..feed = ProfilePaymentHistoryFeed(
          customerId: 'CUS1',
          items: controller.stream,
        );
      final viewModel = PaymentHistoryViewModel(paymentService: service);

      await viewModel.loadPaymentHistory();
      controller.addError(Exception('firestore'));
      await pumpEventQueue();

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.items, isEmpty);
      expect(viewModel.errorMessage, 'Error loading payment history.');

      await controller.close();
      viewModel.dispose();
    });

    test('maps load failure to friendly error', () async {
      final service = FakeProfilePaymentService()
        ..loadError = Exception('firestore');
      final viewModel = PaymentHistoryViewModel(paymentService: service);

      await viewModel.loadPaymentHistory();

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.items, isEmpty);
      expect(viewModel.errorMessage, 'Error loading payment history.');
    });
  });
}
