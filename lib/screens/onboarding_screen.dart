import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../theme/colors.dart';
import '../services/locale_service.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          PageView(
            children: [
              buildPage(
                title: LocaleService.instance.t('onboard_title_1'),
                description: LocaleService.instance.t('onboard_desc_1'),
                color: AppColors.primaryLight,
              ),
              buildPage(
                title: LocaleService.instance.t('onboard_title_2'),
                description: LocaleService.instance.t('onboard_desc_2'),
                color: AppColors.secondaryLight,
              ),
              buildPage(
                title: LocaleService.instance.t('onboard_title_3'),
                description: LocaleService.instance.t('onboard_desc_3'),
                color: AppColors.accent,
              ),
            ],
          ),

          // Get Started Button
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                child: Text(
                  LocaleService.instance.t('get_started'),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPage({
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      color: color,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
