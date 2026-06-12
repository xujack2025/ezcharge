import 'dart:io';

import 'package:ezcharge/models/profile_account_model.dart';
import 'package:ezcharge/services/profile_account_service.dart';
import 'package:ezcharge/viewmodels/application/delete_account_viewmodel.dart';
import 'package:ezcharge/viewmodels/application/profile_activity_viewmodel.dart';
import 'package:ezcharge/viewmodels/application/profile_authentication_viewmodel.dart';
import 'package:ezcharge/viewmodels/application/profile_bookmark_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeProfileAccountService implements ProfileAccountServiceContract {
  String? customerId = 'CUS1';
  Object? error;
  List<ProfileBookmarkStation> bookmarks = const [];
  ProfileActivityData? activity;
  ProfileDeleteAccountStatus deleteStatus = ProfileDeleteAccountStatus.success;
  ProfileAuthenticationImageType? uploadedImageType;
  File? uploadedImage;
  bool didSubmitAuthentication = false;
  String? removedBookmarkId;
  bool didCancelReservation = false;

  @override
  Future<String?> getCurrentCustomerId() async {
    return customerId;
  }

  @override
  Future<ProfileAuthenticationUpload> uploadAuthenticationImage({
    required ProfileAuthenticationImageType type,
    required File image,
  }) async {
    final error = this.error;
    if (error != null) throw error;
    uploadedImageType = type;
    uploadedImage = image;
    return const ProfileAuthenticationUpload(downloadUrl: 'https://image');
  }

  @override
  Future<void> submitAuthenticationRequest() async {
    final error = this.error;
    if (error != null) throw error;
    didSubmitAuthentication = true;
  }

  @override
  Future<List<ProfileBookmarkStation>> fetchBookmarkedStations() async {
    final error = this.error;
    if (error != null) throw error;
    return bookmarks;
  }

  @override
  Future<void> removeBookmark(String bookmarkId) async {
    final error = this.error;
    if (error != null) throw error;
    removedBookmarkId = bookmarkId;
  }

  @override
  Future<ProfileActivityData?> fetchActivity() async {
    final error = this.error;
    if (error != null) throw error;
    return activity;
  }

  @override
  Future<void> cancelReservation() async {
    final error = this.error;
    if (error != null) throw error;
    didCancelReservation = true;
  }

  @override
  Future<ProfileDeleteAccountStatus> deleteCurrentAccount() async {
    final error = this.error;
    if (error != null) throw error;
    return deleteStatus;
  }
}

void main() {
  group('ProfileAuthenticationViewModel', () {
    test('uploads selected image through service', () async {
      final service = FakeProfileAccountService();
      final viewModel = ProfileAuthenticationViewModel(accountService: service);
      final image = File('/tmp/license.jpg');

      final result = await viewModel.uploadImage(
        type: ProfileAuthenticationImageType.license,
        image: image,
      );

      expect(result, ProfileAuthenticationUploadResult.success);
      expect(service.uploadedImageType, ProfileAuthenticationImageType.license);
      expect(service.uploadedImage, image);
      expect(viewModel.errorMessage, isNull);
    });

    test('does not upload when image is missing', () async {
      final service = FakeProfileAccountService();
      final viewModel = ProfileAuthenticationViewModel(accountService: service);

      final result = await viewModel.uploadImage(
        type: ProfileAuthenticationImageType.selfie,
        image: null,
      );

      expect(result, ProfileAuthenticationUploadResult.noImage);
      expect(service.uploadedImageType, isNull);
      expect(viewModel.errorMessage, 'Please select an image first.');
    });

    test('submits authentication request through service', () async {
      final service = FakeProfileAccountService();
      final viewModel = ProfileAuthenticationViewModel(accountService: service);

      final result = await viewModel.submitAuthenticationRequest();

      expect(result, ProfileAuthenticationSubmitResult.success);
      expect(service.didSubmitAuthentication, isTrue);
    });
  });

  group('ProfileBookmarkViewModel', () {
    test('loads and removes bookmarks', () async {
      final service = FakeProfileAccountService()
        ..bookmarks = const [
          ProfileBookmarkStation(
            bookmarkId: 'BM1',
            stationId: 'ST1',
            stationName: 'Station',
            description: 'Desc',
            imageUrl: 'https://image',
          ),
        ];
      final viewModel = ProfileBookmarkViewModel(accountService: service);

      await viewModel.loadBookmarks();
      final result = await viewModel.removeBookmark('BM1');

      expect(viewModel.stations, isEmpty);
      expect(result, ProfileBookmarkRemoveResult.success);
      expect(service.removedBookmarkId, 'BM1');
    });
  });

  group('ProfileActivityViewModel', () {
    test('loads reservation and ended attendance state', () async {
      final service = FakeProfileAccountService()
        ..activity = ProfileActivityData(
          customerId: 'CUS1',
          reservation: const ProfileReservationActivity(
            chargerId: 'CH1',
            stationId: 'ST1',
            status: 'Upcoming',
            stationName: 'Station',
            chargerName: 'Charger',
            chargerType: 'AC',
            chargerVoltage: '22',
            currentType: 'kW',
            pricePerVoltage: '1.50',
          ),
          endedAttendances: [
            ProfileEndedAttendance(
              stationName: 'Station',
              chargerName: 'Charger',
              totalCost: '10',
              duration: '30 min',
              checkInTime: DateTime(2026),
              checkOutTime: DateTime(2026, 1, 1, 1),
            ),
          ],
        );
      final viewModel = ProfileActivityViewModel(accountService: service);

      await viewModel.loadActivity();

      expect(viewModel.hasUpcomingReservation, isTrue);
      expect(viewModel.endedAttendances, hasLength(1));

      viewModel.dispose();
    });

    test('cancels reservation through service', () async {
      final service = FakeProfileAccountService();
      final viewModel = ProfileActivityViewModel(accountService: service);

      final result = await viewModel.cancelReservation();

      expect(result, ProfileCancelReservationResult.success);
      expect(service.didCancelReservation, isTrue);

      viewModel.dispose();
    });
  });

  group('DeleteAccountViewModel', () {
    test('maps successful delete', () async {
      final service = FakeProfileAccountService();
      final viewModel = DeleteAccountViewModel(accountService: service);

      final result = await viewModel.deleteAccount();

      expect(result, DeleteAccountResult.success);
      expect(viewModel.errorMessage, isNull);
    });

    test('maps missing customer to friendly message', () async {
      final service = FakeProfileAccountService()
        ..deleteStatus = ProfileDeleteAccountStatus.customerNotFound;
      final viewModel = DeleteAccountViewModel(accountService: service);

      final result = await viewModel.deleteAccount();

      expect(result, DeleteAccountResult.customerNotFound);
      expect(viewModel.errorMessage, 'Customer profile was not found.');
    });
  });
}
