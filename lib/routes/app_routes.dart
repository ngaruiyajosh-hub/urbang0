import 'package:flutter/material.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/passenger_home_screen/passenger_home_screen.dart';
import '../presentation/more_screen/more_screen.dart';
import '../presentation/driver_home_screen/driver_home_screen.dart';
import '../presentation/driver_more_screen/driver_more_screen.dart';
import '../presentation/splash_screen/splash_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String splashScreen = '/splash-screen';
  static const String login = '/login-screen';
  static const String passengerHome = '/passenger-home-screen';
  static const String more = '/more-screen';
  static const String driverHome = '/driver-home-screen';
  static const String driverMore = '/driver-more-screen';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    splashScreen: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
    passengerHome: (context) => const PassengerHomeScreen(),
    more: (context) => const MoreScreen(),
    driverHome: (context) => const DriverHomeScreen(),
    driverMore: (context) => const DriverMoreScreen(),
  };
}
