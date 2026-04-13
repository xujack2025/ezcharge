import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ezcharge/models/user_model.dart';

class CustomerModel extends UserModel {
  final String gender;
  final double walletBalance;
  final int pointBalance;
  final DateTime dateOfBirth;
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

  // ✅ Convert Firestore document to CustomerModel
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
      dateOfBirth: (data['DateOfBirth'] as Timestamp).toDate(),
      createdAt: data['CreatedAt'] ?? Timestamp.now(),
    );
  }

  // ✅ Convert CustomerModel to Firestore document format
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
      'DateOfBirth': Timestamp.fromDate(dateOfBirth),
      'CreatedAt': createdAt,
    };
  }
}
