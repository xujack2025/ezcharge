class ChargingSessionInfo {
  const ChargingSessionInfo({
    required this.customerId,
    required this.stationId,
    required this.chargerId,
    required this.stationName,
    required this.chargerName,
    required this.chargerType,
  });

  final String customerId;
  final String stationId;
  final String chargerId;
  final String stationName;
  final String chargerName;
  final String chargerType;

  bool get hasReservation => customerId.isNotEmpty && chargerId.isNotEmpty;
}
