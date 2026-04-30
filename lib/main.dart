import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'package:ezcharge/services/station_service.dart';
import 'package:ezcharge/viewmodels/charging_station_viewmodel.dart';
import 'package:ezcharge/core/constants/colors.dart';
import 'package:ezcharge/viewmodels/auth/auth_viewmodel.dart';
import 'package:ezcharge/viewmodels/emergency_request_viewmodel.dart';
import 'package:ezcharge/viewmodels/tracking_viewmodel.dart';
import 'package:ezcharge/views/auth/sign_in_screen.dart';
// ignore: unused_import
import 'package:ezcharge/views/welcome/intro_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthViewModel()),
        ChangeNotifierProvider(create: (context) => EmergencyRequestViewModel()),
        ChangeNotifierProvider(create: (context) => TrackingViewModel()),
        ChangeNotifierProvider(
          create: (context) => ChargingStationViewModel(stationService: StationService()),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EzCharge',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.textBlue,
          primary: AppColors.textBlue,
        ),
      ),
      // home: IntroScreen(),
      home: SignInScreen(),
    );
  }
}
