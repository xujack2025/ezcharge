import 'package:flutter/foundation.dart';

import '../core/routes/app_routes.dart';
import '../core/routes/auth_route_resolver.dart';
import '../core/utils/app_logger.dart';
import '../models/user_model.dart';
import '../services/startup_service.dart';

class StartupViewModel extends ChangeNotifier {
  StartupViewModel({StartupServiceContract? startupService})
    : _startupService = startupService ?? StartupService();

  final StartupServiceContract _startupService;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<String> resolveInitialRoute() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final hasCompletedOnboarding = await _startupService
          .hasCompletedOnboarding();
      if (!hasCompletedOnboarding) {
        return AppRoutes.introScreen;
      }

      final isLoggedIn = await _startupService.isLoggedIn();
      if (!isLoggedIn) {
        return AppRoutes.signInScreen;
      }

      final role = await _startupService.resolveCurrentUserRole();
      if (role == null) {
        await _startupService.setLoggedIn(false);
        return AppRoutes.signInScreen;
      }

      return AuthRouteResolver.successRouteFor(role);
    } catch (e) {
      AppLogger.error("Startup route resolution failed: $e");
      _errorMessage = "Failed to start app.";
      return AppRoutes.signInScreen;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> completeOnboarding() {
    return _startupService.markOnboardingCompleted();
  }

  Future<void> markLoggedIn(UserRole role) {
    return _startupService.setLoggedIn(true, role: role);
  }

  Future<void> markLoggedOut() {
    return _startupService.setLoggedIn(false);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
