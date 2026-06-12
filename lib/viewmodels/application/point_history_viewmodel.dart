import 'package:flutter/foundation.dart';

import '../../core/utils/app_logger.dart';
import '../../models/reward_model.dart';
import '../../services/reward_service.dart';

class PointHistoryViewModel extends ChangeNotifier {
  PointHistoryViewModel({RewardServiceContract? rewardService})
    : _rewardService = rewardService ?? RewardService();

  final RewardServiceContract _rewardService;

  List<RewardModel> _expiredRewards = const [];
  List<RewardModel> _usedRewards = const [];
  bool _isLoading = false;
  String? _errorMessage;

  List<RewardModel> get expiredRewards => List.unmodifiable(_expiredRewards);
  List<RewardModel> get usedRewards => List.unmodifiable(_usedRewards);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadRewardHistory() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final history = await _rewardService.fetchRewardHistory();
      _expiredRewards = history.expiredRewards;
      _usedRewards = history.usedRewards;
    } catch (e) {
      AppLogger.error('Error loading reward history: $e');
      _expiredRewards = const [];
      _usedRewards = const [];
      _errorMessage = 'Failed to load reward history.';
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
