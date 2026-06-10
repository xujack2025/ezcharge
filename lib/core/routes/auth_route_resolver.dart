import '../../models/user_model.dart';
import 'app_routes.dart';

class AuthRouteResolver {
  const AuthRouteResolver._();

  static String successRouteFor(UserRole role) {
    return switch (role) {
      UserRole.admin => AppRoutes.adminDashboardScreen,
      UserRole.customer => AppRoutes.applicationScreen,
    };
  }
}
