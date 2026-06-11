import 'package:ezcharge/models/charging_checkout_model.dart';
import 'package:ezcharge/services/charging_checkout_service.dart';
import 'package:ezcharge/viewmodels/charging/charging_checkout_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeChargingCheckoutService service;
  late ChargingCheckoutViewModel viewModel;

  final details = ChargingCheckoutDetails(
    customerId: 'CUS001',
    chargerId: 'CH001',
    stationId: 'ST001',
    reservationId: 'RSV001',
    reservationStatus: 'Ended',
    stationName: 'EzCharge KL',
    chargerName: 'Bay 1',
    chargerType: 'DC',
    currentType: 'Fast',
    chargerVoltage: 10,
    pricePerVoltage: 2,
    startTime: DateTime(2026, 1, 1, 10),
  );

  setUp(() {
    service = _FakeChargingCheckoutService();
    viewModel = ChargingCheckoutViewModel(checkoutService: service);
  });

  tearDown(() {
    viewModel.dispose();
  });

  test('load exposes checkout details', () async {
    service.details = details;

    await viewModel.load();

    expect(viewModel.stationName, 'EzCharge KL');
    expect(viewModel.chargerName, 'Bay 1');
    expect(viewModel.chargerType, 'DC');
    expect(viewModel.errorMessage, isNull);
  });

  test('chargingCostFor calculates duration by price and voltage', () async {
    service.details = details;
    await viewModel.load();

    final total = viewModel.chargingCostFor(const Duration(minutes: 30));

    expect(total, 10);
  });

  test('checkOut creates attendance when reservation is ended', () async {
    service.details = details;
    await viewModel.load();

    final result = await viewModel.checkOut(
      duration: const Duration(minutes: 30),
      durationText: '00:30:00',
      penaltyCost: 5,
    );

    expect(result, ChargingCheckoutResult.success);
    expect(service.createdAttendance, isTrue);
    expect(service.receivedChargingCost, 10);
    expect(service.receivedPenaltyCost, 5);
  });

  test('checkOut rejects reservation that is not ended', () async {
    service.details = ChargingCheckoutDetails(
      customerId: 'CUS001',
      chargerId: 'CH001',
      stationId: 'ST001',
      reservationId: 'RSV001',
      reservationStatus: 'Charging',
      stationName: 'EzCharge KL',
      chargerName: 'Bay 1',
      chargerType: 'DC',
      currentType: 'Fast',
      chargerVoltage: 10,
      pricePerVoltage: 2,
      startTime: DateTime(2026, 1, 1, 10),
    );
    await viewModel.load();

    final result = await viewModel.checkOut(
      duration: const Duration(minutes: 30),
      durationText: '00:30:00',
      penaltyCost: 0,
    );

    expect(result, ChargingCheckoutResult.notEnded);
    expect(service.createdAttendance, isFalse);
  });
}

class _FakeChargingCheckoutService implements ChargingCheckoutServiceContract {
  ChargingCheckoutDetails? details;
  bool createdAttendance = false;
  double? receivedChargingCost;
  double? receivedPenaltyCost;

  @override
  Future<ChargingCheckoutDetails?> fetchCheckoutDetails() async {
    return details;
  }

  @override
  Future<void> createAttendanceRecord({
    required ChargingCheckoutDetails details,
    required String duration,
    required double chargingCost,
    required double penaltyCost,
    DateTime? checkedOutAt,
  }) async {
    createdAttendance = true;
    receivedChargingCost = chargingCost;
    receivedPenaltyCost = penaltyCost;
  }
}
