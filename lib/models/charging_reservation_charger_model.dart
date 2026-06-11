import 'package:cloud_firestore/cloud_firestore.dart';

class ChargingReservationCharger {
  const ChargingReservationCharger({
    required this.id,
    required this.name,
    required this.type,
    required this.power,
    required this.price,
    required this.status,
  });

  final String id;
  final String name;
  final String type;
  final String power;
  final String price;
  final String status;

  bool get isAvailable => status == "Available";

  factory ChargingReservationCharger.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return ChargingReservationCharger(
      id: doc.id,
      name: data["ChargerName"]?.toString() ?? "Unknown Bay",
      type: data["ChargerType"]?.toString() ?? "Unknown Type",
      power:
          "${data["ChargerVoltage"]?.toString() ?? "0"}kW ${data["CurrentType"]?.toString() ?? ""}",
      price: "RM ${data["PricePerVoltage"]?.toString() ?? "0.00"}/kW",
      status: data["Status"]?.toString() ?? "Unknown",
    );
  }
}
