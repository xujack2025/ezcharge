class EmergencyPaymentProfile {
  const EmergencyPaymentProfile({
    required this.customerId,
    required this.walletBalance,
    required this.pointBalance,
    this.cardNumber,
  });

  final String customerId;
  final double walletBalance;
  final int pointBalance;
  final String? cardNumber;
}

enum EmergencyPaymentMethod { card, wallet }

enum EmergencyPaymentProcessStatus {
  success,
  insufficientBalance,
  customerNotFound,
  failed,
}

class EmergencyPaymentProcessResult {
  const EmergencyPaymentProcessResult({
    required this.status,
    required this.paymentMethodLabel,
    required this.walletBalance,
  });

  final EmergencyPaymentProcessStatus status;
  final String paymentMethodLabel;
  final double walletBalance;
}

class EmergencyPaymentSuccessDetails {
  const EmergencyPaymentSuccessDetails({
    required this.customerId,
    required this.requestId,
    required this.duration,
  });

  final String customerId;
  final String requestId;
  final String duration;
}

class EmergencyPaymentHistoryDetail {
  const EmergencyPaymentHistoryDetail({
    required this.totalCost,
    required this.duration,
    required this.paymentMethod,
    required this.paymentId,
    required this.paidTime,
  });

  final double totalCost;
  final String duration;
  final String paymentMethod;
  final String paymentId;
  final DateTime? paidTime;
}
