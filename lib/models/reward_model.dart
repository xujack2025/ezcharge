import 'package:cloud_firestore/cloud_firestore.dart';

class RewardModel {
  const RewardModel({
    required this.id,
    required this.details,
    required this.points,
    required this.expiredDate,
  });

  final String id;
  final String details;
  final int points;
  final DateTime expiredDate;

  bool isActiveAt(DateTime dateTime) {
    return expiredDate.isAfter(dateTime);
  }

  factory RewardModel.fromFirestore(
    Map<String, dynamic> data, {
    String? documentId,
  }) {
    final expiredDate = data['ExpiredDate'];

    return RewardModel(
      id: (data['RewardID'] ?? documentId ?? '').toString(),
      details: (data['RewardDetails'] ?? '').toString(),
      points: _parseInt(data['Points']),
      expiredDate: expiredDate is Timestamp
          ? expiredDate.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static int _parseInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class CustomerRewardState {
  const CustomerRewardState({
    required this.customerId,
    required this.pointBalance,
    required this.redeemedRewardIds,
    this.usedRewardIds = const [],
  });

  final String customerId;
  final int pointBalance;
  final List<String> redeemedRewardIds;
  final List<String> usedRewardIds;
}

class RewardHistoryState {
  const RewardHistoryState({
    required this.expiredRewards,
    required this.usedRewards,
  });

  final List<RewardModel> expiredRewards;
  final List<RewardModel> usedRewards;
}
