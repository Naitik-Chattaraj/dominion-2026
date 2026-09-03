import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../models/safety_models.dart';
import '../../widgets/liquid_glass_container.dart';

class RiskGridHomeScreen extends StatefulWidget {
  final SafetyStatus? initialStatus;
  const RiskGridHomeScreen({super.key, this.initialStatus});

  @override
  State<RiskGridHomeScreen> createState() => _RiskGridHomeScreenState();
}

class _RiskGridHomeScreenState extends State<RiskGridHomeScreen>
    with SingleTickerProviderStateMixin {
  late SafetyStatus _currentStatus;
  late SafetyStatus _prevStatus;
  late AnimationController _flowController;
  late Animation<double> _flowAnimation;

  final List<LocalIncidentReport> _incidents = [
    LocalIncidentReport(
      title: 'Fighting Happeni...',
      locationName: 'Potheri, Maramalai Nag...',
      sourceTag: 'srmist.edu.in',
      thumbnailAsset: 'assets/incident_thumb.png',
    ),
    LocalIncidentReport(
      title: 'Fighting Happeni...',
      locationName: 'Potheri, Maramalai Nag...',
      sourceTag: 'srmist.edu.in',
      thumbnailAsset: 'assets/incident_thumb.png',
    ),
    LocalIncidentReport(
      title: 'Fighting Happeni...',
      locationName: 'Potheri, Maramalai Nag...',
      sourceTag: 'srmist.edu.in',
      thumbnailAsset: 'assets/incident_thumb.png',
    ),
    LocalIncidentReport(
      title: 'Roadblock Reporte...',
      locationName: 'GST Road, Chennai...',
      sourceTag: 'srmist.edu.in',
      thumbnailAsset: 'assets/incident_thumb.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.initialStatus ?? SafetyStatus.allGood;
    _prevStatus = _currentStatus;

    _flowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _flowAnimation = CurvedAnimation(
      parent: _flowController,
      curve: Curves.easeOutCubic,
    );

    _flowController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _flowController.dispose();
    super.dispose();
  }

  void _cycleStatus() {
    setState(() {
      _prevStatus = _currentStatus;
      _currentStatus = SafetyStatus.values[
        (_currentStatus.index + 1) % SafetyStatus.values.length
      ];
    });
    _flowController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    const Color deepBlack = Color(0xFF070709);

    return Scaffold(
      backgroundColor: deepBlack,
      body: Stack(
        children: [
          // 1. HARDWARE-ACCELERATED ORGANIC AMBIENT LAYER
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _flowAnimation,
                builder: (context, child) {
                  final progress = _flowController.isAnimating
                      ? _flowAnimation.value
                      : 1.0;

                  return CustomPaint(
                    painter: OrganicAmbientPainter(
                      fromColor: _prevStatus.ambientColor,
                      toColor: _currentStatus.ambientColor,
                      progress: progress,
                    ),
                  );
                },
              ),
            ),
          ),

          // 2. MAIN SCROLLABLE CONTENT
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // Top Header Row: Shield Logo (left) and Liquid Glass Notification Bell (right)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: _cycleStatus,
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/riskgrid.png',
                              height: 38,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.shield,
                                  color: Color(0xFFD9779F),
                                  size: 34,
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      LiquidGlassContainer(
                        borderRadius: 22.0,
                        blurSigma: 10.0,
                        tintOpacity: 0.42,
                        tintColor: const Color(0xFF16091E),
                        padding: const EdgeInsets.all(10.0),
                        enableBlur: true,
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          color: Colors.white,
                          size: 24.0,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Display Title with STRICT FIXED HEIGHT CONTAINER
                  // Prevents the layout from shifting or pushing upwards when switching to "Risky Area"
                  SizedBox(
                    height: 70.0,
                    width: double.infinity,
                    child: Center(
                      child: GestureDetector(
                        onTap: _cycleStatus,
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          layoutBuilder: (currentChild, previousChildren) => Stack(
                            alignment: Alignment.center,
                            children: [
                              ...previousChildren,
                              ?currentChild,
                            ],
                          ),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(opacity: animation, child: child);
                          },
                          child: FittedBox(
                            key: ValueKey(_currentStatus),
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0),
                              child: Text(
                                _currentStatus.displayTitle,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                softWrap: false,
                                style: const TextStyle(
                                  fontFamily: 'WinterSolace',
                                  fontSize: 52.0,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFD9779F),
                                  letterSpacing: 0.5,
                                  shadows: [
                                    Shadow(
                                      color: Color(0x66D9779F),
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // "Nearby Risky Locations" Liquid Glass Card (Enlarged 1.15x to 236px Height)
                  LiquidGlassContainer(
                    borderRadius: 24,
                    tintColor: const Color(0xFF14081B),
                    tintOpacity: 0.65,
                    enableBlur: false,
                    padding: EdgeInsets.zero,
                    child: SizedBox(
                      height: 236, // 205 * 1.15 = 235.75
                      width: double.infinity,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          children: [
                            Positioned(
                              right: 0,
                              top: 0,
                              bottom: 0,
                              left: 185,
                              child: Image.asset(
                                'assets/potheri_map.png',
                                fit: BoxFit.cover,
                                alignment: Alignment.centerLeft,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(color: const Color(0xFF20162A));
                                },
                              ),
                            ),

                            Positioned.fill(
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Color(0xFF14081B),
                                      Color(0xFF14081B),
                                      Color(0xEA14081B),
                                      Color(0x8014081B),
                                      Colors.transparent,
                                    ],
                                    stops: [0.0, 0.42, 0.54, 0.70, 0.90],
                                  ),
                                ),
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.fromLTRB(26.0, 28.0, 20.0, 28.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Nearby Risky\nLocations',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 23.0,
                                      fontWeight: FontWeight.w700,
                                      height: 1.25,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  const Text(
                                    'Potheri, Maramalai\nNagar',
                                    style: TextStyle(
                                      color: Color(0xFF96909E),
                                      fontSize: 15.5,
                                      height: 1.3,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Section Header: "Happening Around You >"
                  const Text(
                    'Happening Around You  >',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.0,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Incident Cards Horizontal Carousel (Enlarged 1.10x height to 292px, 1.50x width to 258px)
                  SizedBox(
                    height: 295, // 265 * 1.10 = 291.5
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _incidents.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final incident = _incidents[index];
                        return LiquidGlassContainer(
                          borderRadius: 20,
                          tintColor: const Color(0xFF14081B),
                          tintOpacity: 0.65,
                          enableBlur: false,
                          padding: EdgeInsets.zero,
                          child: SizedBox(
                            width: 258, // 172 * 1.5 = 258.0
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                  child: SizedBox(
                                    height: 168,
                                    width: double.infinity,
                                    child: Image.asset(
                                      incident.thumbnailAsset,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: const Color(0xFF2C1638),
                                          child: const Icon(
                                            CupertinoIcons.photo,
                                            color: Colors.white30,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),

                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16.0, 14.0, 16.0, 12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        incident.locationName,
                                        style: const TextStyle(
                                          color: Color(0xFF908A99),
                                          fontSize: 13.0,
                                          fontFamily: 'Inter',
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        incident.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16.5,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Inter',
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        incident.sourceTag,
                                        style: const TextStyle(
                                          color: Color(0xFF908A99),
                                          fontSize: 13.0,
                                          fontFamily: 'Inter',
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 130),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Seamless Organic Ambient Painter
class OrganicAmbientPainter extends CustomPainter {
  final Color fromColor;
  final Color toColor;
  final double progress;

  OrganicAmbientPainter({
    required this.fromColor,
    required this.toColor,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const Color deepBlack = Color(0xFF070709);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = deepBlack,
    );

    final currentColor = Color.lerp(fromColor, toColor, progress) ?? toColor;

    final double maxReach = size.height * 0.28;
    final flowY = math.sin(progress * math.pi * 0.5);
    final currentReach = maxReach * flowY;

    final targetRect = Rect.fromLTWH(0, 0, size.width, currentReach);

    // Primary Atmospheric Vertical Wash
    canvas.drawRect(
      targetRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            currentColor.withValues(alpha: 0.60),
            currentColor.withValues(alpha: 0.44),
            currentColor.withValues(alpha: 0.26),
            currentColor.withValues(alpha: 0.12),
            currentColor.withValues(alpha: 0.03),
            currentColor.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.25, 0.50, 0.72, 0.88, 1.0],
        ).createShader(targetRect),
    );

    // Left-leaning Organic Plume
    final leftRect = Rect.fromLTWH(0, 0, size.width * 0.85, currentReach * 0.90);
    canvas.drawRect(
      leftRect,
      Paint()
        ..shader = LinearGradient(
          begin: const Alignment(-0.85, -1.0),
          end: const Alignment(0.40, 1.0),
          colors: [
            currentColor.withValues(alpha: 0.35),
            currentColor.withValues(alpha: 0.18),
            currentColor.withValues(alpha: 0.05),
            currentColor.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.40, 0.75, 1.0],
        ).createShader(leftRect),
    );

    // Right-leaning Organic Plume
    final rightRect = Rect.fromLTWH(size.width * 0.15, 0, size.width * 0.85, currentReach * 0.82);
    canvas.drawRect(
      rightRect,
      Paint()
        ..shader = LinearGradient(
          begin: const Alignment(0.85, -1.0),
          end: const Alignment(-0.35, 1.0),
          colors: [
            currentColor.withValues(alpha: 0.28),
            currentColor.withValues(alpha: 0.14),
            currentColor.withValues(alpha: 0.03),
            currentColor.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.38, 0.72, 1.0],
        ).createShader(rightRect),
    );

    // Center Ambient Radiance
    final centerRect = Rect.fromLTWH(0, 0, size.width, currentReach * 1.15);
    canvas.drawRect(
      centerRect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.0, -0.85),
          radius: 1.25,
          colors: [
            currentColor.withValues(alpha: 0.30),
            currentColor.withValues(alpha: 0.15),
            currentColor.withValues(alpha: 0.04),
            currentColor.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.45, 0.78, 1.0],
        ).createShader(centerRect),
    );
  }

  @override
  bool shouldRepaint(covariant OrganicAmbientPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.toColor != toColor ||
        oldDelegate.fromColor != fromColor;
  }
}
