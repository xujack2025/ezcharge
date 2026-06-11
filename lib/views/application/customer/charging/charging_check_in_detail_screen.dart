import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../viewmodels/application/check_in_viewmodel.dart';
import '../service/chatbot_screen.dart';
import 'charging_start_screen.dart';

class ChargingCheckInDetailScreen extends StatefulWidget {
  const ChargingCheckInDetailScreen({super.key});

  @override
  ChargingCheckInDetailScreenState createState() =>
      ChargingCheckInDetailScreenState();
}

class ChargingCheckInDetailScreenState
    extends State<ChargingCheckInDetailScreen> {
  bool isChecked = false;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CheckInViewModel()..loadCheckInDetails(),
      child: Consumer<CheckInViewModel>(
        builder: (context, viewModel, _) {
          final details = viewModel.checkInDetails;
          final startTime = details?.startTime ?? DateTime.now();

          return Scaffold(
            backgroundColor: Colors.white,
            body: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //Back Button & Title
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Left side: back button + "Check In"
                            Row(
                              children: [
                                IconButton(
                                  icon: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: const Icon(
                                      Icons.arrow_back,
                                      color: Colors.white,
                                    ),
                                  ),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  "Check In",
                                  style: TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            // Right side: "Help"
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ChatbotScreen(),
                                    ),
                                  );
                                },
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.support_agent,
                                      color: Colors.blue,
                                      size: 30,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "Help",
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        //Image
                        Center(
                          child: Image.asset(
                            'assets/images/charging.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 20),
                        //Reservation Details
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              const Text(
                                "Charging Station: ",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Expanded(
                                child: Text(
                                  details?.stationName ?? "",
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              const Text(
                                "Charging Slot: ",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Expanded(
                                child: Text(
                                  details?.chargerName ?? "",
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              const Text(
                                "Charger Type: ",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Expanded(
                                child: Text(
                                  details?.chargerType ?? "",
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              const Text(
                                "Price per KWH: ",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Expanded(
                                child: Text(
                                  "RM${details?.pricePerVoltage.toStringAsFixed(2) ?? ""}",
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              const Text(
                                "Reserved Time: ",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Expanded(
                                child: Text(
                                  // Convert the Timestamp to a DateTime, then format it
                                  DateFormat(
                                    'yyyy-MM-dd HH:mm',
                                  ).format(startTime),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                        //Terms & Conditions Checkbox
                        Row(
                          children: [
                            Checkbox(
                              value: isChecked,
                              onChanged: (value) {
                                setState(() {
                                  isChecked = value!;
                                });
                              },
                            ),
                            const Expanded(
                              child: Text(
                                "I have checked the details and request for charging",
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        //Check-In Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                (isChecked && DateTime.now().isAfter(startTime))
                                ? () => _checkIn(context, viewModel)
                                : () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Now isn't your check-in time!",
                                        ),
                                      ),
                                    );
                                  }, // Disable button
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  (isChecked &&
                                      DateTime.now().isAfter(startTime))
                                  ? Colors.blue
                                  : Colors.grey,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            child: const Text(
                              "CHECK IN",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  Future<void> _checkIn(
    BuildContext context,
    CheckInViewModel viewModel,
  ) async {
    final result = await viewModel.submitCheckIn();
    if (!context.mounted) return;

    switch (result) {
      case CheckInSubmitResult.success:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Check-in successful!")));

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChargingStartScreen()),
        );
        return;
      case CheckInSubmitResult.notReady:
      case CheckInSubmitResult.noReservation:
      case CheckInSubmitResult.failed:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              viewModel.errorMessage ?? "Check-in failed. Try again!",
            ),
          ),
        );
    }
  }
}
