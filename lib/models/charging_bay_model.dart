import 'package:cloud_firestore/cloud_firestore.dart';

class ChargingBay {
  String chargerID;
  String chargerName;
  String chargerType;
  double chargerVoltage;
  String currentType;
  double pricePerVoltage;
  String status;

  ChargingBay({
    required this.chargerID,
    required this.chargerName,
    required this.chargerType,
    required this.chargerVoltage,
    required this.currentType,
    required this.pricePerVoltage,
    required this.status,
  });

  factory ChargingBay.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return ChargingBay(
      chargerID: data['ChargerID'] ?? '',
      chargerName: data['ChargerName'] ?? '',
      chargerType: data['ChargerType'] ?? '',
      chargerVoltage: double.tryParse(data['ChargerVoltage'].toString()) ?? 0,
      currentType: data['CurrentType'] ?? '',
      pricePerVoltage:
          double.tryParse(data['PriceperVoltage'].toString()) ?? 0.0,
      status: data['Status'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ChargerID': chargerID,
      'ChargerName': chargerName,
      'ChargerType': chargerType,
      'ChargerVoltage': chargerVoltage,
      'CurrentType': currentType,
      'PriceperVoltage': pricePerVoltage,
      'Status': status,
    };
  }
}
