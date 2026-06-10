import 'package:ezcharge/core/routes/app_routes.dart';
import 'package:ezcharge/models/user_model.dart';
import 'package:ezcharge/services/startup_service.dart';
import 'package:ezcharge/viewmodels/startup_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeStartupService implements StartupServiceContract {
  FakeStartupService({
    this.hasCompletedOnboardingValue = true,
    this.isLoggedInValue = false,
    this.savedRole,
    this.resolvedRole,
  });

  bool hasCompletedOnboardingValue;
  bool isLoggedInValue;
  UserRole? savedRole;
  UserRole? resolvedRole;
  bool markedOnboardingCompleted = false;
  bool? loggedInValue;
  UserRole? loggedInRole;

  @override
  Future<bool> hasCompletedOnboarding() async => hasCompletedOnboardingValue;

  @override
  Future<void> markOnboardingCompleted() async {
    markedOnboardingCompleted = true;
  }

  @override
  Future<bool> isLoggedIn() async => isLoggedInValue;

  @override
  Future<void> setLoggedIn(bool value, {UserRole? role}) async {
    loggedInValue = value;
    loggedInRole = role;
  }

  @override
  Future<UserRole?> getSavedRole() async => savedRole;

  @override
  Future<UserRole?> resolveCurrentUserRole() async => resolvedRole;
}

void main() {
  group('StartupViewModel.resolveInitialRoute', () {
    test('sends first open users to intro screen', () async {
      final service = FakeStartupService(hasCompletedOnboardingValue: false);
      final viewModel = StartupViewModel(startupService: service);

      final route = await viewModel.resolveInitialRoute();

      expect(route, AppRoutes.introScreen);
    });

    test('sends onboarded logged-out users to sign in', () async {
      final service = FakeStartupService(
        hasCompletedOnboardingValue: true,
        isLoggedInValue: false,
      );
      final viewModel = StartupViewModel(startupService: service);

      final route = await viewModel.resolveInitialRoute();

      expect(route, AppRoutes.signInScreen);
    });

    test('sends logged-in customers to app home shell', () async {
      final service = FakeStartupService(
        isLoggedInValue: true,
        resolvedRole: UserRole.customer,
      );
      final viewModel = StartupViewModel(startupService: service);

      final route = await viewModel.resolveInitialRoute();

      expect(route, AppRoutes.applicationScreen);
    });

    test('sends logged-in admins to admin dashboard', () async {
      final service = FakeStartupService(
        isLoggedInValue: true,
        resolvedRole: UserRole.admin,
      );
      final viewModel = StartupViewModel(startupService: service);

      final route = await viewModel.resolveInitialRoute();

      expect(route, AppRoutes.adminDashboardScreen);
    });

    test('clears stale login when role cannot be resolved', () async {
      final service = FakeStartupService(isLoggedInValue: true);
      final viewModel = StartupViewModel(startupService: service);

      final route = await viewModel.resolveInitialRoute();

      expect(route, AppRoutes.signInScreen);
      expect(service.loggedInValue, isFalse);
    });
  });

  test('completeOnboarding marks onboarding as completed', () async {
    final service = FakeStartupService();
    final viewModel = StartupViewModel(startupService: service);

    await viewModel.completeOnboarding();

    expect(service.markedOnboardingCompleted, isTrue);
  });
}
