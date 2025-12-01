import 'package:flutter/material.dart';

class ThemeController {
  ThemeController._privateConstructor();
  static final ThemeController instance = ThemeController._privateConstructor();

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);

  ThemeMode get current => themeMode.value;

  bool get isDark => themeMode.value == ThemeMode.dark;

  void setThemeMode(ThemeMode mode) {
    themeMode.value = mode;
  }

  void toggleDark(bool enable) {
    themeMode.value = enable ? ThemeMode.dark : ThemeMode.light;
  }
}
