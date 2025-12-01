import 'package:hive_flutter/hive_flutter.dart';

class AuthService {
  AuthService._private();
  static final AuthService instance = AuthService._private();

  Box get _box => Hive.box('auth');

  bool isLoggedIn() {
    return _box.get('isLoggedIn', defaultValue: false) as bool;
  }

  String? currentUserEmail() {
    return _box.get('email') as String?;
  }

  Future<void> login(String email) async {
    await _box.put('isLoggedIn', true);
    await _box.put('email', email);
  }

  Future<void> logout() async {
    await _box.put('isLoggedIn', false);
    await _box.delete('email');
  }
}
