import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../viewmodels/charging/charging_reward_selection_viewmodel.dart';

class ChargingRewardSelectionScreen extends StatefulWidget {
  const ChargingRewardSelectionScreen({super.key});

  @override
  State<ChargingRewardSelectionScreen> createState() =>
      _ChargingRewardSelectionScreenState();
}

class _ChargingRewardSelectionScreenState
    extends State<ChargingRewardSelectionScreen> {
  String _formatDate(DateTime date) {
    return DateFormat('d/M/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChargingRewardSelectionViewModel()..loadRewards(),
      child: Consumer<ChargingRewardSelectionViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: viewModel.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildBody(viewModel),
            ),
            bottomNavigationBar: SafeArea(
              minimum: const EdgeInsets.all(16),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: viewModel.selectedIndex == null
                    ? null
                    : () {
                        final selectedReward = viewModel.selectedReward();
                        if (selectedReward == null) return;
                        Navigator.pop(
                          context,
                          selectedReward.toNavigationResult(),
                        );
                      },
                child: const Text(
                  "CONFIRM",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(ChargingRewardSelectionViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with the back button and "Reward Discount" text
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Row(
            children: [
              // Circular back button
              InkWell(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Reward Discount",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        // Body content: list of rewards or a "No rewards found" message.
        Expanded(
          child: viewModel.rewards.isEmpty
              ? const Center(child: Text("No rewards found."))
              : ListView.builder(
                  itemCount: viewModel.rewards.length,
                  itemBuilder: (context, index) {
                    final reward = viewModel.rewards[index];
                    final points = reward.points;
                    final details = reward.details;
                    final dateText =
                        "Valid Till: ${_formatDate(reward.expiredDate)}";

                    return InkWell(
                      onTap: () {
                        viewModel.selectReward(index);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: viewModel.selectedIndex == index
                                ? Colors.blue
                                : Colors.grey.shade300,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade200,
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Radio icon to indicate selection
                            Icon(
                              viewModel.selectedIndex == index
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 12),
                            // Points circle + icon (simulate the “-300 pts” design)
                            Container(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "-$points",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.bolt,
                                    size: 16,
                                    color: Colors.blue,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Reward info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    details,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    dateText,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
