import 'package:ezcharge/viewmodels/tracking_viewmodel.dart';
import 'package:ezcharge/views/auth/Intro_screen.dart';
import 'package:ezcharge/views/customer/customercontent/AccountScreen.dart';
import 'package:flutter/material.dart';
import 'package:ezcharge/viewmodels/emergency_request_viewmodel.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
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
      routes: {'/account': (context) => AccountScreen()},
    );
  }
}
