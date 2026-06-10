import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/app_logger.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

abstract class StartupServiceContract {
  Future<bool> hasCompletedOnboarding();

  Future<void> markOnboardingCompleted();

  Future<bool> isLoggedIn();

  Future<void> setLoggedIn(bool value, {UserRole? role});

  Future<UserRole?> getSavedRole();

  Future<UserRole?> resolveCurrentUserRole();
}

class StartupService implements StartupServiceContract {
  StartupService({
    AuthServiceContract? authService,
    Future<SharedPreferences> Function()? preferencesProvider,
  }) : _authService = authService ?? AuthService(),
       _preferencesProvider =
           preferencesProvider ?? SharedPreferences.getInstance;

  static const String _hasCompletedOnboardingKey = "hasCompletedOnboarding";
  static const String _isLoggedInKey = "isLoggedIn";
  static const String _userRoleKey = "userRole";

  final AuthServiceContract _authService;
  final Future<SharedPreferences> Function() _preferencesProvider;

  @override
  Future<bool> hasCompletedOnboarding() async {
    final preferences = await _preferencesProvider();
    return preferences.getBool(_hasCompletedOnboardingKey) ?? false;
  }

  @override
  Future<void> markOnboardingCompleted() async {
    final preferences = await _preferencesProvider();
    await preferences.setBool(_hasCompletedOnboardingKey, true);
  }

  @override
  Future<bool> isLoggedIn() async {
    final preferences = await _preferencesProvider();
    return preferences.getBool(_isLoggedInKey) ?? false;
  }

  @override
  Future<void> setLoggedIn(bool value, {UserRole? role}) async {
    final preferences = await _preferencesProvider();
    await preferences.setBool(_isLoggedInKey, value);

    if (!value) {
      await preferences.remove(_userRoleKey);
      return;
    }

    if (role != null) {
      await preferences.setString(_userRoleKey, role.name);
    }
  }

  @override
  Future<UserRole?> getSavedRole() async {
    final preferences = await _preferencesProvider();
    final rawRole = preferences.getString(_userRoleKey);
    return _parseRole(rawRole);
  }

  @override
  Future<UserRole?> resolveCurrentUserRole() async {
    final phoneNumber = _authService.getCurrentUserPhoneNumber();
    if (phoneNumber == null || phoneNumber.isEmpty) {
      await setLoggedIn(false);
      return null;
    }

    try {
      final savedRole = await getSavedRole();
      if (savedRole != null) {
        final user = await _authService.getUserByPhoneNumber(
          phoneNumber,
          savedRole,
        );
        if (user != null) return savedRole;
      }

      final admin = await _authService.getAdminByPhoneNumber(phoneNumber);
      if (admin != null) {
        await setLoggedIn(true, role: UserRole.admin);
        return UserRole.admin;
      }

      final customer = await _authService.getCustomerByPhoneNumber(phoneNumber);
      if (customer != null) {
        await setLoggedIn(true, role: UserRole.customer);
        return UserRole.customer;
      }

      await setLoggedIn(false);
      return null;
    } catch (e) {
      AppLogger.error("Failed to resolve startup user role: $e");
      return null;
    }
  }

  UserRole? _parseRole(String? rawRole) {
    if (rawRole == null) return null;

    for (final role in UserRole.values) {
      if (role.name == rawRole) return role;
    }

    return null;
  }
}
