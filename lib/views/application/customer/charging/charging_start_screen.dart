import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../viewmodels/charging/charging_session_viewmodel.dart';
import 'charging_session_timer_screen.dart';

class ChargingStartScreen extends StatelessWidget {
  const ChargingStartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChargingSessionViewModel()..load(),
      child: const _ChargingStartContent(),
    );
  }
}

class _ChargingStartContent extends StatefulWidget {
  const _ChargingStartContent();

  @override
  State<_ChargingStartContent> createState() => _ChargingStartContentState();
}

class _ChargingStartContentState extends State<_ChargingStartContent> {
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _navigationTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted) {
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const ChargingSessionTimerScreen(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChargingSessionViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Container(),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 35, top: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Image.asset(
              'assets/images/startcharging.png',
              fit: BoxFit.contain,
              height: 180,
            ),
            const SizedBox(height: 20),
            Text(
              viewModel.chargerName,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Start charging now",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text(
              "Plug in the connector to start charging session",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
