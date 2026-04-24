abstract class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String phone;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
  });
}

enum UserRole { admin, customer }
