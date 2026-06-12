class ProfilePaymentCardInput {
  const ProfilePaymentCardInput({
    required this.cardNumber,
    required this.expiredDate,
    required this.cvv,
  });

  final String cardNumber;
  final String expiredDate;
  final String cvv;

  Map<String, dynamic> toFirestore() {
    return {'CardNumber': cardNumber, 'ExpiredDate': expiredDate, 'CVV': cvv};
  }
}

class ProfilePaymentMethodProfile {
  const ProfilePaymentMethodProfile({
    required this.customerId,
    required this.walletBalance,
    this.cardNumber,
  });

  final String customerId;
  final double walletBalance;
  final String? cardNumber;
}

class ProfilePaymentHistoryFeed {
  const ProfilePaymentHistoryFeed({
    required this.customerId,
    required this.items,
  });

  final String customerId;
  final Stream<List<ProfilePaymentHistoryItem>> items;
}

class ProfilePaymentHistoryItem {
  const ProfilePaymentHistoryItem({
    required this.paymentId,
    required this.stationName,
    required this.chargerName,
    required this.chargerType,
    required this.duration,
    required this.paymentMethod,
    required this.totalCost,
    required this.paidTime,
  });

  final String paymentId;
  final String stationName;
  final String chargerName;
  final String chargerType;
  final String duration;
  final String paymentMethod;
  final double totalCost;
  final DateTime? paidTime;
}
