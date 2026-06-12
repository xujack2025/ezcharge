import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/utils/app_logger.dart';
import '../models/reward_model.dart';
import 'auth_service.dart';

enum RewardRedeemStatus { success, alreadyRedeemed, customerNotFound }

class RewardRedeemResult {
  const RewardRedeemResult({
    required this.status,
    required this.pointBalance,
    required this.redeemedRewardIds,
  });

  final RewardRedeemStatus status;
  final int pointBalance;
  final List<String> redeemedRewardIds;
}

abstract class RewardServiceContract {
  Future<CustomerRewardState?> fetchCurrentCustomerRewardState();

  Future<List<RewardModel>> fetchActiveRewards({DateTime? now});

  Future<List<RewardModel>> fetchUsableRedeemedRewards({DateTime? now});

  Future<RewardHistoryState> fetchRewardHistory({DateTime? now});

  Future<RewardRedeemResult> redeemReward({
    required String customerId,
    required RewardModel reward,
  });
}

class RewardService implements RewardServiceContract {
  RewardService({
    FirebaseFirestore? firestore,
    AuthServiceContract? authService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _authService = authService ?? AuthService();

  final FirebaseFirestore _firestore;
  final AuthServiceContract _authService;

  @override
  Future<CustomerRewardState?> fetchCurrentCustomerRewardState() async {
    final customerId = await _authService.getCurrentCustomerId();
    if (customerId == null || customerId.isEmpty) return null;

    final doc = await _firestore.collection('Customers').doc(customerId).get();
    if (!doc.exists) return null;

    return _customerRewardStateFromSnapshot(doc);
  }

  @override
  Future<List<RewardModel>> fetchActiveRewards({DateTime? now}) async {
    final currentTime = now ?? DateTime.now();
    final querySnapshot = await _firestore.collection('Rewards').get();

    return querySnapshot.docs
        .map((doc) => RewardModel.fromFirestore(doc.data(), documentId: doc.id))
        .where((reward) => reward.isActiveAt(currentTime))
        .toList();
  }

  @override
  Future<List<RewardModel>> fetchUsableRedeemedRewards({DateTime? now}) async {
    final customerState = await fetchCurrentCustomerRewardState();
    if (customerState == null) return [];

    final currentTime = now ?? DateTime.now();
    final rewards = <RewardModel>[];
    for (final rewardId in customerState.redeemedRewardIds) {
      if (customerState.usedRewardIds.contains(rewardId)) continue;

      final rewardDoc = await _firestore
          .collection('Rewards')
          .doc(rewardId)
          .get();
      if (!rewardDoc.exists) continue;

      final reward = RewardModel.fromFirestore(
        rewardDoc.data() ?? {},
        documentId: rewardDoc.id,
      );
      if (reward.isActiveAt(currentTime)) {
        rewards.add(reward);
      }
    }

    return rewards;
  }

  @override
  Future<RewardHistoryState> fetchRewardHistory({DateTime? now}) async {
    final customerState = await fetchCurrentCustomerRewardState();
    if (customerState == null) {
      return const RewardHistoryState(expiredRewards: [], usedRewards: []);
    }

    final currentTime = now ?? DateTime.now();
    final expiredRewards = <RewardModel>[];
    final usedRewards = <RewardModel>[];

    for (final rewardId in customerState.redeemedRewardIds) {
      final reward = await _fetchRewardById(rewardId);
      if (reward != null && !reward.isActiveAt(currentTime)) {
        expiredRewards.add(reward);
      }
    }

    for (final rewardId in customerState.usedRewardIds) {
      final reward = await _fetchRewardById(rewardId);
      if (reward != null) {
        usedRewards.add(reward);
      }
    }

    return RewardHistoryState(
      expiredRewards: expiredRewards,
      usedRewards: usedRewards,
    );
  }

  @override
  Future<RewardRedeemResult> redeemReward({
    required String customerId,
    required RewardModel reward,
  }) async {
    final customerRef = _firestore.collection('Customers').doc(customerId);

    return _firestore.runTransaction((transaction) async {
      final customerSnapshot = await transaction.get(customerRef);
      if (!customerSnapshot.exists) {
        AppLogger.warning(
          'Reward redeem failed. Customer not found: $customerId',
        );
        return const RewardRedeemResult(
          status: RewardRedeemStatus.customerNotFound,
          pointBalance: 0,
          redeemedRewardIds: [],
        );
      }

      final data = customerSnapshot.data() ?? {};
      final redeemedRewardIds = _parseStringList(data['RedeemedRewards']);
      final pointBalance = _parseInt(data['PointBalance']);

      if (redeemedRewardIds.contains(reward.id)) {
        return RewardRedeemResult(
          status: RewardRedeemStatus.alreadyRedeemed,
          pointBalance: pointBalance,
          redeemedRewardIds: redeemedRewardIds,
        );
      }

      final updatedRedeemedRewards = [...redeemedRewardIds, reward.id];
      final updatedPoints = pointBalance + reward.points;

      transaction.update(customerRef, {
        'PointBalance': updatedPoints,
        'RedeemedRewards': updatedRedeemedRewards,
      });

      return RewardRedeemResult(
        status: RewardRedeemStatus.success,
        pointBalance: updatedPoints,
        redeemedRewardIds: updatedRedeemedRewards,
      );
    });
  }

  CustomerRewardState _customerRewardStateFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    return CustomerRewardState(
      customerId: (data['CustomerID'] ?? snapshot.id).toString(),
      pointBalance: _parseInt(data['PointBalance']),
      redeemedRewardIds: _parseStringList(data['RedeemedRewards']),
      usedRewardIds: _parseStringList(data['UsedReward']),
    );
  }

  static int _parseInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static List<String> _parseStringList(Object? value) {
    if (value is Iterable) {
      return value.map((item) => item.toString()).toList();
    }
    return [];
  }

  Future<RewardModel?> _fetchRewardById(String rewardId) async {
    final rewardDoc = await _firestore
        .collection('Rewards')
        .doc(rewardId)
        .get();
    if (!rewardDoc.exists) return null;

    return RewardModel.fromFirestore(
      rewardDoc.data() ?? {},
      documentId: rewardDoc.id,
    );
  }
}
