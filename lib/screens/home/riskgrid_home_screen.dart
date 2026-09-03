import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/safety_models.dart';
import '../../models/danger_zone.dart';
import '../../services/safety_location_service.dart';
import '../../services/news_service.dart';
import '../../widgets/liquid_glass_container.dart';
import '../../utils/app_haptics.dart';

class RiskGridHomeScreen extends StatefulWidget {
  final void Function(int)? onNavigate;
  final SafetyStatus? initialStatus;

  const RiskGridHomeScreen({super.key, this.onNavigate, this.initialStatus});

  @override
  State<RiskGridHomeScreen> createState() => _RiskGridHomeScreenState();
}

class _RiskGridHomeScreenState extends State<RiskGridHomeScreen>
    with SingleTickerProviderStateMixin {
  late SafetyStatus _currentStatus;
  late SafetyStatus _prevStatus;
  late AnimationController _flowController;
  late Animation<double> _flowAnimation;

  late Future<List<NewsArticle>> _newsFuture;

  @override
  void initState() {
    super.initState();
    // Initialize with location service or widget override
    _currentStatus = widget.initialStatus ?? SafetyLocationService.instance.statusNotifier.value;
    
    _newsFuture = NewsService.instance.fetchLocalNews();
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

    // Live reactive binding to GPS proximity engine
    SafetyLocationService.instance.statusNotifier.addListener(_onStatusChanged);
  }

  @override
  void dispose() {
    SafetyLocationService.instance.statusNotifier.removeListener(_onStatusChanged);
    _flowController.dispose();
    super.dispose();
  }

  void _onStatusChanged() {
    final newStatus = SafetyLocationService.instance.statusNotifier.value;
    if (newStatus != _currentStatus && mounted) {
      // Differentiated tactile haptics tailored to incoming status:
      switch (newStatus) {
        case SafetyStatus.allGood:
          HapticFeedback.lightImpact(); // Calm, gentle confirmation
          break;
        case SafetyStatus.staySafe:
          HapticFeedback.mediumImpact(); // Notable advisory bump
          break;
        case SafetyStatus.riskyArea:
          HapticFeedback.heavyImpact(); // Urgent, strong warning alert
          break;
      }

      setState(() {
        _prevStatus = _currentStatus;
        _currentStatus = newStatus;
      });
      _flowController.forward(from: 0.0);
    }
  }

  Color _getCategoryColor(SafetyCategory category) {
    switch (category) {
      case SafetyCategory.crime:
        return Colors.redAccent;
      case SafetyCategory.hazard:
        return Colors.orangeAccent;
      case SafetyCategory.traffic:
        return Colors.amber;
      case SafetyCategory.generalAlert:
        return Colors.lightBlueAccent;
    }
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
                      Row(
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

                      LiquidGlassContainer(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No new alerts in your current grid zone'),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        borderRadius: 22.0,
                        blurSigma: 5.0, // Reduced by 50%
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

                  const SizedBox(height: 24),

                  // "RiskGrid Map" Liquid Glass Card (Enlarged 1.15x to 236px Height)
                  ValueListenableBuilder<LatLng?>(
                    valueListenable: SafetyLocationService.instance.locationNotifier,
                    builder: (context, userLoc, _) {
                      return ValueListenableBuilder<List<DangerZone>>(
                        valueListenable: SafetyLocationService.instance.zonesNotifier,
                        builder: (context, zones, _) {
                          final center = userLoc ?? const LatLng(12.8235, 80.0442);

                          return LiquidGlassContainer(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              if (widget.onNavigate != null) {
                                widget.onNavigate!(1); // Navigate to index 1 (Explore/Map)
                              }
                            },
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
                                      left: 175,
                                      child: IgnorePointer(
                                        child: FlutterMap(
                                          options: MapOptions(
                                            initialCenter: center,
                                            initialZoom: 14.5,
                                            interactionOptions: const InteractionOptions(
                                              flags: InteractiveFlag.none,
                                            ),
                                          ),
                                          children: [
                                            TileLayer(
                                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                              userAgentPackageName: 'com.example.riskgrid',
                                            ),
                                            CircleLayer(
                                              circles: zones.map((zone) {
                                                final color = zone.isHistorical
                                                    ? const Color(0xFF7C4DFF)
                                                    : (zone.level == 'red' ? Colors.red : Colors.orange);
                                                return CircleMarker(
                                                  point: LatLng(zone.latitude, zone.longitude),
                                                  radius: zone.radiusMeters,
                                                  useRadiusInMeter: true,
                                                  color: color.withValues(alpha: 0.35),
                                                  borderColor: color,
                                                  borderStrokeWidth: 1.5,
                                                );
                                              }).toList(),
                                            ),
                                            if (userLoc != null)
                                              MarkerLayer(
                                                markers: [
                                                  Marker(
                                                    point: userLoc,
                                                    width: 24,
                                                    height: 24,
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: const Color(0xFF00E5FF),
                                                        border: Border.all(color: Colors.white, width: 2),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
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
                                            'RiskGrid\nMap',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 26.0,
                                              fontWeight: FontWeight.w700,
                                              height: 1.25,
                                              fontFamily: 'Inter',
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          Text(
                                            userLoc != null
                                                ? '${zones.length} active risk zones\nGPS telemetry active'
                                                : 'Live nearby risk\ntelemetry',
                                            style: const TextStyle(
                                              color: Color(0xFF96909E),
                                              fontSize: 14.5,
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
                          );
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Section Header: "Happening Around You" (Interactive)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      AppHaptics.cardTap();
                      if (widget.onNavigate != null) {
                        widget.onNavigate!(2);
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Happening Around You',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.0,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Inter',
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'View all',
                              style: TextStyle(
                                color: const Color(0xFFD9779F).withValues(alpha: 0.85),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Inter',
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Color(0xFFD9779F),
                              size: 13,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Incident Cards Horizontal Carousel (Enlarged to accommodate text)
                  SizedBox(
                    height: 340, 
                    child: FutureBuilder<List<NewsArticle>>(
                      future: _newsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(color: Color(0xFFD9779F)),
                          );
                        }
                        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                            child: Text(
                              'No local updates at this moment.',
                              style: TextStyle(color: Color(0xFF908A99)),
                            ),
                          );
                        }
                        
                        final articles = snapshot.data!.take(4).toList();

                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: articles.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 16),
                          itemBuilder: (context, index) {
                            final article = articles[index];
                            return LiquidGlassContainer(
                              onTap: () {
                                AppHaptics.cardTap();
                                if (widget.onNavigate != null) {
                                  widget.onNavigate!(2); // Navigate to index 2 (News)
                                }
                              },
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
                                        child: Image.network(
                                          article.thumbnail,
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
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                                    margin: const EdgeInsets.only(right: 8),
                                                    decoration: BoxDecoration(
                                                      color: _getCategoryColor(article.category).withValues(alpha: 0.2),
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(color: _getCategoryColor(article.category).withValues(alpha: 0.5)),
                                                    ),
                                                    child: Text(
                                                      article.category.name.toUpperCase(),
                                                      style: TextStyle(
                                                        color: _getCategoryColor(article.category),
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF251C2B),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      article.sourceName.toUpperCase(),
                                                      style: const TextStyle(
                                                        color: Color(0xFF9871BA),
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        letterSpacing: 0.5,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Flexible(
                                                child: Text(
                                                  'Chennai', 
                                                  style: const TextStyle(
                                                    color: Color(0xFF6F667A),
                                                    fontSize: 11.0,
                                                    fontFamily: 'Inter',
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            article.title,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15.5,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'Inter',
                                              height: 1.25,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          if (article.description.isNotEmpty)
                                            Text(
                                              article.description.replaceAll(RegExp(r'<[^>]*>'), ''),
                                              style: const TextStyle(
                                                color: Color(0xFF908A99),
                                                fontSize: 12.5,
                                                fontFamily: 'Inter',
                                              ),
                                              maxLines: 2,
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
