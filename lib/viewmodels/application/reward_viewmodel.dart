import 'package:flutter/foundation.dart';

import '../../core/utils/app_logger.dart';
import '../../models/reward_model.dart';
import '../../services/reward_service.dart';

enum RewardRedeemOutcome { success, alreadyRedeemed, failed }

class RewardViewModel extends ChangeNotifier {
  RewardViewModel({RewardServiceContract? rewardService})
    : _rewardService = rewardService ?? RewardService();

  final RewardServiceContract _rewardService;

  int _customerPoints = 0;
  String _customerId = '';
  List<String> _redeemedRewardIds = [];
  List<RewardModel> _rewards = [];
  bool _isLoading = false;
  String? _errorMessage;

  int get customerPoints => _customerPoints;
  String get customerId => _customerId;
  List<String> get redeemedRewardIds => List.unmodifiable(_redeemedRewardIds);
  List<RewardModel> get rewards => List.unmodifiable(_rewards);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool isRedeemed(String rewardId) {
    return _redeemedRewardIds.contains(rewardId);
  }

  Future<void> loadRewards() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final results = await Future.wait<Object?>([
        _rewardService.fetchCurrentCustomerRewardState(),
        _rewardService.fetchActiveRewards(),
      ]);

      final customerState = results[0] as CustomerRewardState?;
      if (customerState != null) {
        _customerId = customerState.customerId;
        _customerPoints = customerState.pointBalance;
        _redeemedRewardIds = customerState.redeemedRewardIds;
      }

      _rewards = results[1] as List<RewardModel>;
    } catch (e) {
      AppLogger.error('Error loading rewards: $e');
      _errorMessage = 'Failed to load rewards.';
    } finally {
      _setLoading(false);
    }
  }

  Future<RewardRedeemOutcome> redeemReward(RewardModel reward) async {
    if (_redeemedRewardIds.contains(reward.id)) {
      return RewardRedeemOutcome.alreadyRedeemed;
    }

    if (_customerId.isEmpty) {
      _errorMessage = 'Customer profile not found.';
      notifyListeners();
      return RewardRedeemOutcome.failed;
    }

    try {
      final result = await _rewardService.redeemReward(
        customerId: _customerId,
        reward: reward,
      );

      _customerPoints = result.pointBalance;
      _redeemedRewardIds = result.redeemedRewardIds;

      switch (result.status) {
        case RewardRedeemStatus.success:
          _errorMessage = null;
          notifyListeners();
          return RewardRedeemOutcome.success;
        case RewardRedeemStatus.alreadyRedeemed:
          notifyListeners();
          return RewardRedeemOutcome.alreadyRedeemed;
        case RewardRedeemStatus.customerNotFound:
          _errorMessage = 'Customer profile not found.';
          notifyListeners();
          return RewardRedeemOutcome.failed;
      }
    } catch (e) {
      AppLogger.error('Error redeeming reward: $e');
      _errorMessage = 'Failed to redeem reward.';
      notifyListeners();
      return RewardRedeemOutcome.failed;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
