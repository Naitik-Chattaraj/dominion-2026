import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'widgets/liquid_glass_navbar.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/home/riskgrid_home_screen.dart';
import 'services/local_auth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const RiskGridApp());
}

class RiskGridApp extends StatelessWidget {
  const RiskGridApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RiskGrid',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _localAuthService = LocalAuthService();
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final shouldLogin = await _localAuthService.shouldAutoLogin();
    if (mounted) {
      setState(() {
        _isLoggedIn = shouldLogin;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF070709),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFD9779F),
            strokeWidth: 2,
          ),
        ),
      );
    }
    if (_isLoggedIn) {
      return const MainShellScreen();
    } else {
      return SignInScreen(
        onSignInSuccess: () {
          setState(() {
            _isLoggedIn = true;
          });
        },
      );
    }
  }
}

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => MainShellScreenState();
}

class MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

  final List<DockItem> _dockItems = const [
    DockItem(
      icon: CupertinoIcons.house_fill,
      activeIcon: CupertinoIcons.house_fill,
      label: 'Home',
      activeColor: Color(0xFFD9779F),
    ),
    DockItem(
      icon: CupertinoIcons.compass,
      activeIcon: CupertinoIcons.compass_fill,
      label: 'Explore',
      activeColor: Color(0xFF00E5FF),
    ),
    DockItem(
      icon: CupertinoIcons.gear,
      activeIcon: CupertinoIcons.gear_solid,
      label: 'Settings',
      activeColor: Color(0xFFA855F7),
    ),
    DockItem(
      icon: CupertinoIcons.person,
      activeIcon: CupertinoIcons.person_fill,
      label: 'Profile',
      activeColor: Color(0xFFFFB800),
    ),
  ];

  void logout() async {
    await LocalAuthService().signOut();
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
    final screens = [
      const RiskGridHomeScreen(),
      const Center(
        child: Text(
          'Safe Route / Explore',
          style: TextStyle(color: Colors.white, fontFamily: 'Inter'),
        ),
      ),
      const Center(
        child: Text(
          'Settings & Sensors',
          style: TextStyle(color: Colors.white, fontFamily: 'Inter'),
        ),
      ),
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8A1E4A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF070709),
      body: Stack(
        children: [
          // Screen content
          Positioned.fill(
            child: IndexedStack(
              index: _currentIndex,
              children: screens,
            ),
          ),

          // Floating Liquid Glass Dock Navbar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: LiquidGlassDockNavBar(
              currentIndex: _currentIndex,
              items: _dockItems,
              bottomOffset: 24.0,
              showSeparator: false,
              onTap: (index) {
                setState(() => _currentIndex = index);
              },
            ),
          ),
        ],
      ),
    );
  }
}
