import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../viewmodels/charging/charging_session_viewmodel.dart';
import '../profile/account/activity_screen.dart';
import '../service/chatbot_screen.dart';
import 'charging_stop_screen.dart';

// A shared timer service that holds the timer state independently.
class ChargingSessionTimerService {
  static DateTime? startTime;
  static Timer? timer;
  static int elapsedSeconds = 0;

  static void startTimer(Function onTimeLimitReached) {
    // Start timer only once.
    if (startTime == null) {
      startTime = DateTime.now();
      timer = Timer.periodic(const Duration(seconds: 1), (t) {
        elapsedSeconds++;
        if (elapsedSeconds >= 60) {
          onTimeLimitReached();
        }
      });
    }
  }

  static void stopTimer() {
    timer?.cancel();
    timer = null;
  }

  static String get hoursStr =>
      (elapsedSeconds ~/ 3600).toString().padLeft(2, '0');
  static String get minutesStr =>
      ((elapsedSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
  static String get secondsStr =>
      (elapsedSeconds % 60).toString().padLeft(2, '0');
}

class ChargingSessionTimerScreen extends StatelessWidget {
  const ChargingSessionTimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChargingSessionViewModel()..load(),
      child: const _ChargingSessionTimerContent(),
    );
  }
}

class _ChargingSessionTimerContent extends StatefulWidget {
  const _ChargingSessionTimerContent();

  @override
  State<_ChargingSessionTimerContent> createState() =>
      _ChargingSessionTimerContentState();
}

class _ChargingSessionTimerContentState
    extends State<_ChargingSessionTimerContent> {
  // A separate UI timer to trigger setState so that the displayed time updates.
  Timer? _uiTimer;

  @override
  void initState() {
    super.initState();
    // Start the shared timer if it hasn't been started.
    ChargingSessionTimerService.startTimer(_handleTimeLimitReached);
    // Set up a UI update timer.
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    // Do NOT stop the shared ChargingSessionTimerService here so that the timer continues.
    super.dispose();
  }

  Future<void> _handleTimeLimitReached() async {
    final viewModel = context.read<ChargingSessionViewModel>();
    final result = await viewModel.endSession();
    if (!mounted || result != ChargingSessionEndResult.success) {
      return;
    }

    final stopTime = DateTime.now();
    final totalDuration = stopTime.difference(
      ChargingSessionTimerService.startTime ?? stopTime,
    );

    ChargingSessionTimerService.stopTimer();
    ChargingSessionTimerService.startTime = null;
    ChargingSessionTimerService.elapsedSeconds = 0;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ChargingStopScreen(totalDuration: totalDuration),
      ),
    );
  }

  // Show the bottom sheet to stop charging.
  Future<void> _showStopChargingSheet() async {
    final viewModel = context.read<ChargingSessionViewModel>();
    final rootContext = context;

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            children: [
              const Text(
                "Stop charging?",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Final amount charged will be based on your total duration. "
                "You can check on the rates first before confirming.",
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red, // Button background color
                        foregroundColor: Colors.white, // Text color
                      ),
                      onPressed: () async {
                        final result = await viewModel.endSession();
                        if (!context.mounted ||
                            !rootContext.mounted ||
                            result != ChargingSessionEndResult.success) {
                          return;
                        }

                        ChargingSessionTimerService.stopTimer();

                        final stopTime = DateTime.now();
                        final totalDuration = stopTime.difference(
                          ChargingSessionTimerService.startTime ?? stopTime,
                        );

                        ChargingSessionTimerService.startTime = null;
                        ChargingSessionTimerService.elapsedSeconds = 0;

                        Navigator.pop(context);

                        Navigator.pushReplacement(
                          rootContext,
                          MaterialPageRoute(
                            builder: (context) => ChargingStopScreen(
                              totalDuration: totalDuration,
                            ),
                          ),
                        );
                      },
                      child: const Text("STOP CHARGING"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context); // Just close bottom sheet.
                      },
                      child: const Text("CANCEL"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChargingSessionViewModel>();

    return Scaffold(
      // Dark blue background
      backgroundColor: Colors.blue[900],

      // AppBar with same dark blue background
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            // Navigate to ActivityScreen's active tab without stopping the timer.
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const ActivityScreen(initialTabIndex: 1),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const ChatbotScreen(), // Replace with your target page widget
                ),
              );
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.support_agent, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  "Help",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // Use a Stack to layer the circle, the lightning icon, and the white container.
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Large circle
            Container(
              width: 900,
              height: 1000,
              decoration: const BoxDecoration(
                color: Colors.blue, // A lighter/brighter blue for contrast
                shape: BoxShape.circle,
              ),
            ),

            // White lightning icon on top of the circle
            Transform.translate(
              offset: const Offset(
                -30,
                0,
              ), // negative X moves it left, adjust as needed
              child: const Icon(Icons.bolt, size: 480, color: Colors.white),
            ),

            // White container with timer info on top of the lightning icon
            Container(
              width: 260,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    viewModel.stationName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    viewModel.chargerName,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  // Timer Display
                  Text(
                    "${ChargingSessionTimerService.hoursStr} : ${ChargingSessionTimerService.minutesStr} : ${ChargingSessionTimerService.secondsStr}",
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text("Connector: ${viewModel.chargerType}"),
                ],
              ),
            ),
          ],
        ),
      ),

      // Bottom nav bar with "STOP CHARGING"
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: TextButton(
            onPressed: _showStopChargingSheet,
            child: const Text(
              "STOP CHARGING",
              style: TextStyle(
                fontSize: 20,
                color: Colors.lightBlueAccent,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
