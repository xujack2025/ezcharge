import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ezcharge/models/user_model.dart';

class AdminModel extends UserModel {
  final String gender;
  final String dateOfBirth;
  final Timestamp createdAt;
  final String email;

  AdminModel({
    required this.gender,
    required this.dateOfBirth,
    required this.createdAt,
    required this.email,
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.phone,
  });

  // ✅ Convert Firestore document to AdminModel
  factory AdminModel.fromFirestore(Map<String, dynamic> data) {
    return AdminModel(
      id: data['AdminID'] ?? '',
      firstName: data['FirstName'] ?? '',
      lastName: data['LastName'] ?? '',
      gender: data['Gender'] ?? '',
      email: data['EmailAddress'] ?? '',
      phone: data['PhoneNumber'] ?? '',
      dateOfBirth: data['DateOfBirth'] ?? '',
      createdAt: data['CreatedAt'] ?? Timestamp.now(),
    );
  }

  // ✅ Convert AdminModel to Firestore document format
  Map<String, dynamic> toFirestore() {
    return {
      'AdminID': id,
      'FirstName': firstName,
      'LastName': lastName,
      'Gender': gender,
      'EmailAddress': email,
      'PhoneNumber': phone,
      'DateOfBirth': dateOfBirth,
      'CreatedAt': createdAt,
    };
  }
}
