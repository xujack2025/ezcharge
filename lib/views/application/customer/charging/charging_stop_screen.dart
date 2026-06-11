import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../viewmodels/charging/charging_session_viewmodel.dart';
import 'charging_check_out_detail_screen.dart';

class ChargingStopScreen extends StatelessWidget {
  const ChargingStopScreen({super.key, required this.totalDuration});

  final Duration totalDuration;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChargingSessionViewModel()..load(),
      child: _ChargingStopContent(totalDuration: totalDuration),
    );
  }
}

class _ChargingStopContent extends StatefulWidget {
  const _ChargingStopContent({required this.totalDuration});

  final Duration totalDuration;

  @override
  State<_ChargingStopContent> createState() => _ChargingStopContentState();
}

class _ChargingStopContentState extends State<_ChargingStopContent> {
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
          builder: (context) =>
              ChargingCheckOutDetailScreen(totalDuration: widget.totalDuration),
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
              "Unplug charger",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const Text(
              "Unplug the connector and place back to the dock",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
