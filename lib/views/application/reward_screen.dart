import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/reward_model.dart';
import '../../viewmodels/application/reward_viewmodel.dart';
import '../reward/point_history_screen.dart';

class RewardScreen extends StatefulWidget {
  const RewardScreen({super.key});

  @override
  RewardScreenState createState() => RewardScreenState();
}

class RewardScreenState extends State<RewardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RewardViewModel>().loadRewards();
    });
  }

  // Redeem reward and accumulate points (if not already redeemed)
  Future<void> _redeemReward(BuildContext context, RewardModel reward) async {
    final rewardViewModel = context.read<RewardViewModel>();
    final messenger = ScaffoldMessenger.of(context);

    if (rewardViewModel.isRedeemed(reward.id)) {
      messenger.showSnackBar(
        const SnackBar(content: Text("You have already redeemed this reward.")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Redeem Points"),
          content: Text("Are you sure you want to redeem:\n${reward.details}?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel", style: TextStyle(color: Colors.blue)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                final outcome = await rewardViewModel.redeemReward(reward);
                if (!mounted) return;

                switch (outcome) {
                  case RewardRedeemOutcome.success:
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          "Successfully redeemed: ${reward.details}",
                        ),
                      ),
                    );
                    return;
                  case RewardRedeemOutcome.alreadyRedeemed:
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text("You have already redeemed this reward."),
                      ),
                    );
                    return;
                  case RewardRedeemOutcome.failed:
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text("Failed to redeem reward. Try again."),
                      ),
                    );
                    return;
                }
              },
              child: const Text("Confirm", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rewardViewModel = context.watch<RewardViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: false,
        title: const Text(
          "Rewards",
          style: TextStyle(
            color: Colors.black,
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: rewardViewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPointsCard(rewardViewModel.customerPoints),
                  const SizedBox(height: 20),

                  //View Points History Button
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PointHistoryScreen(),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "View my points history",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        Container(
                          width: 30, // Set size of the circle
                          height: 30,
                          decoration: const BoxDecoration(
                            color: Colors.blue, // Blue background
                            shape: BoxShape.circle, // Circular shape
                          ),
                          child: const Icon(
                            Icons.arrow_forward,
                            color: Colors.white, // White arrow
                            size: 20, // Adjust arrow size
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Divider(
                    color: Colors.grey, // Light gray color
                    thickness: 1, // Line thickness
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "EZCHARGE Promotions",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  if (rewardViewModel.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        rewardViewModel.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),

                  if (rewardViewModel.rewards.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text("No rewards available.")),
                    )
                  else
                    ...rewardViewModel.rewards.map(
                      (reward) =>
                          _buildPromotionItem(context, rewardViewModel, reward),
                    ),
                ],
              ),
            ),
    );
  }

  //Display User Points
  Widget _buildPointsCard(int customerPoints) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.blue, Colors.indigo]),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "You have",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 5),
          Text(
            "$customerPoints pts",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  //Build a Redeemable Promotion Item
  Widget _buildPromotionItem(
    BuildContext context,
    RewardViewModel rewardViewModel,
    RewardModel reward,
  ) {
    bool isRedeemed = rewardViewModel.isRedeemed(reward.id);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 100,
                height: 80,
                color: Colors.grey[300],
                child: const Icon(
                  Icons.card_giftcard,
                  color: Colors.blue,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reward.details,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.bolt, color: Colors.blue, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        "${reward.points} pts",
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: isRedeemed
                  ? null
                  : () => _redeemReward(context, reward),
              style: ElevatedButton.styleFrom(
                backgroundColor: isRedeemed ? Colors.grey : Colors.blue,
              ),
              child: Text(
                isRedeemed ? "REDEEMED" : "REDEEM",
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
