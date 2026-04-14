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

  // Convert Firestore document to AdminModel
  factory AdminModel.fromFirestore(Map<String, dynamic> data) {
    return AdminModel(
      id: data['AdminID']?.toString() ?? '',
      firstName: data['FirstName']?.toString() ?? '',
      lastName: data['LastName']?.toString() ?? '',
      gender: data['Gender']?.toString() ?? '',
      email: data['EmailAddress']?.toString() ?? '',
      phone: data['PhoneNumber']?.toString() ?? '',
      dateOfBirth: data['DateOfBirth']?.toString() ?? '',
      createdAt: data['CreatedAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  // Convert AdminModel to Firestore document format
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
