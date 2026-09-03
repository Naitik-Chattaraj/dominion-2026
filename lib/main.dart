import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'widgets/liquid_glass_navbar.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/home/riskgrid_home_screen.dart';
import 'screens/home/safety_map_screen.dart';
import 'screens/news/news_feed_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'services/local_auth_service.dart';
import 'services/safety_location_service.dart';

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
    bool shouldLogin = await _localAuthService.shouldAutoLogin();
    
    // If not auto-login (stay signed in false), check if biometrics can save us
    if (!shouldLogin) {
      final lastUser = await _localAuthService.getLastStoredUser();
      if (lastUser != null && lastUser.biometricEnabled) {
         final result = await _localAuthService.signInWithBiometrics();
         shouldLogin = result.isSuccess;
      }
    }

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

  @override
  void initState() {
    super.initState();
    SafetyLocationService.instance.init();
  }

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
      icon: CupertinoIcons.news,
      activeIcon: CupertinoIcons.news_solid,
      label: 'News',
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
    HapticFeedback.mediumImpact();
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
      RiskGridHomeScreen(
        onNavigate: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      const SafetyMapScreen(),
      const NewsFeedScreen(),
      const ProfileScreen(),
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
