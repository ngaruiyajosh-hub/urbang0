import 'package:flutter/material.dart';
import 'package:urban_go/screens/auth/login_screen.dart';
import 'package:urban_go/screens/auth/register_screen.dart';
import 'package:urban_go/services/auth_service.dart';
import 'package:urban_go/models/user_model.dart';

void main() {
  // Initialize demo users
  _initializeDemoUsers();
  runApp(const MyApp());
}

void _initializeDemoUsers() async {
  // Create demo users for testing
  await AuthService.register(
    name: 'Josh Passenger',
    email: 'passenger@demo.com',
    phone: '0712940967',
    password: 'password123',
    role: UserRole.passenger,
  );

  await AuthService.register(
    name: 'Driver Josh',
    email: 'driver@demo.com',
    phone: '9876543211',
    password: 'password123',
    role: UserRole.driver,
  );

  await AuthService.register(
    name: 'Conductor Josh',
    email: 'conductor@demo.com',
    phone: '9876543212',
    password: 'password123',
    role: UserRole.conductor,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Urban Go',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
      },
    );
  }
}
