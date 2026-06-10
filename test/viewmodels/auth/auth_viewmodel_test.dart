import 'package:ezcharge/models/admin_model.dart';
import 'package:ezcharge/models/customer_model.dart';
import 'package:ezcharge/models/user_model.dart';
import 'package:ezcharge/services/auth_service.dart';
import 'package:ezcharge/viewmodels/auth/auth_viewmodel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthService implements AuthServiceContract {
  FakeAuthService({this.verificationId, this.errorMessage});

  final String? verificationId;
  final String? errorMessage;
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
  Future<CustomerModel?> getCustomerByPhoneNumber(String phoneNumber) {
    throw UnimplementedError();
  }

  @override
  Future<String> getAuthStatus(String customerId) {
    throw UnimplementedError();
  }

  @override
  Future<void> signout() {
    throw UnimplementedError();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthViewModel.submitPhoneNumber', () {
    test(
      'returns null and does not call auth service when phone is empty',
      () async {
        final authService = FakeAuthService();
        final viewModel = AuthViewModel(authService: authService);

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
      final viewModel = AuthViewModel(authService: authService);

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
        final viewModel = AuthViewModel(authService: authService);

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
}
