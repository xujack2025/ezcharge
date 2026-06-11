import 'package:ezcharge/models/charging_reservation_charger_model.dart';
import 'package:ezcharge/services/charging_reservation_service.dart';
import 'package:ezcharge/viewmodels/charging/charging_reservation_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeChargingReservationService
    implements ChargingReservationServiceContract {
  FakeChargingReservationService({
    this.customerId = "CUS1",
    this.chargers = const [],
    this.slotTaken = false,
  });

  String? customerId;
  List<ChargingReservationCharger> chargers;
  bool slotTaken;
  String? submittedCustomerId;
  String? submittedStationId;
  String? submittedChargerId;
  DateTime? submittedStartTime;

  @override
  Future<String?> getCurrentCustomerId() async {
    return customerId;
  }

  @override
  Future<List<ChargingReservationCharger>> fetchChargers(
    String stationId,
  ) async {
    return chargers;
  }

  @override
  Future<bool> isSlotTaken({
    required String chargerId,
    required DateTime startTime,
  }) async {
    return slotTaken;
  }

  @override
  Future<void> createReservation({
    required String customerId,
    required String stationId,
    required String chargerId,
    required DateTime startTime,
  }) async {
    submittedCustomerId = customerId;
    submittedStationId = stationId;
    submittedChargerId = chargerId;
    submittedStartTime = startTime;
  }
}

void main() {
  const charger = ChargingReservationCharger(
    id: "CHG1",
    name: "Bay 1",
    type: "Type 2",
    power: "22kW AC",
    price: "RM 1.00/kW",
    status: "Available",
  );

  group('ChargingReservationViewModel', () {
    test('loads current customer and chargers from service', () async {
      final service = FakeChargingReservationService(chargers: [charger]);
      final viewModel = ChargingReservationViewModel(
        reservationService: service,
      );

      await viewModel.load("STT1");

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.chargers, [charger]);
    });

    test('returns slotTaken when selected start time is unavailable', () async {
      final service = FakeChargingReservationService(
        chargers: [charger],
        slotTaken: true,
      );
      final viewModel = ChargingReservationViewModel(
        reservationService: service,
      );

      await viewModel.load("STT1");
      viewModel.selectCharger(charger.id);
      final result = await viewModel.selectStartTime(DateTime(2026));

      expect(result, ChargingReservationTimeResult.slotTaken);
    });

    test('submits reservation when charger and terms are selected', () async {
      final service = FakeChargingReservationService(chargers: [charger]);
      final viewModel = ChargingReservationViewModel(
        reservationService: service,
      );
      final startTime = DateTime(2026, 1, 1, 12);

      await viewModel.load("STT1");
      viewModel.selectCharger(charger.id);
      viewModel.setTermsAccepted(true);
      await viewModel.selectStartTime(startTime);
      final result = await viewModel.submitReservation("STT1");

      expect(result, ChargingReservationSubmitResult.success);
      expect(service.submittedCustomerId, "CUS1");
      expect(service.submittedStationId, "STT1");
      expect(service.submittedChargerId, charger.id);
      expect(service.submittedStartTime, startTime);
    });

    test('does not submit when customer cannot be resolved', () async {
      final service = FakeChargingReservationService(
        customerId: null,
        chargers: [charger],
      );
      final viewModel = ChargingReservationViewModel(
        reservationService: service,
      );

      await viewModel.load("STT1");
      viewModel.selectCharger(charger.id);
      viewModel.setTermsAccepted(true);
      final result = await viewModel.submitReservation("STT1");

      expect(result, ChargingReservationSubmitResult.customerNotFound);
      expect(service.submittedCustomerId, isNull);
    });
  });
}
