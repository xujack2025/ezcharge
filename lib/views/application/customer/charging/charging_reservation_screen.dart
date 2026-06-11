import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../models/charging_reservation_charger_model.dart';
import '../../../../viewmodels/charging/charging_reservation_viewmodel.dart';
import '../profile/account/activity_screen.dart';

class ChargingReservationScreen extends StatelessWidget {
  const ChargingReservationScreen({super.key, required this.stationId});

  final String stationId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ChargingReservationViewModel()..load(stationId),
      child: _ChargingReservationContent(stationId: stationId),
    );
  }
}

class _ChargingReservationContent extends StatelessWidget {
  const _ChargingReservationContent({required this.stationId});

  final String stationId;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChargingReservationViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  _buildAppBar(context),
                  const SizedBox(height: 20),
                  const Text(
                    "Provided Charger",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (viewModel.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        viewModel.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ...viewModel.chargers.map(
                    (charger) => _buildChargerCard(context, viewModel, charger),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Select Time",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildTimeSelector(context, viewModel),
                  const SizedBox(height: 20),
                  _buildTermsRow(viewModel),
                  const SizedBox(height: 20),
                  _buildReserveButton(context, viewModel),
                ],
              ),
            ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          "Reservation",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTimeSelector(
    BuildContext context,
    ChargingReservationViewModel viewModel,
  ) {
    return GestureDetector(
      onTap: () => _selectTime(context, viewModel),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, color: Colors.blue),
            const SizedBox(width: 10),
            Text(DateFormat.jm().format(viewModel.selectedTime)),
            const Spacer(),
            const Icon(Icons.arrow_drop_down, color: Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsRow(ChargingReservationViewModel viewModel) {
    return Row(
      children: [
        Checkbox(
          value: viewModel.isTermsAccepted,
          onChanged: (value) {
            viewModel.setTermsAccepted(value ?? false);
          },
        ),
        const Text("I accept the Terms & Conditions"),
      ],
    );
  }

  Widget _buildReserveButton(
    BuildContext context,
    ChargingReservationViewModel viewModel,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: viewModel.canSubmit
            ? () => _submitReservation(context, viewModel)
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: viewModel.canSubmit ? Colors.blue : Colors.grey,
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child: Text(
          viewModel.isSubmitting ? "RESERVING..." : "RESERVE",
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildChargerCard(
    BuildContext context,
    ChargingReservationViewModel viewModel,
    ChargingReservationCharger charger,
  ) {
    final isSelected = viewModel.selectedChargerId == charger.id;
    return GestureDetector(
      onTap: charger.isAvailable
          ? () => viewModel.selectCharger(charger.id)
          : null,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: charger.isAvailable ? Colors.white : Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? Colors.blue : Colors.grey),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: charger.isAvailable ? Colors.blue : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(charger.name),
            const Spacer(),
            Text(charger.power),
            const SizedBox(width: 10),
            Text(
              charger.status,
              style: TextStyle(
                color: charger.isAvailable ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTime(
    BuildContext context,
    ChargingReservationViewModel viewModel,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(viewModel.selectedTime),
    );
    if (picked == null || !context.mounted) {
      return;
    }

    final now = DateTime.now();
    final selectedDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      picked.hour,
      picked.minute,
    );
    final result = await viewModel.selectStartTime(selectedDateTime);
    if (!context.mounted) {
      return;
    }

    switch (result) {
      case ChargingReservationTimeResult.selected:
        return;
      case ChargingReservationTimeResult.noChargerSelected:
        _showMessage(context, "Please select a charger first!");
        return;
      case ChargingReservationTimeResult.slotTaken:
        _showMessage(context, "The slot has been selected by others!");
        return;
      case ChargingReservationTimeResult.failed:
        _showMessage(context, "Failed to check reservation slot.");
        return;
    }
  }

  Future<void> _submitReservation(
    BuildContext context,
    ChargingReservationViewModel viewModel,
  ) async {
    final result = await viewModel.submitReservation(stationId);
    if (!context.mounted) {
      return;
    }

    switch (result) {
      case ChargingReservationSubmitResult.success:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const _ReservationSuccessScreen(),
          ),
        );
        return;
      case ChargingReservationSubmitResult.noChargerSelected:
        _showMessage(context, "Please select a charger!");
        return;
      case ChargingReservationSubmitResult.termsNotAccepted:
        _showMessage(context, "Please accept the terms and conditions!");
        return;
      case ChargingReservationSubmitResult.customerNotFound:
        _showMessage(context, "Customer profile not found.");
        return;
      case ChargingReservationSubmitResult.failed:
        _showMessage(context, "Failed to reserve the charger. Try again!");
        return;
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ReservationSuccessScreen extends StatelessWidget {
  const _ReservationSuccessScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "The slot is booked",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.check_circle, color: Colors.green, size: 100),
            const SizedBox(height: 20),
            const Text(
              "The slot is successfully reserved\nPlease ensure you arrive on time!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 200,
              height: 45,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ActivityScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "FINISH",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
