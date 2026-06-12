import 'package:ezcharge/models/reward_model.dart';
import 'package:ezcharge/services/reward_service.dart';
import 'package:ezcharge/viewmodels/charging/charging_reward_selection_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRewardService implements RewardServiceContract {
  _FakeRewardService({this.rewards = const []});

  final List<RewardModel> rewards;

  @override
  Future<CustomerRewardState?> fetchCurrentCustomerRewardState() async => null;

  @override
  Future<List<RewardModel>> fetchActiveRewards({DateTime? now}) async => [];

  @override
  Future<List<RewardModel>> fetchUsableRedeemedRewards({DateTime? now}) async {
    return rewards;
  }

  @override
  Future<RewardHistoryState> fetchRewardHistory({DateTime? now}) async {
    return const RewardHistoryState(expiredRewards: [], usedRewards: []);
  }

  @override
  Future<RewardRedeemResult> redeemReward({
    required String customerId,
    required RewardModel reward,
  }) {
    throw UnimplementedError();
  }
}

void main() {
  test('selects a redeemed reward and creates navigation result', () async {
    final reward = RewardModel(
      id: 'RWD1',
      details: 'RM30 charging discount',
      points: 300,
      expiredDate: DateTime(2099),
    );
    final viewModel = ChargingRewardSelectionViewModel(
      rewardService: _FakeRewardService(rewards: [reward]),
    );

    await viewModel.loadRewards();
    viewModel.selectReward(0);
    final selectedReward = viewModel.selectedReward();

    expect(viewModel.rewards, [reward]);
    expect(selectedReward?.rewardId, 'RWD1');
    expect(selectedReward?.discount, 30);
    expect(selectedReward?.toNavigationResult(), {
      'rewardID': 'RWD1',
      'discount': 30.0,
      'points': 300,
    });
  });
}
