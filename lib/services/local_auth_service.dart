import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:riskgrid/database/riskgrid_database.dart';
import 'package:riskgrid/models/local_user.dart';

class BiometricAuthResult {
  final bool isSuccess;
  final String message;

  BiometricAuthResult({required this.isSuccess, required this.message});

  factory BiometricAuthResult.success() =>
      BiometricAuthResult(isSuccess: true, message: 'Authentication successful');

  factory BiometricAuthResult.error(String message) =>
      BiometricAuthResult(isSuccess: false, message: message);
}

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

  Future<bool> isBiometricHardwareAvailable() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      return isSupported || canCheck;
    } catch (_) {
      return false;
    }
  }

  Future<BiometricAuthResult> verifyBiometricsToEnable() async {
    try {
      final canAuthenticate = await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
      if (!canAuthenticate) {
        return BiometricAuthResult.error('Biometrics and lock screen security are not supported on this device.');
      }

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Confirm identity to enable Biometric Login',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (didAuthenticate) {
        return BiometricAuthResult.success();
      } else {
        return BiometricAuthResult.error('Verification canceled.');
      }
    } on PlatformException catch (e) {
      if (e.code == 'NotEnrolled') {
        return BiometricAuthResult.error(
            'No fingerprint or device screen lock enrolled. Please set up a screen lock/fingerprint in Android Settings.');
      }
      return BiometricAuthResult.error(e.message ?? 'Verification failed.');
    } catch (e) {
      return BiometricAuthResult.error('Error verifying identity: $e');
    }
  }

  Future<BiometricAuthResult> signInWithBiometrics() async {
    try {
      final user = await getLastStoredUser();
      if (user == null) {
        return BiometricAuthResult.error('No account registered on this device.');
      }

      final canAuthenticate = await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
      if (!canAuthenticate) {
        return BiometricAuthResult.error('Biometrics and lock screen security are not supported on this device.');
      }

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Confirm your identity to sign in to RiskGrid',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (didAuthenticate) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyLastUserUid, user.uid);
        await prefs.setBool(_keyIsLoggedIn, true);
        return BiometricAuthResult.success();
      } else {
        return BiometricAuthResult.error('Authentication canceled.');
      }
    } on PlatformException catch (e) {
      if (e.code == 'NotEnrolled') {
        return BiometricAuthResult.error(
            'No fingerprint enrolled in device settings. Please set up a fingerprint in Android Settings or use password.');
      } else if (e.code == 'LockedOut' || e.code == 'PermanentlyLockedOut') {
        return BiometricAuthResult.error('Biometrics locked due to too many attempts. Please use password.');
      }
      return BiometricAuthResult.error(e.message ?? 'Biometric authentication failed.');
    } catch (e) {
      return BiometricAuthResult.error('Authentication failed: $e');
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
