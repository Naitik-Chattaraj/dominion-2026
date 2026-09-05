import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'theme/app_theme.dart';
import 'widgets/liquid_glass_navbar.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/home/riskgrid_home_screen.dart';
import 'screens/home/safety_map_screen.dart';
import 'screens/news/news_feed_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'services/local_auth_service.dart';
import 'services/safety_location_service.dart';
import 'services/notification_service.dart';
import 'widgets/fluid_liquid_glass_dynamic_island.dart';

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
  NotificationService.instance.init();
}

class RiskGridApp extends StatelessWidget {
  const RiskGridApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844), // iPhone 14 / Standard Android Size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'RiskGrid',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: const AuthWrapper(),
        );
      },
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
    try {
      final shouldLogin = await _localAuthService.shouldAutoLogin().timeout(
        const Duration(seconds: 3),
        onTimeout: () => false,
      );

      if (mounted) {
        setState(() {
          _isLoggedIn = shouldLogin;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Auth check error: $e');
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF070709),
        body: Center(
          child: CircularProgressIndicator(
            color: const Color(0xFFD9779F),
            strokeWidth: 2.w,
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
          Positioned.fill(
            child: IndexedStack(
              index: _currentIndex,
              children: screens,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: LiquidGlassDockNavBar(
              currentIndex: _currentIndex,
              items: _dockItems,
              bottomOffset: 16.h,
              showSeparator: false,
              onTap: (index) {
                setState(() => _currentIndex = index);
              },
            ),
          ),
          // Fluid Liquid Glass Dynamic Island anchored at the top camera notch
          Positioned.fill(
            child: FluidLiquidGlassDynamicIsland(
              onViewOnMap: (zone) {
                SafetyLocationService.instance.mapFocusZoneNotifier.value = zone;
                setState(() => _currentIndex = 1);
              },
            ),
          ),
        ],
      ),
    );
  }
}
