import 'dart:async';
import 'dart:io';

import 'package:ezcharge/models/emergency_request_model.dart';
import 'package:ezcharge/services/emergency_request_service.dart';
import 'package:ezcharge/viewmodels/emergency_request_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeEmergencyRequestService implements EmergencyRequestServiceContract {
  _FakeEmergencyRequestService({
    this.phoneNumber = '+60123456789',
    this.customerId = 'CUS001',
  });

  final String? phoneNumber;
  final String? customerId;

  @override
  String? getCurrentUserPhoneNumber() => phoneNumber;

  @override
  Future<String?> getCustomerIdByPhoneNumber(String phoneNumber) async {
    return customerId;
  }

  @override
  Stream<ActiveEmergencyRequest> watchActiveRequest(String customerId) {
    return const Stream.empty();
  }

  @override
  Stream<List<EmergencyRequest>> watchRequests(String customerId) {
    return const Stream.empty();
  }

  @override
  Future<void> createRequest(EmergencyRequest request) async {}

  @override
  Future<void> updateRequestStatus(String requestID, String status) async {}

  @override
  Future<String> uploadRequestImage(File image) async => '';

  @override
  Future<String> getPowerBankImageUrl() async => '';

  @override
  Future<String?> getDriverId(String requestId) async => null;

  @override
  Stream<String?> watchDriverId(String requestId) {
    return const Stream.empty();
  }

  @override
  Future<void> startCharging(String requestID) async {}

  @override
  Future<void> updateChargingComplete(String requestID, double kWhUsed) async {}

  @override
  Future<void> processPayment(String requestID) async {}
}

void main() {
  group('EmergencyRequestViewModel', () {
    test('loadCurrentCustomerId resolves customer id from service', () async {
      final viewModel = EmergencyRequestViewModel(
        emergencyRequestService: _FakeEmergencyRequestService(),
      );

      await viewModel.loadCurrentCustomerId();

      expect(viewModel.customerId, 'CUS001');
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.isLoading, isFalse);
    });

    test(
      'loadCurrentCustomerId exposes friendly error when no phone exists',
      () async {
        final viewModel = EmergencyRequestViewModel(
          emergencyRequestService: _FakeEmergencyRequestService(
            phoneNumber: null,
          ),
        );

        await viewModel.loadCurrentCustomerId();

        expect(viewModel.customerId, isNull);
        expect(viewModel.errorMessage, 'No customer profile was found.');
        expect(viewModel.isLoading, isFalse);
      },
    );

    test(
      'loadCurrentCustomerId exposes friendly error when customer is missing',
      () async {
        final viewModel = EmergencyRequestViewModel(
          emergencyRequestService: _FakeEmergencyRequestService(
            customerId: null,
          ),
        );

        await viewModel.loadCurrentCustomerId();

        expect(viewModel.customerId, isNull);
        expect(viewModel.errorMessage, 'No customer profile was found.');
        expect(viewModel.isLoading, isFalse);
      },
    );
  });
}
