import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ezcharge/models/user_model.dart';

class CustomerModel extends UserModel {
  final String gender;
  final double walletBalance;
  final int pointBalance;
  final String dateOfBirth;
  final Timestamp createdAt;
  final String email;

  CustomerModel({
    required this.gender,
    required this.walletBalance,
    required this.pointBalance,
    required this.dateOfBirth,
    required this.createdAt,
    required this.email,
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.phone,
  });

  factory CustomerModel.fromFirestore(Map<String, dynamic> data) {
    return CustomerModel(
      id: data['CustomerID'] ?? '',
      firstName: data['FirstName'] ?? '',
      lastName: data['LastName'] ?? '',
      gender: data['Gender'] ?? '',
      email: data['EmailAddress'] ?? '',
      phone: data['PhoneNumber'] ?? '',
      walletBalance: (data['WalletBalance'] ?? 0.0).toDouble(),
      pointBalance: data['PointBalance'] ?? 0,
      dateOfBirth: data['DateOfBirth']?.toString() ?? '',
      createdAt: data['CreatedAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'CustomerID': id,
      'FirstName': firstName,
      'LastName': lastName,
      'Gender': gender,
      'EmailAddress': email,
      'PhoneNumber': phone,
      'WalletBalance': walletBalance,
      'PointBalance': pointBalance,
      'DateOfBirth': dateOfBirth,
      'CreatedAt': createdAt,
    };
  }
}
