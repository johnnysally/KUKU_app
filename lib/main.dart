import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/splash_screen.dart';
import 'theme/theme_controller.dart';
import 'theme/colors.dart';

void main() {
  // Run the app inside a guarded zone so uncaught async errors can be captured.
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Hive and open boxes
    await Hive.initFlutter();
    await Hive.openBox('users');
    await Hive.openBox('profile');
    await Hive.openBox('flocks');
    await Hive.openBox('feed');
    await Hive.openBox('vaccinations');
    await Hive.openBox('analytics');
    await Hive.openBox('notifications');
    await Hive.openBox('mortality');
    await Hive.openBox('eggs');
    // Initialize local notifications
    // NotificationService is optional; initialize if available.
    // NotificationService will be initialized after pub get when available.
    await Hive.openBox('tips');
    await Hive.openBox('auth');

    // Capture Flutter framework errors.
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      // Could send to remote logging here.
    };

    runApp(const PoultryApp());
  }, (Object error, StackTrace stack) {
    // Log error; in production send to crash reporting.
    debugPrint('Uncaught zone error: $error');
    debugPrint('$stack');
  });
}

class PoultryApp extends StatelessWidget {
  const PoultryApp({super.key});

  ThemeData _lightTheme() => ThemeData(
        brightness: Brightness.light,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: AppBarTheme(backgroundColor: AppColors.primary),
      );

  ThemeData _darkTheme() => ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.grey[900],
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: AppBarTheme(backgroundColor: Colors.grey[900]),
      );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _lightTheme(),
          darkTheme: _darkTheme(),
          themeMode: mode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
