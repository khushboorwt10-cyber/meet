class UserModel {
  final String? name;
  final String email;
  final String? phone;
  final String password;

  UserModel({
    this.name,
    required this.email,
    this.phone,
    required this.password,
  });

  // Register ke liye JSON
  Map<String, dynamic> toRegisterJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
    };
  }

  // Login ke liye JSON
  Map<String, dynamic> toLoginJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}