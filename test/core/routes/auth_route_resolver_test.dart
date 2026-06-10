import 'package:ezcharge/core/routes/app_routes.dart';
import 'package:ezcharge/core/routes/auth_route_resolver.dart';
import 'package:ezcharge/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthRouteResolver.successRouteFor', () {
    test('returns application route for customer', () {
      expect(
        AuthRouteResolver.successRouteFor(UserRole.customer),
        AppRoutes.applicationScreen,
      );
    });

    test('returns admin dashboard route for admin', () {
      expect(
        AuthRouteResolver.successRouteFor(UserRole.admin),
        AppRoutes.adminDashboardScreen,
      );
    });
  });
}
