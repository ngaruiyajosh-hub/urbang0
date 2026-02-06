import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';

/// Splash Screen for UrbanGo
/// Shows app logo while checking authentication state
/// Redirects to appropriate screen based on login status
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _checkAuthAndNavigate();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Minimum display duration for brand recognition
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      // Check if user is authenticated
      final isAuthenticated = _authService.isAuthenticated;

      if (isAuthenticated) {
        // User is logged in, get their profile to determine role
        final user = _authService.currentUser;
        if (user != null) {
          final profile = await _authService.getUserProfile(user.id);
          final userRole = (profile?['role'] ?? 'Passenger')
              .toString()
              .trim()
              .toLowerCase();

          if (!mounted) return;

          // Navigate to appropriate home screen based on role
          if (userRole == 'driver') {
            Navigator.of(context).pushReplacementNamed(AppRoutes.driverHome);
          } else {
            Navigator.of(context).pushReplacementNamed(AppRoutes.passengerHome);
          }
        } else {
          // No user found, go to login
          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed(AppRoutes.login);
        }
      } else {
        // User not authenticated, go to login
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    } catch (e) {
      debugPrint('❌ Splash screen auth check error: $e');
      // On error, navigate to login screen
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withAlpha(204),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Spacer to push content to center
              const Spacer(),

              // Logo with fade animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: CustomImageWidget(
                  imageUrl:
                      'assets/images/URBAN_GO_logo_final-1770227236338.png',
                  width: 60.w,
                  fit: BoxFit.contain,
                  semanticLabel: 'Urban Go logo',
                ),
              ),

              SizedBox(height: 4.h),

              // Loading indicator
              FadeTransition(
                opacity: _fadeAnimation,
                child: SizedBox(
                  width: 10.w,
                  height: 10.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.0,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withAlpha(230),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 2.h),

              // Loading text
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'Loading...',
                  style: TextStyle(
                    color: Colors.white.withAlpha(230),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              // Spacer to push content to center
              const Spacer(),

              // App version or tagline (optional)
              Padding(
                padding: EdgeInsets.only(bottom: 3.h),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'Your Urban Transport Solution',
                    style: TextStyle(
                      color: Colors.white.withAlpha(179),
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
