import 'dart:async';

import 'package:ezcharge/models/charging_reservation_charger_model.dart';
import 'package:ezcharge/models/charging_station_detail_model.dart';
import 'package:ezcharge/services/charging_station_detail_service.dart';
import 'package:ezcharge/viewmodels/charging/charging_station_detail_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeChargingStationDetailService service;
  late ChargingStationDetailViewModel viewModel;

  const station = ChargingStationDetail(
    stationId: "ST001",
    stationName: "EzCharge KL",
    description: "Near lobby",
    location: "Kuala Lumpur",
    latitude: "3.1390",
    longitude: "101.6869",
    imageUrl: "https://example.com/station.jpg",
    capacity: 2,
  );

  const charger = ChargingReservationCharger(
    id: "CH001",
    name: "Bay 1",
    type: "DC",
    power: "120kW DC",
    price: "RM 1.20/kW",
    status: "Available",
  );

  setUp(() {
    service = _FakeChargingStationDetailService();
    viewModel = ChargingStationDetailViewModel(stationDetailService: service);
  });

  tearDown(() async {
    viewModel.dispose();
    await service.dispose();
  });

  test("load fetches station, chargers, reviews, and access", () async {
    service.detail = const ChargingStationDetailData(
      station: station,
      chargers: [charger],
    );
    service.reviews = [
      ChargingStationReview(
        rating: 4,
        reviewText: "Fast charger",
        reviewerLabel: "Tesla Model 3",
        reviewDate: DateTime(2026, 6, 10),
      ),
    ];
    service.access = const ChargingStationAccess(
      customerId: "CUS001",
      authenticationStatus: "Pass",
      reservationStatus: "",
    );

    await viewModel.load("ST001");

    expect(viewModel.station?.stationName, "EzCharge KL");
    expect(viewModel.chargers, [charger]);
    expect(viewModel.reviews.single.reviewText, "Fast charger");
    expect(viewModel.canReserve, isTrue);
    expect(viewModel.errorMessage, isNull);
  });

  test("busy times stream exposes no data state", () async {
    await viewModel.load("ST001");

    service.emitCheckIns([]);
    await pumpEventQueue();

    expect(viewModel.trafficStatus, "No data available");
    expect(viewModel.busyTimes, everyElement(0.2));
  });

  test("reserve intent requires authentication before navigation", () async {
    service.access = const ChargingStationAccess(
      customerId: "CUS001",
      authenticationStatus: "",
      reservationStatus: "",
    );

    await viewModel.load("ST001");

    expect(
      viewModel.getReserveIntent(),
      ChargingStationReserveIntent.authenticationRequired,
    );
  });

  test("reserve intent blocks existing upcoming reservation", () async {
    service.access = const ChargingStationAccess(
      customerId: "CUS001",
      authenticationStatus: "Pass",
      reservationStatus: "Upcoming",
    );

    await viewModel.load("ST001");

    expect(
      viewModel.getReserveIntent(),
      ChargingStationReserveIntent.existingReservation,
    );
  });

  test("load handles missing station", () async {
    service.detail = null;

    await viewModel.load("ST404");

    expect(viewModel.station, isNull);
    expect(viewModel.errorMessage, "Station not found.");
  });
}

class _FakeChargingStationDetailService
    implements ChargingStationDetailServiceContract {
  ChargingStationDetailData? detail = const ChargingStationDetailData(
    station: ChargingStationDetail(
      stationId: "ST001",
      stationName: "EzCharge KL",
      description: "Near lobby",
      location: "Kuala Lumpur",
      latitude: "3.1390",
      longitude: "101.6869",
      imageUrl: "https://example.com/station.jpg",
      capacity: 2,
    ),
    chargers: [],
  );
  List<ChargingStationReview> reviews = [];
  ChargingStationAccess access = const ChargingStationAccess(
    customerId: "CUS001",
    authenticationStatus: "Pass",
    reservationStatus: "",
  );

  final StreamController<List<DateTime>> _checkInsController =
      StreamController<List<DateTime>>.broadcast();

  @override
  Future<ChargingStationDetailData?> fetchStationDetail(
    String stationId,
  ) async {
    return detail;
  }

  @override
  Future<List<ChargingStationReview>> fetchReviews(String stationId) async {
    return reviews;
  }

  @override
  Future<ChargingStationAccess> fetchReservationAccess() async {
    return access;
  }

  @override
  Stream<List<DateTime>> watchAttendanceCheckIns(String stationId) {
    return _checkInsController.stream;
  }

  void emitCheckIns(List<DateTime> checkIns) {
    _checkInsController.add(checkIns);
  }

  Future<void> dispose() async {
    await _checkInsController.close();
  }
}
