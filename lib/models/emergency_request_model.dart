import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencyRequest {
  String requestID;
  String customerID;
  GeoPoint location; // Store as GeoPoint in Firestore
  String address; // Separate field to store the human-readable address
  String bookingReason;
  String? imageUrl;
  String preferredTime;
  String status; // Pending, Upcoming, Charging, Payment, Processing, Completed
  String? driverID;
  int eta;
  double kWhUsed;
  String? chatID;

  EmergencyRequest({
    required this.requestID,
    required this.customerID,
    required this.location, // GeoPoint for Firestore
    required this.address, // String for UI display
    required this.bookingReason,
    this.imageUrl,
    required this.preferredTime,
    required this.status,
    this.driverID,
    this.eta = 0,
    this.kWhUsed = 0,
    this.chatID,
  });

  factory EmergencyRequest.fromMap(Map<String, dynamic> map) {
    return EmergencyRequest(
      requestID: map['RequestID'] ?? '',
      customerID: map['CustomerID'] ?? '',
      location: map['Location'] is GeoPoint
          ? map['Location'] as GeoPoint
          : const GeoPoint(0, 0), // Handle GeoPoint
      address: map['Address'] ?? '', // Readable address for UI
      bookingReason: map['BookingReason'] ?? '',
      imageUrl: map['ImageUrl'],
      preferredTime: map['PreferredTime'] ?? '',
      status: map['Status'] ?? 'Pending',
      driverID: map['DriverID'] ?? '',
      eta: (map['Eta'] as num?)?.toInt() ?? 0,
      kWhUsed: (map['KWhUsed'] as num?)?.toDouble() ?? 0.0,
      chatID: map['ChatID'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'RequestID': requestID,
      'CustomerID': customerID,
      'Location': location, // Store as GeoPoint
      'Address': address, // Store human-readable address
      'BookingReason': bookingReason,
      'ImageUrl': imageUrl,
      'PreferredTime': preferredTime,
      'Status': status,
      'DriverID': driverID,
      'Eta': eta,
      'KWhUsed': kWhUsed,
      'ChatID': chatID,
    };
  }
}
