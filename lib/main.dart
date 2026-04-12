import 'dart:developer';
import 'package:ezcharge/viewmodels/tracking_viewmodel.dart';
import 'package:ezcharge/views/EZCHARGE/HomeScreen.dart';
import 'package:ezcharge/views/EZCHARGE/book_a_charge_screen.dart';
import 'package:ezcharge/views/admin/admin_analysis.dart';
import 'package:ezcharge/views/admin/admin_dashboard.dart';
import 'package:ezcharge/views/admin/admin_profile.dart';
import 'package:ezcharge/views/auth/Intro_screen.dart';
import 'package:ezcharge/views/auth/Welcome_screen.dart';
import 'package:ezcharge/views/auth/signin.dart';
import 'package:ezcharge/views/customer/Reward/RewardScreen.dart';
import 'package:ezcharge/views/customer/customercontent/AccountScreen.dart';
import 'package:ezcharge/views/customer/emergency_request/emergency_request_view.dart';
import 'package:ezcharge/views/customer/rating/customer_rating.dart';
import 'package:ezcharge/views/customer/rating/manage_complaint.dart';
import 'package:flutter/material.dart';
import 'package:ezcharge/viewmodels/emergency_request_viewmodel.dart';
import 'package:ezcharge/views/admin/admin_charging_station.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => EmergencyRequestViewModel(),
        ),
        ChangeNotifierProvider(create: (context) => TrackingViewModel()),
        // ✅ Add this line
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
      theme: ThemeData(primarySwatch: Colors.blue),
      home: IntroScreen(),
    );
  }
}
