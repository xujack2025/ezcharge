import 'package:ezcharge/models/reward_model.dart';
import 'package:ezcharge/services/reward_service.dart';
import 'package:ezcharge/viewmodels/application/point_history_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRewardService implements RewardServiceContract {
  RewardHistoryState history = const RewardHistoryState(
    expiredRewards: [],
    usedRewards: [],
  );
  Object? error;

  @override
  Future<CustomerRewardState?> fetchCurrentCustomerRewardState() async {
    return null;
  }

  @override
  Future<List<RewardModel>> fetchActiveRewards({DateTime? now}) async {
    return const [];
  }

  @override
  Future<List<RewardModel>> fetchUsableRedeemedRewards({DateTime? now}) async {
    return const [];
  }

  @override
  Future<RewardHistoryState> fetchRewardHistory({DateTime? now}) async {
    final error = this.error;
    if (error != null) throw error;
    return history;
  }

  @override
  Future<RewardRedeemResult> redeemReward({
    required String customerId,
    required RewardModel reward,
  }) async {
    return const RewardRedeemResult(
      status: RewardRedeemStatus.success,
      pointBalance: 0,
      redeemedRewardIds: [],
    );
  }
}

void main() {
  group('PointHistoryViewModel', () {
    test('loads expired and used rewards from service', () async {
      final expiredReward = RewardModel(
        id: 'RWD1',
        details: 'Expired credit',
        points: 10,
        expiredDate: DateTime(2025),
      );
      final usedReward = RewardModel(
        id: 'RWD2',
        details: 'Used credit',
        points: 20,
        expiredDate: DateTime(2027),
      );
      final service = _FakeRewardService()
        ..history = RewardHistoryState(
          expiredRewards: [expiredReward],
          usedRewards: [usedReward],
        );
      final viewModel = PointHistoryViewModel(rewardService: service);

      await viewModel.loadRewardHistory();

      expect(viewModel.expiredRewards, [expiredReward]);
      expect(viewModel.usedRewards, [usedReward]);
      expect(viewModel.errorMessage, isNull);
    });

    test('maps service failure to friendly error', () async {
      final service = _FakeRewardService()..error = Exception('firestore');
      final viewModel = PointHistoryViewModel(rewardService: service);

      await viewModel.loadRewardHistory();

      expect(viewModel.expiredRewards, isEmpty);
      expect(viewModel.usedRewards, isEmpty);
      expect(viewModel.errorMessage, 'Failed to load reward history.');
    });
  });
}
