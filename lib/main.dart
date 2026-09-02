import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'widgets/liquid_glass_navbar.dart';
import 'screens/home_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/threats_screen.dart';
import 'screens/network_screen.dart';
import 'screens/settings_screen.dart';

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
      home: const MainShellScreen(),
    );
  }
}

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _currentIndex = 0;

  final List<DockItem> _dockItems = const [
    DockItem(
      icon: CupertinoIcons.square_grid_2x2,
      activeIcon: CupertinoIcons.square_grid_2x2_fill,
      label: 'RiskGrid',
      activeColor: Color(0xFF00E5FF), // Cyber Cyan
    ),
    DockItem(
      icon: CupertinoIcons.chart_bar_alt_fill,
      activeIcon: CupertinoIcons.chart_bar_alt_fill,
      label: 'Analytics',
      activeColor: Color(0xFFA855F7), // Electric Violet
    ),
    DockItem(
      icon: CupertinoIcons.shield,
      activeIcon: CupertinoIcons.shield_fill,
      label: 'Threats',
      badgeCount: 3,
      activeColor: Color(0xFFFF2A6D), // Neon Crimson
    ),
    DockItem(
      icon: CupertinoIcons.waveform_path_ecg,
      activeIcon: CupertinoIcons.waveform_path_ecg,
      label: 'Nodes',
      activeColor: Color(0xFF10B981), // Emerald
    ),
    DockItem(
      icon: CupertinoIcons.slider_horizontal_3,
      activeIcon: CupertinoIcons.slider_horizontal_3,
      label: 'Studio',
      activeColor: Color(0xFFFBBF24), // Amber Gold
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        onNavigateToThreats: () => setState(() => _currentIndex = 2),
      ),
      const AnalyticsScreen(),
      const ThreatsScreen(),
      const NetworkScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // 1. Ambient Background Glow Gradients
          // Radiant glowing blooms that shine through the frosted liquid glass navbar and cards
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF7C3AED).withValues(alpha: 0.28), // Violet bloom
                    const Color(0xFF4C1D95).withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00E5FF).withValues(alpha: 0.18), // Cyan bloom
                    const Color(0xFF0D9488).withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 360,
            left: 60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF2A6D).withValues(alpha: 0.08), // Crimson bloom
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 2. Active Screen Content
          Positioned.fill(
            child: IndexedStack(
              index: _currentIndex,
              children: screens,
            ),
          ),

          // 3. Floating Mac Dock Bottom Navigation Bar
          // - Pill with circular ends on both sides (borderRadius: 44)
          // - Lifted above the base (bottomOffset: 24.0 + safe area inset)
          // - Exact Liquid Glass SVG/CSS styles with specular highlights & refraction
          // - Mac Dock magnification, spring bounce, indicator dot & tooltips
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: LiquidGlassDockNavBar(
              currentIndex: _currentIndex,
              items: _dockItems,
              bottomOffset: 24.0,
              showSeparator: true,
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
