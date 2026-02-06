import 'package:urban_go/models/user_model.dart';

class AuthService {
  // Simulated user database (in production, use real backend)
  static final Map<String, User> _userDatabase = {};
  static User? _currentUser;

  // Get current logged-in user
  static User? getCurrentUser() {
    return _currentUser;
  }

  // Register a new user
  static Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Check if email already exists
    if (_userDatabase.values.any((user) => user.email == email)) {
      return false;
    }

    final newUser = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      phone: phone,
      password: password,
      role: role,
      createdAt: DateTime.now(),
    );

    _userDatabase[newUser.id] = newUser;
    return true;
  }

  // Login user
  static Future<bool> login({
    required String email,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final user = _userDatabase.values.firstWhere(
        (user) => user.email == email && user.password == password,
      );
      _currentUser = user;
      return true;
    } catch (e) {
      return false;
    }
  }

  // Logout user
  static void logout() {
    _currentUser = null;
  }

  // Check if user is logged in
  static bool isLoggedIn() {
    return _currentUser != null;
  }

  // Get user by ID
  static User? getUserById(String id) {
    return _userDatabase[id];
  }
}
