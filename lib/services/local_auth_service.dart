import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:riskgrid/database/riskgrid_database.dart';
import 'package:riskgrid/models/local_user.dart';

class LocalAuthService {
  final RiskGridDatabase _db = RiskGridDatabase.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyLastUserUid = 'last_user_uid';

  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _generatePublicUid() {
    var uuid = const Uuid().v4();
    var parts = uuid.split('-');
    return '${parts[0]}-${parts[1]}-${parts[2]}-${parts[3]}'.toUpperCase();
  }
  
  String _generatePairingCode() {
    var uuid = const Uuid().v4().replaceAll('-', '');
    return uuid.substring(0, 6).toUpperCase();
  }

  Future<bool> hasAnyAccount() async {
    return await _db.hasAnyUser();
  }
  
  Future<LocalUser?> getLastStoredUser() async {
    return await _db.getLatestUser();
  }

  Future<void> createAccount({
    required String name,
    required String email,
    required String password,
    required bool staySignedIn,
  }) async {
    final uid = const Uuid().v4();
    final publicUid = _generatePublicUid();
    final pairingCode = _generatePairingCode();
    
    final user = LocalUser(
      uid: uid,
      name: name,
      email: email,
      passwordHash: _hashPassword(password),
      publicUid: publicUid,
      pairingCode: pairingCode,
      biometricEnabled: false, // Default false until they enable it
      staySignedIn: staySignedIn,
    );
    
    await _db.createUser(user);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastUserUid, uid);
    await prefs.setBool(_keyIsLoggedIn, staySignedIn);
  }

  Future<bool> signIn({
    required String email,
    required String password,
    required bool staySignedIn,
  }) async {
    final user = await _db.getUserByEmail(email);
    if (user == null) return false;
    
    final hash = _hashPassword(password);
    if (user.passwordHash == hash) {
      // Update preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastUserUid, user.uid);
      await prefs.setBool(_keyIsLoggedIn, staySignedIn);
      
      // Update user setting
      final updatedUser = LocalUser(
        uid: user.uid,
        name: user.name,
        email: user.email,
        passwordHash: user.passwordHash,
        publicUid: user.publicUid,
        pairingCode: user.pairingCode,
        biometricEnabled: user.biometricEnabled,
        staySignedIn: staySignedIn,
      );
      await _db.updateUser(updatedUser);
      
      return true;
    }
    return false;
  }

  Future<bool> signInWithBiometrics() async {
    try {
      final user = await getLastStoredUser();
      if (user == null || !user.biometricEnabled) return false;

      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      if (!canAuthenticate) return false;

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access RiskGrid',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allows fallback to PIN
        ),
      );

      if (didAuthenticate) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyLastUserUid, user.uid);
        await prefs.setBool(_keyIsLoggedIn, true);
      }
      return didAuthenticate;
    } catch (e) {
      return false;
    }
  }

  Future<void> updateBiometricPreference(bool enabled) async {
    final user = await getLastStoredUser();
    if (user != null) {
      final updatedUser = LocalUser(
        uid: user.uid,
        name: user.name,
        email: user.email,
        passwordHash: user.passwordHash,
        publicUid: user.publicUid,
        pairingCode: user.pairingCode,
        biometricEnabled: enabled,
        staySignedIn: user.staySignedIn,
      );
      await _db.updateUser(updatedUser);
    }
  }

  Future<void> updateStaySignedInPreference(bool enabled) async {
    final user = await getLastStoredUser();
    if (user != null) {
      final updatedUser = LocalUser(
        uid: user.uid,
        name: user.name,
        email: user.email,
        passwordHash: user.passwordHash,
        publicUid: user.publicUid,
        pairingCode: user.pairingCode,
        biometricEnabled: user.biometricEnabled,
        staySignedIn: enabled,
      );
      await _db.updateUser(updatedUser);
    }
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, false);
    
    // Unset staySignedIn in db too
    final user = await getLastStoredUser();
    if (user != null) {
       final updatedUser = LocalUser(
        uid: user.uid,
        name: user.name,
        email: user.email,
        passwordHash: user.passwordHash,
        publicUid: user.publicUid,
        pairingCode: user.pairingCode,
        biometricEnabled: user.biometricEnabled,
        staySignedIn: false,
      );
      await _db.updateUser(updatedUser);
    }
  }

  Future<bool> shouldAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    
    // Verify user exists and staySignedIn is true
    final user = await getLastStoredUser();
    return isLoggedIn && user != null && user.staySignedIn;
  }
}
