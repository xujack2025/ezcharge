import 'package:ezcharge/models/charging_session_model.dart';
import 'package:ezcharge/services/charging_session_service.dart';
import 'package:ezcharge/viewmodels/charging/charging_session_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeChargingSessionService service;
  late ChargingSessionViewModel viewModel;

  const session = ChargingSessionInfo(
    customerId: "CUS001",
    stationId: "ST001",
    chargerId: "CH001",
    stationName: "EzCharge KL",
    chargerName: "Bay 1",
    chargerType: "DC",
  );

  setUp(() {
    service = _FakeChargingSessionService();
    viewModel = ChargingSessionViewModel(sessionService: service);
  });

  tearDown(() {
    viewModel.dispose();
  });

  test("load exposes current charging session", () async {
    service.session = session;

    await viewModel.load();

    expect(viewModel.stationName, "EzCharge KL");
    expect(viewModel.chargerName, "Bay 1");
    expect(viewModel.chargerType, "DC");
    expect(viewModel.errorMessage, isNull);
  });

  test("endSession updates reservation through service", () async {
    service.session = session;
    await viewModel.load();

    final result = await viewModel.endSession();

    expect(result, ChargingSessionEndResult.success);
    expect(service.endedCustomerIds, ["CUS001"]);
  });

  test(
    "endSession returns noSession when customer cannot be resolved",
    () async {
      service.session = null;
      await viewModel.load();

      final result = await viewModel.endSession();

      expect(result, ChargingSessionEndResult.noSession);
      expect(service.endedCustomerIds, isEmpty);
    },
  );

  test("endSession exposes failure when service throws", () async {
    service.session = session;
    service.throwOnEnd = true;
    await viewModel.load();

    final result = await viewModel.endSession();

    expect(result, ChargingSessionEndResult.failed);
    expect(viewModel.errorMessage, "Failed to end charging session.");
  });
}

class _FakeChargingSessionService implements ChargingSessionServiceContract {
  ChargingSessionInfo? session;
  bool throwOnEnd = false;
  final List<String> endedCustomerIds = [];

  @override
  Future<ChargingSessionInfo?> fetchCurrentSession() async {
    return session;
  }

  @override
  Future<void> endReservation(String customerId) async {
    if (throwOnEnd) {
      throw Exception("end failed");
    }

    endedCustomerIds.add(customerId);
  }
}
