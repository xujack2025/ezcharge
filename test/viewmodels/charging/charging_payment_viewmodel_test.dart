import 'package:ezcharge/models/charging_checkout_model.dart';
import 'package:ezcharge/services/payment_service.dart';
import 'package:ezcharge/viewmodels/charging/charging_payment_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeChargingPaymentService service;
  late ChargingPaymentViewModel viewModel;

  const profile = ChargingPaymentProfile(
    customerId: 'CUS001',
    walletBalance: 100,
    pointBalance: 300,
    cardNumber: '4111111111111234',
  );

  const historyDetails = ChargingPaymentHistoryDetails(
    customerId: 'CUS001',
    duration: '00:30:00',
    stationName: 'EzCharge KL',
    chargerName: 'Bay 1',
    chargerType: 'DC',
  );

  final historyDetail = ChargingPaymentHistoryDetail(
    totalCost: 20,
    stationName: 'EzCharge KL',
    chargerName: 'Bay 1',
    chargerType: 'DC',
    duration: '00:30:00',
    paymentMethod: 'Credit Card',
    paymentId: 'PAY001',
    paidTime: DateTime(2026),
  );

  setUp(() {
    service = _FakeChargingPaymentService();
    viewModel = ChargingPaymentViewModel(paymentService: service);
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

  test('totalAfterDiscount clamps negative totals to zero', () {
    final total = viewModel.totalAfterDiscount(
      chargingCost: 10,
      penaltyCost: 5,
      rewardDiscount: 50,
    );

    expect(total, 0);
  });

  test('wallet payment updates wallet balance through service', () async {
    service.profile = profile;
    service.processResult = const ChargingPaymentProcessResult(
      status: ChargingPaymentProcessStatus.success,
      paymentMethodLabel: 'EZCHARGE Wallet',
      walletBalance: 80,
    );
    await viewModel.loadPaymentProfile();
    viewModel.selectPaymentMethod(ChargingPaymentMethod.wallet);

    final result = await viewModel.processPayment(
      totalAmount: 20,
      rewardId: 'RWD001',
      rewardPoints: 100,
    );

    expect(result, ChargingPaymentResult.success);
    expect(viewModel.walletBalance, 80);
    expect(service.receivedMethod, ChargingPaymentMethod.wallet);
    expect(service.receivedRewardId, 'RWD001');
  });

  test(
    'wallet payment returns insufficient balance without success state',
    () async {
      service.profile = profile;
      service.processResult = const ChargingPaymentProcessResult(
        status: ChargingPaymentProcessStatus.insufficientBalance,
        paymentMethodLabel: '',
        walletBalance: 15,
      );
      await viewModel.loadPaymentProfile();
      viewModel.selectPaymentMethod(ChargingPaymentMethod.wallet);

      final result = await viewModel.processPayment(
        totalAmount: 20,
        rewardId: '',
        rewardPoints: 0,
      );

      expect(result, ChargingPaymentResult.insufficientBalance);
      expect(viewModel.walletBalance, 15);
    },
  );

  test('createPaymentHistory delegates to service', () async {
    service.historyDetails = historyDetails;
    service.createdPaymentId = 'PAY001';
    await viewModel.loadPaymentHistoryDetails();

    final (result, paymentId) = await viewModel.createPaymentHistory(
      paymentMethod: 'Credit Card',
      totalAmount: 20,
    );

    expect(result, ChargingPaymentHistoryResult.success);
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

class _FakeChargingPaymentService implements ChargingPaymentServiceContract {
  ChargingPaymentSummaryDetails? summaryDetails;
  ChargingPaymentProfile? profile;
  ChargingPaymentHistoryDetails? historyDetails;
  ChargingPaymentHistoryDetail? historyDetail;
  ChargingPaymentProcessResult processResult =
      const ChargingPaymentProcessResult(
        status: ChargingPaymentProcessStatus.success,
        paymentMethodLabel: 'Credit Card',
        walletBalance: 0,
      );
  String createdPaymentId = 'PAY123';

  ChargingPaymentMethod? receivedMethod;
  String? receivedRewardId;
  String? receivedPaymentMethod;
  String? receivedAccountId;
  String? receivedPaymentId;
  double? receivedTotalAmount;

  @override
  Future<ChargingPaymentSummaryDetails?> fetchPaymentSummaryDetails() async {
    return summaryDetails;
  }

  @override
  Future<ChargingPaymentProfile?> fetchPaymentProfile() async {
    return profile;
  }

  @override
  Future<ChargingPaymentProcessResult> processPayment({
    required String customerId,
    required double totalAmount,
    required ChargingPaymentMethod method,
    required String rewardId,
    required int rewardPoints,
  }) async {
    receivedMethod = method;
    receivedRewardId = rewardId;
    return processResult;
  }

  @override
  Future<ChargingPaymentHistoryDetails?> fetchPaymentHistoryDetails() async {
    return historyDetails;
  }

  @override
  Future<ChargingPaymentHistoryDetail?> fetchPaymentHistoryDetail({
    required String accountId,
    required String paymentId,
  }) async {
    receivedAccountId = accountId;
    receivedPaymentId = paymentId;
    return historyDetail;
  }

  @override
  Future<String> createPaymentHistoryRecord({
    required ChargingPaymentHistoryDetails details,
    required String paymentMethod,
    required double totalAmount,
    DateTime? paidAt,
  }) async {
    receivedPaymentMethod = paymentMethod;
    receivedTotalAmount = totalAmount;
    return createdPaymentId;
  }
}
