import 'package:flutter/foundation.dart';

import '../../core/utils/app_logger.dart';
import '../../models/reward_model.dart';
import '../../services/reward_service.dart';

class ChargingRewardSelection {
  const ChargingRewardSelection({
    required this.rewardId,
    required this.discount,
    required this.points,
  });

  final String rewardId;
  final double discount;
  final int points;

  Map<String, dynamic> toNavigationResult() {
    return {'rewardID': rewardId, 'discount': discount, 'points': points};
  }
}

class ChargingRewardSelectionViewModel extends ChangeNotifier {
  ChargingRewardSelectionViewModel({RewardServiceContract? rewardService})
    : _rewardService = rewardService ?? RewardService();

  final RewardServiceContract _rewardService;

  List<RewardModel> _rewards = [];
  int? _selectedIndex;
  bool _isLoading = false;
  String? _errorMessage;

  List<RewardModel> get rewards => List.unmodifiable(_rewards);
  int? get selectedIndex => _selectedIndex;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadRewards() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _rewards = await _rewardService.fetchUsableRedeemedRewards();
      _selectedIndex = null;
    } catch (e) {
      AppLogger.error('Error loading redeemed charging rewards: $e');
      _rewards = [];
      _errorMessage = 'Failed to load rewards.';
    } finally {
      _setLoading(false);
    }
  }

  void selectReward(int index) {
    if (index < 0 || index >= _rewards.length) return;
    _selectedIndex = index;
    notifyListeners();
  }

  ChargingRewardSelection? selectedReward() {
    final index = _selectedIndex;
    if (index == null) return null;

    final reward = _rewards[index];
    return ChargingRewardSelection(
      rewardId: reward.id,
      discount: reward.points / 10,
      points: reward.points,
    );
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
