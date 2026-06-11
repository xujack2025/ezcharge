import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

class Driver extends UserModel {
  GeoPoint location;
  String status; // Available, Busy, Offline

  Driver({
    required this.location,
    required this.status,
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.phone,
  });

  factory Driver.fromMap(Map<String, dynamic> map) {
    return Driver(
      id: map['DriverID'] ?? '',
      firstName: map['FirstName'] ?? '',
      lastName: map['LastName'] ?? '',
      phone: map['PhoneNumber'] ?? '',
      location: map['Location'] ?? const GeoPoint(0.0, 0.0),
      status: map['Status'] ?? 'Offline',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'DriverID': id,
      'FirstName': firstName,
      'LastName': lastName,
      'PhoneNumber': phone,
      'Location': location,
      'Status': status,
    };
  }
}
