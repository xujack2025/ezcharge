import 'package:ezcharge/models/emergency_payment_model.dart';
import 'package:ezcharge/services/payment_service.dart';
import 'package:ezcharge/viewmodels/emergency_payment_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeEmergencyPaymentService implements EmergencyPaymentServiceContract {
  EmergencyPaymentProfile? profile;
  EmergencyPaymentSuccessDetails? successDetails;
  EmergencyPaymentHistoryDetail? historyDetail;
  EmergencyPaymentProcessResult processResult =
      const EmergencyPaymentProcessResult(
        status: EmergencyPaymentProcessStatus.success,
        paymentMethodLabel: 'Credit Card',
        walletBalance: 0,
      );
  String createdPaymentId = 'PAY001';

  EmergencyPaymentMethod? receivedMethod;
  String? receivedRewardId;
  String? receivedPaymentMethod;
  String? receivedAccountId;
  String? receivedPaymentId;
  double? receivedTotalAmount;

  @override
  Future<EmergencyPaymentProfile?> fetchPaymentProfile() async {
    return profile;
  }

  @override
  Future<EmergencyPaymentProcessResult> processPayment({
    required String customerId,
    required double totalAmount,
    required EmergencyPaymentMethod method,
    required String rewardId,
    required int rewardPoints,
  }) async {
    receivedMethod = method;
    receivedRewardId = rewardId;
    receivedTotalAmount = totalAmount;
    return processResult;
  }

  @override
  Future<EmergencyPaymentSuccessDetails?> fetchSuccessDetails() async {
    return successDetails;
  }

  @override
  Future<String> createPaymentHistoryRecord({
    required EmergencyPaymentSuccessDetails details,
    required String paymentMethod,
    required double totalAmount,
    DateTime? paidAt,
  }) async {
    receivedPaymentMethod = paymentMethod;
    receivedTotalAmount = totalAmount;
    return createdPaymentId;
  }

  @override
  Future<EmergencyPaymentHistoryDetail?> fetchPaymentHistoryDetail({
    required String accountId,
    required String paymentId,
  }) async {
    receivedAccountId = accountId;
    receivedPaymentId = paymentId;
    return historyDetail;
  }
}

void main() {
  late _FakeEmergencyPaymentService service;
  late EmergencyPaymentViewModel viewModel;

  const profile = EmergencyPaymentProfile(
    customerId: 'CUS001',
    walletBalance: 100,
    pointBalance: 300,
    cardNumber: '4111111111111234',
  );

  const successDetails = EmergencyPaymentSuccessDetails(
    customerId: 'CUS001',
    requestId: 'EMQ001',
    duration: '00:30:00',
  );

  final historyDetail = EmergencyPaymentHistoryDetail(
    totalCost: 20,
    duration: '00:30:00',
    paymentMethod: 'Credit Card',
    paymentId: 'PAY001',
    paidTime: DateTime(2026),
  );

  setUp(() {
    service = _FakeEmergencyPaymentService();
    viewModel = EmergencyPaymentViewModel(paymentService: service);
  });

  tearDown(() {
    viewModel.dispose();
  });

  test('loadPaymentProfile exposes wallet and card state', () async {
    service.profile = profile;

    await viewModel.loadPaymentProfile();

    expect(viewModel.walletBalance, 100);
    expect(viewModel.cardNumber, '4111111111111234');
    expect(viewModel.errorMessage, isNull);
  });

  test('wallet payment updates wallet balance through service', () async {
    service.profile = profile;
    service.processResult = const EmergencyPaymentProcessResult(
      status: EmergencyPaymentProcessStatus.success,
      paymentMethodLabel: 'EZCHARGE Wallet',
      walletBalance: 80,
    );
    await viewModel.loadPaymentProfile();
    viewModel.selectPaymentMethod(EmergencyPaymentMethod.wallet);

    final result = await viewModel.processPayment(
      totalAmount: 20,
      rewardId: 'RWD001',
      rewardPoints: 100,
    );

    expect(result, EmergencyPaymentResult.success);
    expect(viewModel.walletBalance, 80);
    expect(service.receivedMethod, EmergencyPaymentMethod.wallet);
    expect(service.receivedRewardId, 'RWD001');
  });

  test('wallet payment returns insufficient balance', () async {
    service.profile = profile;
    service.processResult = const EmergencyPaymentProcessResult(
      status: EmergencyPaymentProcessStatus.insufficientBalance,
      paymentMethodLabel: '',
      walletBalance: 15,
    );
    await viewModel.loadPaymentProfile();
    viewModel.selectPaymentMethod(EmergencyPaymentMethod.wallet);

    final result = await viewModel.processPayment(
      totalAmount: 20,
      rewardId: '',
      rewardPoints: 0,
    );

    expect(result, EmergencyPaymentResult.insufficientBalance);
    expect(viewModel.walletBalance, 15);
  });

  test('createPaymentHistory delegates to service', () async {
    service.successDetails = successDetails;
    await viewModel.loadSuccessDetails();

    final (result, paymentId) = await viewModel.createPaymentHistory(
      paymentMethod: 'Credit Card',
      totalAmount: 20,
    );

    expect(result, EmergencyPaymentHistoryResult.success);
    expect(paymentId, 'PAY001');
    expect(service.receivedPaymentMethod, 'Credit Card');
    expect(service.receivedTotalAmount, 20);
  });

  test('loadPaymentHistoryDetail exposes receipt state', () async {
    service.historyDetail = historyDetail;

    await viewModel.loadPaymentHistoryDetail(
      accountId: 'CUS001',
      paymentId: 'PAY001',
    );

    expect(viewModel.historyDetail, historyDetail);
    expect(service.receivedAccountId, 'CUS001');
    expect(service.receivedPaymentId, 'PAY001');
    expect(viewModel.errorMessage, isNull);
  });
}
