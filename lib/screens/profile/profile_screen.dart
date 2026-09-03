import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:riskgrid/services/local_auth_service.dart';
import 'package:riskgrid/models/local_user.dart';
import 'package:riskgrid/main.dart'; // For AuthWrapper routing

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final LocalAuthService _authService = LocalAuthService();
  LocalUser? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getLastStoredUser();
    if (mounted) {
      setState(() {
        _user = user;
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
              await _authService.updateBiometricPreference(val);
              setState(() => _user = LocalUser(
                uid: _user!.uid, name: _user!.name, email: _user!.email, passwordHash: _user!.passwordHash,
                publicUid: _user!.publicUid, pairingCode: _user!.pairingCode,
                biometricEnabled: val, staySignedIn: _user!.staySignedIn,
              ));
            },
          ),
          
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
