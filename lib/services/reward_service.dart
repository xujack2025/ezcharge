import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/utils/app_logger.dart';
import '../models/reward_model.dart';

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

  Future<RewardRedeemResult> redeemReward({
    required String customerId,
    required RewardModel reward,
  });
}

class RewardService implements RewardServiceContract {
  RewardService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  @override
  Future<CustomerRewardState?> fetchCurrentCustomerRewardState() async {
    final phoneNumber = _auth.currentUser?.phoneNumber;
    if (phoneNumber == null || phoneNumber.isEmpty) return null;

    final querySnapshot = await _firestore
        .collection('Customers')
        .where('PhoneNumber', isEqualTo: phoneNumber)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return null;

    return _customerRewardStateFromSnapshot(querySnapshot.docs.first);
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
    QueryDocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    return CustomerRewardState(
      customerId: (data['CustomerID'] ?? snapshot.id).toString(),
      pointBalance: _parseInt(data['PointBalance']),
      redeemedRewardIds: _parseStringList(data['RedeemedRewards']),
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
}
