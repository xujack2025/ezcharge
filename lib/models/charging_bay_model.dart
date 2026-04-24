import 'package:cloud_firestore/cloud_firestore.dart';

enum BayStatus { available, occupied, outofservice }

enum CurrentType { ac, dc, undefined }

enum ChargerType { type2, ccs2, undefined }

class ChargingBay {
  final String chargerID;
  final String chargerName;
  final ChargerType chargerType;
  final double chargerVoltage;
  final CurrentType currentType;
  final double pricePerVoltage;
  final BayStatus status;

  ChargingBay({
    required this.chargerID,
    required this.chargerName,
    required this.chargerType,
    required this.chargerVoltage,
    required this.currentType,
    required this.pricePerVoltage,
    required this.status,
  });

  factory ChargingBay.fromMap(Map<String, dynamic> data) {
    return ChargingBay(
      chargerID: data['ChargerID'] ?? '',
      chargerName: data['ChargerName'] ?? '',
      chargerType: ChargerType.values.firstWhere(
        (e) => e.name == data['ChargerType'],
        orElse: () => ChargerType.undefined,
      ),
      chargerVoltage: (data['ChargerVoltage'] as num?)?.toDouble() ?? 0.0,
      currentType: CurrentType.values.firstWhere(
        (e) => e.name == data['CurrentType'],
        orElse: () => CurrentType.undefined,
      ),
      pricePerVoltage: (data['PriceperVoltage'] as num?)?.toDouble() ?? 0.0,
      status: BayStatus.values.firstWhere(
        (e) => e.name == data['Status'],
        orElse: () => BayStatus.outofservice,
      ),
    );
  }

  factory ChargingBay.fromFirestore(DocumentSnapshot doc) {
    return ChargingBay.fromMap(doc.data() as Map<String, dynamic>);
  }

  Map<String, dynamic> toMap() {
    return {
      'ChargerID': chargerID,
      'ChargerName': chargerName,
      'ChargerType': chargerType.name,
      'ChargerVoltage': chargerVoltage,
      'CurrentType': currentType.name,
      'PriceperVoltage': pricePerVoltage,
      'Status': status.name,
    };
  }
}
