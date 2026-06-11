// ignore_for_file: unused_import

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'core/constants/colors.dart';
import 'core/routes/app_routes.dart';
import 'models/user_model.dart';
import 'services/station_service.dart';
import 'viewmodels/application/application_viewmodel.dart';
import 'viewmodels/application/check_in_viewmodel.dart';
import 'viewmodels/application/home_viewmodel.dart';
import 'viewmodels/application/notification_viewmodel.dart';
import 'viewmodels/application/profile_viewmodel.dart';
import 'viewmodels/application/reward_viewmodel.dart';
import 'viewmodels/auth/auth_viewmodel.dart';
import 'viewmodels/charging_station_viewmodel.dart';
import 'viewmodels/emergency_request_viewmodel.dart';
import 'viewmodels/onboarding/onboarding_viewmodel.dart';
import 'viewmodels/startup_viewmodel.dart';
import 'viewmodels/tracking_viewmodel.dart';
import 'views/admin/admin_dashboard.dart';
import 'views/application/application_screen.dart';
import 'views/application/check_in_screen.dart';
import 'views/application/home_screen.dart';
import 'views/auth/admin_sign_in_screen.dart';
import 'views/auth/otp_screen.dart';
import 'views/auth/sign_in_screen.dart';
import 'views/onboarding/intro_schedule_screen.dart';
import 'views/onboarding/intro_screen.dart';
import 'views/onboarding/welcome_screen.dart';
import 'views/startup/startup_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthViewModel()),
        ChangeNotifierProvider(
          create: (context) => EmergencyRequestViewModel(),
        ),
        ChangeNotifierProvider(create: (context) => TrackingViewModel()),
        ChangeNotifierProvider(
          create: (context) =>
              ChargingStationViewModel(stationService: StationService()),
        ),
        ChangeNotifierProvider(create: (context) => OnboardingViewmodel()),
        ChangeNotifierProvider(create: (context) => StartupViewModel()),
        ChangeNotifierProvider(create: (context) => ApplicationViewmodel()),
        ChangeNotifierProvider(create: (context) => CheckInViewModel()),
        ChangeNotifierProvider(create: (context) => HomeViewModel()),
        ChangeNotifierProvider(
          create: (context) => ApplicationNotificationViewModel(),
        ),
        ChangeNotifierProvider(create: (context) => RewardViewModel()),
        ChangeNotifierProvider(create: (context) => ProfileViewModel()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'EzCharge',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.textBlue,
            primary: AppColors.textBlue,
          ),
        ),
        initialRoute: AppRoutes.startupScreen,
        routes: {
          AppRoutes.startupScreen: (context) => const StartupScreen(),
          AppRoutes.introScreen: (context) => const IntroScreen(),
          AppRoutes.introScheduleScreen: (context) => IntroScheduleScreen(),
          AppRoutes.welcomeScreen: (context) => const WelcomeScreen(),
          AppRoutes.signInScreen: (context) => const SignInScreen(),
          AppRoutes.adminSignInScreen: (context) => const AdminSignInScreen(),
          AppRoutes.applicationScreen: (context) => const ApplicationScreen(),
          AppRoutes.adminDashboardScreen: (context) => const AdminDashboard(),
        },
      ),
    );
  }
}
