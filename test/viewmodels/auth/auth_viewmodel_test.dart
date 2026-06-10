import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ezcharge/models/admin_model.dart';
import 'package:ezcharge/models/customer_model.dart';
import 'package:ezcharge/models/user_model.dart';
import 'package:ezcharge/services/auth_service.dart';
import 'package:ezcharge/services/startup_service.dart';
import 'package:ezcharge/services/station_service.dart';
import 'package:ezcharge/viewmodels/auth/auth_viewmodel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthService implements AuthServiceContract {
  FakeAuthService({
    this.verificationId,
    this.errorMessage,
    this.currentPhoneNumber,
    this.customer,
    this.authStatus = "",
  });

  final String? verificationId;
  final String? errorMessage;
  final String? currentPhoneNumber;
  final CustomerModel? customer;
  final String authStatus;
  String? requestedPhoneNumber;
  UserRole? requestedRole;

  @override
  Future<void> sendOtp(
    String phoneNumber,
    UserRole role, {
    required void Function(String verificationId) onCodeSent,
    required void Function() onVerificationCompleted,
    required void Function(String message) onError,
  }) async {
    requestedPhoneNumber = phoneNumber;
    requestedRole = role;

    if (errorMessage != null) {
      onError(errorMessage!);
      return;
    }

    onCodeSent(verificationId ?? 'test-verification-id');
  }

  @override
  Future<UserCredential> signInWithOtp(String verificationId, String smsCode) {
    throw UnimplementedError();
  }

  @override
  Future<UserModel?> getUserByPhoneNumber(String phoneNumber, UserRole role) {
    throw UnimplementedError();
  }

  @override
  Future<AdminModel?> getAdminByPhoneNumber(String phoneNumber) {
    throw UnimplementedError();
  }

  @override
  Future<CustomerModel?> getCustomerByPhoneNumber(String phoneNumber) async {
    requestedPhoneNumber = phoneNumber;
    return customer;
  }

  @override
  Future<String> getAuthStatus(String customerId) async {
    return authStatus;
  }

  @override
  String? getCurrentUserPhoneNumber() {
    return currentPhoneNumber;
  }

  @override
  Future<void> signout() {
    throw UnimplementedError();
  }
}

class FakeStartupService implements StartupServiceContract {
  bool? loggedInValue;
  UserRole? loggedInRole;

  @override
  Future<UserRole?> getSavedRole() {
    throw UnimplementedError();
  }

  @override
  Future<bool> hasCompletedOnboarding() {
    throw UnimplementedError();
  }

  @override
  Future<bool> isLoggedIn() {
    throw UnimplementedError();
  }

  @override
  Future<void> markOnboardingCompleted() {
    throw UnimplementedError();
  }

  @override
  Future<UserRole?> resolveCurrentUserRole() {
    throw UnimplementedError();
  }

  @override
  Future<void> setLoggedIn(bool value, {UserRole? role}) async {
    loggedInValue = value;
    loggedInRole = role;
  }
}

class FakeStationService implements StationReservationServiceContract {
  FakeStationService({this.reservationStatus = ""});

  final String reservationStatus;
  String? requestedCustomerId;

  @override
  Future<String> getReservationStatus(String customerId) async {
    requestedCustomerId = customerId;
    return reservationStatus;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final customer = CustomerModel(
    id: "CUS1",
    firstName: "Test",
    lastName: "Customer",
    gender: "Female",
    walletBalance: 0,
    pointBalance: 0,
    dateOfBirth: "2000-01-01",
    createdAt: Timestamp.fromMillisecondsSinceEpoch(0),
    email: "test@example.com",
    phone: "+60123456789",
  );

  group('AuthViewModel.submitPhoneNumber', () {
    test(
      'returns null and does not call auth service when phone is empty',
      () async {
        final authService = FakeAuthService();
        final viewModel = AuthViewModel(
          authService: authService,
          startupService: FakeStartupService(),
        );

        final verificationId = await viewModel.submitPhoneNumber(
          '',
          UserRole.customer,
        );

        expect(verificationId, isNull);
        expect(authService.requestedPhoneNumber, isNull);
        expect(viewModel.isLoading, isFalse);
        expect(viewModel.errorMessage, isNull);
      },
    );

    test('returns verification id when OTP request succeeds', () async {
      final authService = FakeAuthService(verificationId: 'verification-123');
      final viewModel = AuthViewModel(
        authService: authService,
        startupService: FakeStartupService(),
      );

      final verificationId = await viewModel.submitPhoneNumber(
        '+60123456789',
        UserRole.customer,
      );

      expect(verificationId, 'verification-123');
      expect(authService.requestedPhoneNumber, '+60123456789');
      expect(authService.requestedRole, UserRole.customer);
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNull);
    });

    test(
      'returns null and exposes error message when OTP request fails',
      () async {
        final authService = FakeAuthService(errorMessage: 'Phone not found');
        final viewModel = AuthViewModel(
          authService: authService,
          startupService: FakeStartupService(),
        );

        final verificationId = await viewModel.submitPhoneNumber(
          '+60123456789',
          UserRole.admin,
        );

        expect(verificationId, isNull);
        expect(authService.requestedPhoneNumber, '+60123456789');
        expect(authService.requestedRole, UserRole.admin);
        expect(viewModel.isLoading, isFalse);
        expect(viewModel.errorMessage, 'Phone not found');
      },
    );
  });

  group('AuthViewModel.syncUserStatus', () {
    test(
      'hydrates current customer from Firebase phone before syncing status',
      () async {
        final authService = FakeAuthService(
          currentPhoneNumber: '+60123456789',
          customer: customer,
          authStatus: 'Pass',
        );
        final stationService = FakeStationService(reservationStatus: '');
        final viewModel = AuthViewModel(
          authService: authService,
          stationService: stationService,
          startupService: FakeStartupService(),
        );

        await viewModel.syncUserStatus();

        expect(authService.requestedPhoneNumber, '+60123456789');
        expect(stationService.requestedCustomerId, 'CUS1');
        expect(viewModel.customerId, 'CUS1');
        expect(viewModel.isAuthenticated, isTrue);
        expect(viewModel.hasActiveReservation, isFalse);
        expect(viewModel.errorMessage, isNull);
      },
    );

    test('exposes an error when no customer profile can be restored', () async {
      final viewModel = AuthViewModel(
        authService: FakeAuthService(currentPhoneNumber: '+60123456789'),
        stationService: FakeStationService(),
        startupService: FakeStartupService(),
      );

      await viewModel.syncUserStatus();

      expect(viewModel.customerId, isEmpty);
      expect(viewModel.isAuthenticated, isFalse);
      expect(viewModel.errorMessage, 'Customer profile not found.');
    });
  });
}
