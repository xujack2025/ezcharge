import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/reward_model.dart';
import '../../viewmodels/application/point_history_viewmodel.dart';

class PointHistoryScreen extends StatelessWidget {
  const PointHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PointHistoryViewModel()..loadRewardHistory(),
      child: const _PointHistoryContent(),
    );
  }
}

class _PointHistoryContent extends StatefulWidget {
  const _PointHistoryContent();

  @override
  State<_PointHistoryContent> createState() => _PointHistoryContentState();
}

class _PointHistoryContentState extends State<_PointHistoryContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<PointHistoryViewModel>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Container(
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Top Up EZCHARGE Credit',
          style: TextStyle(
            color: Colors.black,
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Invalid'),
            Tab(text: 'Used'),
          ],
        ),
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : viewModel.errorMessage != null
          ? Center(child: Text(viewModel.errorMessage!))
          : TabBarView(
              controller: _tabController,
              children: [
                _RewardHistoryTab(
                  emptyText: 'No expired rewards.',
                  label: 'Expired',
                  rewards: viewModel.expiredRewards,
                ),
                _RewardHistoryTab(
                  emptyText: 'No used rewards.',
                  label: 'Used',
                  rewards: viewModel.usedRewards,
                ),
              ],
            ),
    );
  }
}

class _RewardHistoryTab extends StatelessWidget {
  const _RewardHistoryTab({
    required this.emptyText,
    required this.label,
    required this.rewards,
  });

  final String emptyText;
  final String label;
  final List<RewardModel> rewards;

  @override
  Widget build(BuildContext context) {
    if (rewards.isEmpty) {
      return Center(child: Text(emptyText));
    }

    return ListView.builder(
      itemCount: rewards.length,
      itemBuilder: (context, index) {
        return _RewardHistoryCard(label: label, reward: rewards[index]);
      },
    );
  }
}

class _RewardHistoryCard extends StatelessWidget {
  const _RewardHistoryCard({required this.label, required this.reward});

  final String label;
  final RewardModel reward;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -10,
            left: -25,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                reward.details.isEmpty ? 'Unknown Reward' : reward.details,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Valid Till: ${reward.expiredDate}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ],
      ),
    );
  }
}
