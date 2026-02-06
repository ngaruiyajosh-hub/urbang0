// User role enum
enum UserRole {
  driver,
  conductor,
  passenger,
}

// User model
class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String password;
  final UserRole role;
  final double walletBalance;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.role,
    this.walletBalance = 0.0,
    required this.createdAt,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'role': role.toString(),
      'walletBalance': walletBalance,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      password: json['password'],
      role: UserRole.values.firstWhere(
        (e) => e.toString() == json['role'],
      ),
      walletBalance: json['walletBalance'] ?? 0.0,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
