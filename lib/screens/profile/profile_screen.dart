import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:riskgrid/services/local_auth_service.dart';
import 'package:riskgrid/models/local_user.dart';
import 'package:riskgrid/main.dart'; // For AuthWrapper routing

import 'package:shared_preferences/shared_preferences.dart';
import 'package:riskgrid/database/riskgrid_database.dart';
import 'package:riskgrid/services/safety_location_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final LocalAuthService _authService = LocalAuthService();
  LocalUser? _user;
  bool _isLoading = true;
  bool _developerMode = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isDev = prefs.getBool('developerMode') ?? false;
    final user = await _authService.getLastStoredUser();
    if (mounted) {
      setState(() {
        _user = user;
        _developerMode = isDev;
        _isLoading = false;
      });
    }
  }

  void _logout() async {
    HapticFeedback.mediumImpact();
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const AuthWrapper(),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF070709),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFFB800))),
      );
    }

    if (_user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF070709),
        body: Center(child: Text('No user data found.', style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF070709),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Profile', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundColor: Color(0xFF1E1E24),
            child: Icon(Icons.person, size: 50, color: Color(0xFFFFB800)),
          ),
          const SizedBox(height: 16),
          Text(
            _user!.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
          ),
          Text(
            _user!.email,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF908A99),
              fontSize: 16,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 32),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF16151A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF2A2730)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Public UID', style: TextStyle(color: Color(0xFF908A99), fontSize: 12)),
                const SizedBox(height: 4),
                Text(_user!.publicUid, style: const TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 1.2)),
                const SizedBox(height: 16),
                const Text('Pairing Code', style: TextStyle(color: Color(0xFF908A99), fontSize: 12)),
                const SizedBox(height: 4),
                Text(_user!.pairingCode, style: const TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 2.0, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          const Text('Security Preferences', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          SwitchListTile(
            title: const Text('Stay Signed In', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Skip login screen on launch', style: TextStyle(color: Color(0xFF908A99))),
            activeThumbColor: const Color(0xFFFFB800),
            value: _user!.staySignedIn,
            onChanged: (val) async {
              HapticFeedback.selectionClick();
              await _authService.updateStaySignedInPreference(val);
              setState(() => _user = LocalUser(
                uid: _user!.uid, name: _user!.name, email: _user!.email, passwordHash: _user!.passwordHash,
                publicUid: _user!.publicUid, pairingCode: _user!.pairingCode,
                biometricEnabled: _user!.biometricEnabled, staySignedIn: val,
              ));
            },
          ),
          SwitchListTile(
            title: const Text('Biometric Login', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Use fingerprint or face scan', style: TextStyle(color: Color(0xFF908A99))),
            activeThumbColor: const Color(0xFFFFB800),
            value: _user!.biometricEnabled,
            onChanged: (val) async {
              HapticFeedback.selectionClick();
              if (val) {
                final result = await _authService.verifyBiometricsToEnable();
                if (!context.mounted) return;
                if (!result.isSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result.message),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
              }
              await _authService.updateBiometricPreference(val);
              if (!context.mounted) return;
              setState(() => _user = LocalUser(
                uid: _user!.uid, name: _user!.name, email: _user!.email, passwordHash: _user!.passwordHash,
                publicUid: _user!.publicUid, pairingCode: _user!.pairingCode,
                biometricEnabled: val, staySignedIn: _user!.staySignedIn,
              ));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(val ? 'Biometric login enabled.' : 'Biometric login disabled.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          
          const SizedBox(height: 32),
          const Text('Developer Options', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          SwitchListTile(
            title: const Text('Developer Mode', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Enable test features and data wipe', style: TextStyle(color: Color(0xFF908A99))),
            activeThumbColor: const Color(0xFF00E5FF),
            value: _developerMode,
            onChanged: (val) async {
              HapticFeedback.selectionClick();
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('developerMode', val);
              setState(() => _developerMode = val);
            },
          ),
          if (_developerMode) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                HapticFeedback.mediumImpact();
                await RiskGridDatabase.instance.deleteAllUserZones();
                await SafetyLocationService.instance.refreshZones();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Test data (user-flagged zones) wiped successfully.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.delete_forever_rounded, color: Colors.white),
              label: const Text('Wipe All Flagged Test Data', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5A1218),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
          
          const SizedBox(height: 48),
          ElevatedButton(
            onPressed: _logout,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8A1E4A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
