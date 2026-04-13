import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ezcharge/models/user_model.dart';

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

  // Convert to Firestore
  Map<String, dynamic> toMap() {
    return {
      'driverID': id,
      'FirstName': firstName,
      'LastName': lastName,
      'phone': phone,
      'location': location, // ✅ Now storing as GeoPoint
      'status': status,
    };
  }

  // Convert from Firestore
  factory Driver.fromMap(Map<String, dynamic> map) {
    return Driver(
      id: map['driverID'] ?? '',
      firstName: map['FirstName'] ?? '',
      lastName: map['LastName'] ?? '',
      phone: map['PhoneNumber'] ?? '',
      location:
          map['location'] ?? GeoPoint(0.0, 0.0), // ✅ Ensure default GeoPoint
      status: map['status'] ?? 'Offline',
    );
  }
}
