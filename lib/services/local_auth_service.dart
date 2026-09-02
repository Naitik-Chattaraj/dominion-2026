import 'package:shared_preferences/shared_preferences.dart';

class LocalAuthService {
  static const String _keyName = 'user_name';
  static const String _keyEmail = 'user_email';
  static const String _keyPassword = 'user_password';
  static const String _keyStaySignedIn = 'stay_signed_in';
  static const String _keyIsLoggedIn = 'is_logged_in';

  Future<void> createAccount({
    required String name,
    required String email,
    required String password,
    required bool staySignedIn,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name);
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyPassword, password);
    await prefs.setBool(_keyStaySignedIn, staySignedIn);
    await prefs.setBool(_keyIsLoggedIn, staySignedIn);
  }

  Future<bool> signIn({
    required String email,
    required String password,
    required bool staySignedIn,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final storedEmail = prefs.getString(_keyEmail);
    final storedPassword = prefs.getString(_keyPassword);

    if (storedEmail == email && storedPassword == password) {
      await prefs.setBool(_keyStaySignedIn, staySignedIn);
      await prefs.setBool(_keyIsLoggedIn, staySignedIn);
      return true;
    }
    return false;
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, false);
    await prefs.setBool(_keyStaySignedIn, false);
  }

  Future<bool> shouldAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  Future<Map<String, String?>> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_keyName),
      'email': prefs.getString(_keyEmail),
    };
  }
}
