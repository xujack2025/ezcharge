enum UserRole { admin, customer }

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
