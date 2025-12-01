import 'package:flutter/material.dart';
import 'dart:async';
import 'onboarding_screen.dart';
import 'dashboard_screen.dart';
import '../services/auth_service.dart';
import '../theme/colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Short delay so splash is visible, then route based on auth state
    Timer(const Duration(seconds: 1), () {
      final loggedIn = AuthService.instance.isLoggedIn();
      if (loggedIn) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.grass,
              size: 80,
              color: AppColors.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'Welcome to Poultry App',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Manage your farm efficiently',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textDark.withAlpha((0.7 * 255).round()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
