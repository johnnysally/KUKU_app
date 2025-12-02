import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'signup_screen.dart';
import 'dashboard_screen.dart';
import '../services/auth_service.dart';
import '../theme/colors.dart';
import '../widgets/localized_text.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;
  late Box usersBox;

  @override
  void initState() {
    super.initState();
    usersBox = Hive.box('users'); // Make sure this box is opened in main.dart
  }

  // Login function
  Future<void> login() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both email and password")),
      );
      return;
    }

    if (!usersBox.containsKey(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No account found with this email")),
      );
      return;
    }

    var storedPassword = usersBox.get(email)['password'];
    if (storedPassword != password) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Incorrect password")),
      );
      return;
    }

    // Persist login state for auto-login
    await AuthService.instance.login(email);
    // Persist profile info for greeting
    try {
          if (Hive.isBoxOpen('users') && Hive.isBoxOpen('profile')) {
        final user = usersBox.get(email) as Map?;
        if (user != null) {
          final profile = Hive.box('profile');
          final name = (user['name'] as String?) ?? '';
          if (name.isNotEmpty) profile.put('name', name);
          profile.put('email', email);
        }
      }
    } catch (_) {}
    if (!mounted) return;

    // Login successful - navigate to dashboard
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const DashboardScreen()),
    );
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // App Title
              LocalizedText(
                'welcome_title',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 10),
              LocalizedText(
                'login_sub',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textDark.withAlpha((0.7 * 255).round()),
                ),
              ),
              const SizedBox(height: 40),

              // Email Input Field
              TextField(
                controller: emailController,
                cursorColor: AppColors.primary,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.card,
                  label: LocalizedText('email_address', style: const TextStyle()),
                  prefixIcon: const Icon(Icons.email, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.primary)),
                ),
              ),
              const SizedBox(height: 20),

              // Password Input Field
              TextField(
                controller: passwordController,
                obscureText: _obscurePassword,
                cursorColor: AppColors.primary,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.card,
                  label: LocalizedText('password', style: const TextStyle()),
                  prefixIcon: const Icon(Icons.lock, color: AppColors.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.primary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.primary)),
                ),
              ),
              const SizedBox(height: 30),

              // Login Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: login,
                child: LocalizedText('login', style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 15),

              // Forgot Password
              TextButton(
                onPressed: () {},
                child: LocalizedText('forgot_password', style: TextStyle(color: AppColors.primary)),
              ),
              const SizedBox(height: 15),

              // Signup Redirect
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    LocalizedText('dont_have_account', style: TextStyle(color: AppColors.textDark)),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SignupScreen()),
                      );
                    },
                    child: LocalizedText('register', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
