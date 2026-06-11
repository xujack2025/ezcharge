import 'dart:async';
import 'dart:io';

import 'package:ezcharge/models/emergency_request_model.dart';
import 'package:ezcharge/models/location_search_model.dart';
import 'package:ezcharge/services/emergency_request_service.dart';
import 'package:ezcharge/services/location_search_service.dart';
import 'package:ezcharge/services/location_service.dart';
import 'package:ezcharge/viewmodels/emergency_request_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class _FakeEmergencyRequestService implements EmergencyRequestServiceContract {
  _FakeEmergencyRequestService({
    this.phoneNumber = '+60123456789',
    this.customerId = 'CUS001',
  });

  final String? phoneNumber;
  final String? customerId;
  EmergencyRequest? createdRequest;

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
  Future<void> createRequest(EmergencyRequest request) async {
    createdRequest = request;
  }

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

class _FakeLocationService implements LocationServiceContract {
  _FakeLocationService({this.currentLocation});

  final LatLng? currentLocation;

  @override
  Future<LatLng?> getCurrentLocation() async {
    return currentLocation;
  }
}

class _FakeLocationSearchService implements LocationSearchServiceContract {
  _FakeLocationSearchService({
    this.suggestions = const [],
    this.selection,
    this.address,
  });

  final List<LocationSuggestion> suggestions;
  final LocationSelection? selection;
  final String? address;

  @override
  Future<List<LocationSuggestion>> fetchAddressSuggestions(String query) async {
    return suggestions;
  }

  @override
  Future<LocationSelection?> fetchPlaceDetails({
    required String placeId,
    required String description,
  }) async {
    return selection;
  }

  @override
  Future<String?> reverseGeocode(LatLng location) async {
    return address;
  }
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

    test(
      'submitEmergencyRequest creates a pending request through service',
      () async {
        final service = _FakeEmergencyRequestService();
        final viewModel = EmergencyRequestViewModel(
          emergencyRequestService: service,
        );

        final result = await viewModel.submitEmergencyRequest(
          customerId: 'CUS001',
          location: const LatLng(3.1, 101.6),
          address: 'Kuala Lumpur',
          bookingReason: 'Running Out of Charge',
        );

        expect(result, EmergencyRequestSubmitResult.success);
        expect(service.createdRequest?.customerID, 'CUS001');
        expect(service.createdRequest?.status, 'Pending');
        expect(service.createdRequest?.address, 'Kuala Lumpur');
        expect(viewModel.requestID, startsWith('EMQ'));
      },
    );

    test('submitEmergencyRequest blocks missing details', () async {
      final service = _FakeEmergencyRequestService();
      final viewModel = EmergencyRequestViewModel(
        emergencyRequestService: service,
      );

      final result = await viewModel.submitEmergencyRequest(
        customerId: 'CUS001',
        location: const LatLng(3.1, 101.6),
        address: '',
        bookingReason: null,
      );

      expect(result, EmergencyRequestSubmitResult.missingDetails);
      expect(service.createdRequest, isNull);
      expect(viewModel.errorMessage, 'Please fill in all details.');
    });

    test(
      'loadCurrentLocationSelection combines location and address services',
      () async {
        final viewModel = EmergencyRequestViewModel(
          emergencyRequestService: _FakeEmergencyRequestService(),
          locationService: _FakeLocationService(
            currentLocation: const LatLng(3.1, 101.6),
          ),
          locationSearchService: _FakeLocationSearchService(
            address: 'Kuala Lumpur',
          ),
        );

        final selection = await viewModel.loadCurrentLocationSelection();

        expect(selection?.location, const LatLng(3.1, 101.6));
        expect(selection?.address, 'Kuala Lumpur');
      },
    );

    test('address search delegates suggestions and place details', () async {
      const suggestion = LocationSuggestion(
        placeId: 'place-1',
        description: 'KLCC',
      );
      const selection = LocationSelection(
        location: LatLng(3.15, 101.71),
        address: 'KLCC',
      );
      final viewModel = EmergencyRequestViewModel(
        emergencyRequestService: _FakeEmergencyRequestService(),
        locationSearchService: _FakeLocationSearchService(
          suggestions: [suggestion],
          selection: selection,
        ),
      );

      final suggestions = await viewModel.fetchAddressSuggestions('KLCC');
      final selected = await viewModel.selectAddress(
        placeId: suggestion.placeId,
        description: suggestion.description,
      );

      expect(suggestions, [suggestion]);
      expect(selected, selection);
    });
  });
}
