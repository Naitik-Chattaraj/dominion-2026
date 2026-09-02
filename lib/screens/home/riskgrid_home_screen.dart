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

class _RiskGridHomeScreenState extends State<RiskGridHomeScreen> {
  late SafetyStatus _currentStatus;

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
  }

  void _cycleStatus() {
    setState(() {
      _currentStatus = SafetyStatus.values[
        (_currentStatus.index + 1) % SafetyStatus.values.length
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070709),
      body: Stack(
        children: [
          // 1. Polished Anti-Banding Linear Atmospheric Gradient (Exact Prototype Match)
          // 9-step optical stops provide smooth, banding-free atmospheric illumination
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
            height: 540,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _currentStatus.ambientGradientColors,
                stops: SafetyStatusExtension.ambientGradientStops,
              ),
            ),
          ),

          // 2. Main Scrollable Content
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  // Top Header Row: Shield Logo (left, larger) and Notification Bell (right)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Tapping shield discreetly cycles safety status
                      GestureDetector(
                        onTap: _cycleStatus,
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/riskgrid.png',
                              height: 38, // Slightly larger as requested
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
                      const Icon(
                        Icons.notifications_none,
                        color: Colors.white,
                        size: 26,
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Display Title in Winter Solace Font (Bigger & Centre-aligned as requested)
                  Center(
                    child: GestureDetector(
                      onTap: _cycleStatus,
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(opacity: animation, child: child);
                        },
                        child: Text(
                          _currentStatus.displayTitle,
                          key: ValueKey(_currentStatus),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'WinterSolace',
                            fontSize: 58, // Bigger heading size
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFD9779F), // Signature brand mauve pink
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

                  const SizedBox(height: 28),

                  // "Nearby Risky Locations" Liquid Glass Card (Enlarged for Mobile)
                  LiquidGlassContainer(
                    borderRadius: 20,
                    tintColor: const Color(0xFF14081B),
                    tintOpacity: 0.65,
                    blurSigma: 12.0,
                    padding: EdgeInsets.zero,
                    child: SizedBox(
                      height: 176, // Generous mobile height
                      width: double.infinity,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            // Street Map Background on Right Side
                            Positioned(
                              right: 0,
                              top: 0,
                              bottom: 0,
                              left: 155,
                              child: Image.asset(
                                'assets/potheri_map.png',
                                fit: BoxFit.cover,
                                alignment: Alignment.centerLeft,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(color: const Color(0xFF20162A));
                                },
                              ),
                            ),

                            // Smooth vignette gradient blending dark glass over map
                            Positioned.fill(
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Color(0xFF14081B),
                                      Color(0xFF14081B),
                                      Color(0xE814081B),
                                      Color(0x7514081B),
                                      Colors.transparent,
                                    ],
                                    stops: [0.0, 0.40, 0.50, 0.65, 0.85],
                                  ),
                                ),
                              ),
                            ),

                            // Text Content: "Nearby Risky Locations" & "Potheri, Maramalai Nagar"
                            Padding(
                              padding: const EdgeInsets.fromLTRB(22.0, 22.0, 16.0, 22.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Nearby Risky\nLocations',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 19.0, // Larger font
                                      fontWeight: FontWeight.w700,
                                      height: 1.25,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  const Text(
                                    'Potheri, Maramalai\nNagar',
                                    style: TextStyle(
                                      color: Color(0xFF96909E),
                                      fontSize: 13.5, // Larger subtitle
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

                  // Section Header: "Happening Around You >" (Enlarged)
                  const Text(
                    'Happening Around You  >',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.0, // Larger section title
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Incident Cards Horizontal Scrolling Carousel (Enlarged Cards)
                  SizedBox(
                    height: 226, // Taller carousel for comfortable readability
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _incidents.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        final incident = _incidents[index];
                        return LiquidGlassContainer(
                          borderRadius: 16,
                          tintColor: const Color(0xFF14081B),
                          tintOpacity: 0.65,
                          blurSigma: 10.0,
                          padding: EdgeInsets.zero,
                          child: SizedBox(
                            width: 152, // Wider card
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Thumbnail
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                  child: SizedBox(
                                    height: 120, // Larger thumbnail image
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

                                // Metadata Text
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        incident.locationName,
                                        style: const TextStyle(
                                          color: Color(0xFF908A99),
                                          fontSize: 11.0,
                                          fontFamily: 'Inter',
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        incident.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13.5, // Larger title
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Inter',
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        incident.sourceTag,
                                        style: const TextStyle(
                                          color: Color(0xFF908A99),
                                          fontSize: 11.0,
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

                  // Bottom Spacing for floating enlarged dock navbar
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
