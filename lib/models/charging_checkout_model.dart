class ChargingCheckoutDetails {
  const ChargingCheckoutDetails({
    required this.customerId,
    required this.chargerId,
    required this.stationId,
    required this.reservationId,
    required this.reservationStatus,
    required this.stationName,
    required this.chargerName,
    required this.chargerType,
    required this.currentType,
    required this.chargerVoltage,
    required this.pricePerVoltage,
    required this.startTime,
  });

  final String customerId;
  final String chargerId;
  final String stationId;
  final String reservationId;
  final String reservationStatus;
  final String stationName;
  final String chargerName;
  final String chargerType;
  final String currentType;
  final double chargerVoltage;
  final double pricePerVoltage;
  final DateTime startTime;

  bool get canCheckOut => reservationStatus == 'Ended';
}

class ChargingCheckInDetails {
  const ChargingCheckInDetails({
    required this.customerId,
    required this.chargerId,
    required this.stationId,
    required this.reservationStatus,
    required this.stationName,
    required this.chargerName,
    required this.chargerType,
    required this.pricePerVoltage,
    required this.startTime,
  });

  final String customerId;
  final String chargerId;
  final String stationId;
  final String reservationStatus;
  final String stationName;
  final String chargerName;
  final String chargerType;
  final double pricePerVoltage;
  final DateTime startTime;

  bool get canCheckIn =>
      reservationStatus == 'Upcoming' && DateTime.now().isAfter(startTime);
}

class ChargingPaymentSummaryDetails {
  const ChargingPaymentSummaryDetails({
    required this.customerId,
    required this.stationId,
    required this.chargerId,
    required this.stationName,
    required this.chargerName,
    required this.chargerType,
    required this.stationImageUrl,
    required this.reservationStatus,
  });

  final String customerId;
  final String stationId;
  final String chargerId;
  final String stationName;
  final String chargerName;
  final String chargerType;
  final String stationImageUrl;
  final String reservationStatus;
}

class ChargingPaymentProfile {
  const ChargingPaymentProfile({
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

class ChargingPaymentHistoryDetails {
  const ChargingPaymentHistoryDetails({
    required this.customerId,
    required this.duration,
    required this.stationName,
    required this.chargerName,
    required this.chargerType,
  });

  final String customerId;
  final String duration;
  final String stationName;
  final String chargerName;
  final String chargerType;
}

class ChargingPaymentHistoryDetail {
  const ChargingPaymentHistoryDetail({
    required this.totalCost,
    required this.stationName,
    required this.chargerName,
    required this.chargerType,
    required this.duration,
    required this.paymentMethod,
    required this.paymentId,
    required this.paidTime,
  });

  final double totalCost;
  final String stationName;
  final String chargerName;
  final String chargerType;
  final String duration;
  final String paymentMethod;
  final String paymentId;
  final DateTime? paidTime;
}

enum ChargingPaymentMethod { card, wallet }

enum ChargingPaymentProcessStatus {
  success,
  insufficientBalance,
  customerNotFound,
  failed,
}

class ChargingPaymentProcessResult {
  const ChargingPaymentProcessResult({
    required this.status,
    required this.paymentMethodLabel,
    required this.walletBalance,
  });

  final ChargingPaymentProcessStatus status;
  final String paymentMethodLabel;
  final double walletBalance;
}
