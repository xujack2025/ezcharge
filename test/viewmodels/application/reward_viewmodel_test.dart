import 'package:ezcharge/models/reward_model.dart';
import 'package:ezcharge/services/reward_service.dart';
import 'package:ezcharge/viewmodels/application/reward_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeRewardService implements RewardServiceContract {
  FakeRewardService({
    this.customerState,
    this.rewards = const [],
    this.redeemResult,
  });

  CustomerRewardState? customerState;
  List<RewardModel> rewards;
  RewardRedeemResult? redeemResult;
  String? redeemedCustomerId;
  RewardModel? redeemedReward;
  int redeemCallCount = 0;

  @override
  Future<CustomerRewardState?> fetchCurrentCustomerRewardState() async {
    return customerState;
  }

  @override
  Future<List<RewardModel>> fetchActiveRewards({DateTime? now}) async {
    return rewards;
  }

  @override
  Future<List<RewardModel>> fetchUsableRedeemedRewards({DateTime? now}) async {
    return rewards;
  }

  @override
  Future<RewardRedeemResult> redeemReward({
    required String customerId,
    required RewardModel reward,
  }) async {
    redeemCallCount++;
    redeemedCustomerId = customerId;
    redeemedReward = reward;
    return redeemResult ??
        RewardRedeemResult(
          status: RewardRedeemStatus.success,
          pointBalance: reward.points,
          redeemedRewardIds: [reward.id],
        );
  }
}

void main() {
  final reward = RewardModel(
    id: 'RWD1',
    details: 'Free charging credit',
    points: 20,
    expiredDate: DateTime(2099),
  );

  group('RewardViewModel', () {
    test('loads customer reward state and active rewards', () async {
      final service = FakeRewardService(
        customerState: const CustomerRewardState(
          customerId: 'CUS1',
          pointBalance: 100,
          redeemedRewardIds: ['RWD0'],
        ),
        rewards: [reward],
      );
      final viewModel = RewardViewModel(rewardService: service);

      await viewModel.loadRewards();

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.customerId, 'CUS1');
      expect(viewModel.customerPoints, 100);
      expect(viewModel.redeemedRewardIds, ['RWD0']);
      expect(viewModel.rewards, [reward]);
    });

    test('redeems reward and updates local state', () async {
      final service = FakeRewardService(
        customerState: const CustomerRewardState(
          customerId: 'CUS1',
          pointBalance: 100,
          redeemedRewardIds: [],
        ),
        rewards: [reward],
        redeemResult: const RewardRedeemResult(
          status: RewardRedeemStatus.success,
          pointBalance: 120,
          redeemedRewardIds: ['RWD1'],
        ),
      );
      final viewModel = RewardViewModel(rewardService: service);

      await viewModel.loadRewards();
      final outcome = await viewModel.redeemReward(reward);

      expect(outcome, RewardRedeemOutcome.success);
      expect(service.redeemCallCount, 1);
      expect(service.redeemedCustomerId, 'CUS1');
      expect(service.redeemedReward, reward);
      expect(viewModel.customerPoints, 120);
      expect(viewModel.isRedeemed('RWD1'), isTrue);
      expect(viewModel.errorMessage, isNull);
    });

    test(
      'does not call service when reward is already redeemed locally',
      () async {
        final service = FakeRewardService(
          customerState: const CustomerRewardState(
            customerId: 'CUS1',
            pointBalance: 100,
            redeemedRewardIds: ['RWD1'],
          ),
          rewards: [reward],
        );
        final viewModel = RewardViewModel(rewardService: service);

        await viewModel.loadRewards();
        final outcome = await viewModel.redeemReward(reward);

        expect(outcome, RewardRedeemOutcome.alreadyRedeemed);
        expect(service.redeemCallCount, 0);
        expect(viewModel.customerPoints, 100);
      },
    );
  });
}
