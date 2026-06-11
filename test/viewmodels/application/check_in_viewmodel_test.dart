import 'package:ezcharge/models/charging_checkout_model.dart';
import 'package:ezcharge/services/check_in_service.dart';
import 'package:ezcharge/viewmodels/application/check_in_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeCheckInService implements CheckInServiceContract {
  FakeCheckInService({
    this.phoneNumber = "+60123456789",
    this.customerId = "CUS1",
    this.reservationStatus = "Upcoming",
    this.details,
  });

  final String? phoneNumber;
  final String? customerId;
  final String reservationStatus;
  final ChargingCheckInDetails? details;
  ChargingCheckInDetails? checkedInDetails;

  @override
  String? getCurrentUserPhoneNumber() {
    return phoneNumber;
  }

  @override
  Future<String?> getCustomerIdByPhoneNumber(String phoneNumber) async {
    return customerId;
  }

  @override
  Future<String> getReservationStatus(String customerId) async {
    return reservationStatus;
  }

  @override
  Future<ChargingCheckInDetails?> fetchCheckInDetails() async {
    return details;
  }

  @override
  Future<void> checkIn(ChargingCheckInDetails details) async {
    checkedInDetails = details;
  }
}

void main() {
  group('CheckInViewModel', () {
    test('loads customer reservation status from service', () async {
      final viewModel = CheckInViewModel(
        checkInService: FakeCheckInService(reservationStatus: "Upcoming"),
      );

      await viewModel.loadReservationStatus();

      expect(viewModel.customerId, "CUS1");
      expect(viewModel.reservationStatus, "Upcoming");
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNull);
    });

    test('falls back to ended when no customer can be resolved', () async {
      final viewModel = CheckInViewModel(
        checkInService: FakeCheckInService(customerId: null),
      );

      await viewModel.loadReservationStatus();

      expect(viewModel.reservationStatus, "Ended");
      expect(viewModel.isLoading, isFalse);
    });

    test('resolves scan results from reservation status', () async {
      final upcomingViewModel = CheckInViewModel(
        checkInService: FakeCheckInService(reservationStatus: "Upcoming"),
      );
      final activeViewModel = CheckInViewModel(
        checkInService: FakeCheckInService(reservationStatus: "Active"),
      );
      final endedViewModel = CheckInViewModel(
        checkInService: FakeCheckInService(reservationStatus: "Ended"),
      );

      await upcomingViewModel.loadReservationStatus();
      await activeViewModel.loadReservationStatus();
      await endedViewModel.loadReservationStatus();

      expect(
        upcomingViewModel.resolveScan("qr-data"),
        CheckInScanResult.upcoming,
      );
      expect(activeViewModel.resolveScan("qr-data"), CheckInScanResult.active);
      expect(
        endedViewModel.resolveScan("qr-data"),
        CheckInScanResult.unavailable,
      );
      expect(upcomingViewModel.resolveScan(""), CheckInScanResult.empty);
    });

    test(
      'loads check-in details and submits when reservation is ready',
      () async {
        final details = ChargingCheckInDetails(
          customerId: "CUS1",
          chargerId: "CHG1",
          stationId: "ST1",
          reservationStatus: "Upcoming",
          stationName: "EzCharge KL",
          chargerName: "Bay 1",
          chargerType: "DC",
          pricePerVoltage: 1.2,
          startTime: DateTime.now().subtract(const Duration(minutes: 5)),
        );
        final service = FakeCheckInService(details: details);
        final viewModel = CheckInViewModel(checkInService: service);

        await viewModel.loadCheckInDetails();
        final result = await viewModel.submitCheckIn();

        expect(viewModel.checkInDetails, details);
        expect(result, CheckInSubmitResult.success);
        expect(service.checkedInDetails, details);
        expect(viewModel.reservationStatus, "Active");
      },
    );

    test('blocks check-in before reserved start time', () async {
      final details = ChargingCheckInDetails(
        customerId: "CUS1",
        chargerId: "CHG1",
        stationId: "ST1",
        reservationStatus: "Upcoming",
        stationName: "EzCharge KL",
        chargerName: "Bay 1",
        chargerType: "DC",
        pricePerVoltage: 1.2,
        startTime: DateTime.now().add(const Duration(minutes: 5)),
      );
      final service = FakeCheckInService(details: details);
      final viewModel = CheckInViewModel(checkInService: service);

      await viewModel.loadCheckInDetails();
      final result = await viewModel.submitCheckIn();

      expect(result, CheckInSubmitResult.notReady);
      expect(service.checkedInDetails, isNull);
      expect(viewModel.errorMessage, "Now isn't your check-in time!");
    });
  });
}
