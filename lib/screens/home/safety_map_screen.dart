import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/danger_zone.dart';
import '../../services/safety_location_service.dart';
import '../../services/dynamic_island_service.dart';
import '../../widgets/liquid_glass_container.dart';
import '../../widgets/liquid_glass_text_field.dart';
import '../../utils/app_haptics.dart';

class SafetyMapScreen extends StatefulWidget {
  const SafetyMapScreen({super.key});

  @override
  State<SafetyMapScreen> createState() => _SafetyMapScreenState();
}

class _SafetyMapScreenState extends State<SafetyMapScreen> {
  final MapController _mapController = MapController();
  final SafetyLocationService _locationService = SafetyLocationService.instance;

  bool _hasCenteredOnUser = false;

  @override
  void initState() {
    super.initState();
    _locationService.init();

    _locationService.locationNotifier.addListener(_onLocationUpdate);
    _locationService.mapFocusZoneNotifier.addListener(_onMapFocusZoneChanged);
  }

  @override
  void dispose() {
    _locationService.locationNotifier.removeListener(_onLocationUpdate);
    _locationService.mapFocusZoneNotifier.removeListener(_onMapFocusZoneChanged);
    super.dispose();
  }

  void _onLocationUpdate() {
    final userLoc = _locationService.locationNotifier.value;
    if (userLoc != null && !_hasCenteredOnUser && mounted) {
      _hasCenteredOnUser = true;
      _mapController.move(userLoc, 16.0);
    }
  }

  void _onMapFocusZoneChanged() {
    final zone = _locationService.mapFocusZoneNotifier.value;
    if (zone != null && mounted) {
      _mapController.move(LatLng(zone.latitude, zone.longitude), 17.0);
    }
  }

  void _recenterOnUser() {
    AppHaptics.recenterMap();
    final userLoc = _locationService.locationNotifier.value;
    if (userLoc != null) {
      _mapController.move(userLoc, 16.5);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Acquiring GPS location... Please wait.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openDynamicIsland(DangerZone zone) {
    DynamicIslandService.instance.showDangerZoneAlert(zone);
  }

  void _closeDynamicIsland() {
    DynamicIslandService.instance.dismiss();
  }

  void _onMapTapped(LatLng tapPoint) {
    DangerZone? tappedZone;
    for (final zone in _locationService.zonesNotifier.value) {
      final dist = const Distance().as(
        LengthUnit.Meter,
        tapPoint,
        LatLng(zone.latitude, zone.longitude),
      );
      if (dist <= zone.radiusMeters) {
        tappedZone = zone;
        break;
      }
    }

    if (tappedZone != null) {
      _openDynamicIsland(tappedZone);
    } else {
      _closeDynamicIsland();
    }
  }

  void _openFlagRiskModal() {
    AppHaptics.openModal();
    final userLoc = _locationService.locationNotifier.value;
    if (userLoc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot flag risk without GPS lock. Please enable location.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => _LiquidGlassFlagRiskSheet(
        userLocation: userLoc,
        onSubmitted: (newZone) {
          _openDynamicIsland(newZone);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<LatLng?>(
      valueListenable: _locationService.locationNotifier,
      builder: (context, userLocation, _) {
        return ValueListenableBuilder<List<DangerZone>>(
          valueListenable: _locationService.zonesNotifier,
          builder: (context, zones, _) {
            final defaultCenter = userLocation ?? const LatLng(12.8235, 80.0442);

            return Scaffold(
              backgroundColor: const Color(0xFF070709),
              body: Stack(
                children: [
                  // Fullscreen Interactive Map
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: defaultCenter,
                      initialZoom: 16.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                      onTap: (tapPosition, point) => _onMapTapped(point),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.riskgrid',
                      ),

                      // Risk Circular Zones (100m user-flagged & permanent AI historical)
                      CircleLayer(
                        circles: zones.map((zone) {
                          Color fillColor;
                          Color borderColor;

                          if (zone.isHistorical) {
                            fillColor = const Color(0xFF7C4DFF).withValues(alpha: 0.28);
                            borderColor = const Color(0xFFB388FF);
                          } else if (zone.level == 'red') {
                            fillColor = const Color(0xFFFF1744).withValues(alpha: 0.32);
                            borderColor = const Color(0xFFFF5252);
                          } else {
                            fillColor = const Color(0xFFFFB800).withValues(alpha: 0.30);
                            borderColor = const Color(0xFFFFC107);
                          }

                          return CircleMarker(
                            point: LatLng(zone.latitude, zone.longitude),
                            radius: zone.radiusMeters,
                            useRadiusInMeter: true,
                            color: fillColor,
                            borderColor: borderColor,
                            borderStrokeWidth: 2.2,
                          );
                        }).toList(),
                      ),

                      // Markers (Zone Center Touch Icons + User Live Marker)
                      MarkerLayer(
                        markers: [
                          ...zones.map((zone) {
                            final Color iconColor = zone.isHistorical
                                ? const Color(0xFFD1C4E9)
                                : (zone.level == 'red'
                                    ? const Color(0xFFFF8A80)
                                    : const Color(0xFFFFE082));

                            return Marker(
                              point: LatLng(zone.latitude, zone.longitude),
                              width: 34.w,
                              height: 34.h,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _openDynamicIsland(zone),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF13061A).withValues(alpha: 0.92),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: iconColor, width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: iconColor.withValues(alpha: 0.4),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    zone.isHistorical
                                        ? Icons.history_edu_rounded
                                        : (zone.level == 'red'
                                            ? Icons.warning_rounded
                                            : Icons.report_problem_rounded),
                                    size: 18,
                                    color: iconColor,
                                  ),
                                ),
                              ),
                            );
                          }),

                          // Live GPS User Marker
                          if (userLocation != null)
                            Marker(
                              point: userLocation,
                              width: 44.w,
                              height: 44.h,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF00E5FF).withValues(alpha: 0.22),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                                      blurRadius: 16,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Container(
                                    width: 16.w,
                                    height: 16.h,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF00E5FF),
                                      border: Border.all(color: Colors.white, width: 2.5),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),

                  // Top Map Legend Pill (Left aligned)
                  Positioned(
                    top: 50,
                    left: 16,
                    child: SafeArea(
                      child: LiquidGlassContainer(
                        borderRadius: 20,
                        blurSigma: 6.0,
                        tintColor: const Color(0xFF120417),
                        tintOpacity: 0.75,
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _LegendDot(color: Color(0xFF7C4DFF), label: 'Predicted Risk'),
                            SizedBox(width: 8.w),
                            _LegendDot(color: Color(0xFFFFB800), label: 'Suspicion'),
                            SizedBox(width: 8.w),
                            _LegendDot(color: Color(0xFFFF1744), label: 'Danger'),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Right-side Floating Action Stack: Recenter GPS + Liquid Glass "+" Button
                  Positioned(
                    right: 20,
                    bottom: 100, // Positioned comfortably above the dock
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Recenter GPS Button
                        LiquidGlassContainer(
                          onTap: _recenterOnUser,
                          borderRadius: 28,
                          blurSigma: 6.0,
                          tintColor: const Color(0xFF14081B),
                          tintOpacity: 0.80,
                          padding: EdgeInsets.all(14.r),
                          child: Icon(
                            Icons.my_location_rounded,
                            color: Color(0xFF00E5FF),
                            size: 22,
                          ),
                        ),
                        SizedBox(height: 14.h),

                        // Liquid Glass "+" Button (Triggers "Flag a Risk" modal)
                        LiquidGlassContainer(
                          onTap: _openFlagRiskModal,
                          borderRadius: 28,
                          blurSigma: 6.0,
                          tintColor: const Color(0xFF381024),
                          tintOpacity: 0.88,
                          padding: EdgeInsets.all(14.r),
                          child: Icon(
                            Icons.add_rounded,
                            color: Color(0xFFD9779F),
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8.w,
          height: 8.h,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        SizedBox(width: 4.w),
        Text(
          label,
          style: TextStyle(color: Colors.white70, fontSize: 11.sp, fontFamily: 'Inter'),
        ),
      ],
    );
  }
}

/// Redesigned Liquid Glass Modal Sheet for Flagging a Risk
class _LiquidGlassFlagRiskSheet extends StatefulWidget {
  final LatLng userLocation;
  final ValueChanged<DangerZone> onSubmitted;

  const _LiquidGlassFlagRiskSheet({
    required this.userLocation,
    required this.onSubmitted,
  });

  @override
  State<_LiquidGlassFlagRiskSheet> createState() => _LiquidGlassFlagRiskSheetState();
}

class _LiquidGlassFlagRiskSheetState extends State<_LiquidGlassFlagRiskSheet> {
  String _selectedLevel = 'amber'; // 'amber' = Suspicion, 'red' = Danger
  String _selectedCategory = 'Fight';
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Fight',
    'Accident',
    'Theft',
    'Harassment',
    'Poor Lighting',
    'Other',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedLevel == 'red') {
      await AppHaptics.flagDanger();
    } else {
      await AppHaptics.flagSuspicion();
    }
    setState(() => _isSubmitting = true);

    final zone = await SafetyLocationService.instance.flagRiskAtCurrentLocation(
      level: _selectedLevel,
      category: _selectedCategory,
      description: _descriptionController.text.trim(),
    );

    if (mounted && zone != null) {
      Navigator.pop(context);
      widget.onSubmitted(zone);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xEE120519),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                color: const Color(0x33D9779F),
                width: 1.5.w,
              ),
            ),
            padding: EdgeInsets.fromLTRB(24, 14, 24, 28),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Modal Drag Handle
                  Center(
                    child: Container(
                      width: 44.w,
                      height: 4.5.h,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(3.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 18.h),

                  // Modal Title: Strictly "Flag a Risk" without subtitles
                  Text(
                    'Flag a Risk',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                    ),
                  ),
                  SizedBox(height: 22.h),

                  // Threat Level Selector: Liquid Glass Suspicion vs Danger buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildLiquidGlassThreatOption(
                          level: 'amber',
                          label: 'Suspicion',
                          icon: Icons.report_problem_rounded,
                          accentColor: const Color(0xFFFFB800),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildLiquidGlassThreatOption(
                          level: 'red',
                          label: 'Danger',
                          icon: Icons.warning_rounded,
                          accentColor: const Color(0xFFFF1744),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 22.h),

                  // Hazard Category Selector (Liquid Glass Treatment)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return LiquidGlassContainer(
                        onTap: () {
                          AppHaptics.categoryChip();
                          setState(() => _selectedCategory = cat);
                        },
                        borderRadius: 14,
                        blurSigma: 4.0,
                        tintColor: isSelected
                            ? const Color(0xFF4A1832)
                            : const Color(0xFF1B1123),
                        tintOpacity: isSelected ? 0.85 : 0.60,
                        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 9.h),
                        child: Text(
                          cat,
                          style: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFFA69EB0),
                            fontSize: 13.5.sp,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontFamily: 'Inter',
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 20.h),

                  // Brief Description Input
                  LiquidGlassTextField(
                    controller: _descriptionController,
                    hintText: 'Brief description (optional)',
                  ),
                  SizedBox(height: 24.h),

                  // Submit Button: Titled "Flag Risk"
                  LiquidGlassContainer(
                    onTap: _isSubmitting ? null : _submit,
                    borderRadius: 14,
                    tintColor: _selectedLevel == 'red'
                        ? const Color(0xFF5A1218)
                        : const Color(0xFF4A3410),
                    tintOpacity: 0.90,
                    blurSigma: 8.0,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    child: Center(
                      child: _isSubmitting
                          ? SizedBox(
                              height: 20.h,
                              width: 20.w,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Flag Risk',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inter',
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiquidGlassThreatOption({
    required String level,
    required String label,
    required IconData icon,
    required Color accentColor,
  }) {
    final isSelected = _selectedLevel == level;

    return LiquidGlassContainer(
      onTap: () {
        if (level == 'red') {
          AppHaptics.selectDanger();
        } else {
          AppHaptics.selectSuspicion();
        }
        setState(() => _selectedLevel = level);
      },
      borderRadius: 16,
      blurSigma: 6.0,
      tintColor: isSelected
          ? (level == 'red' ? const Color(0xFF4D1418) : const Color(0xFF403010))
          : const Color(0xFF1B1123),
      tintOpacity: isSelected ? 0.88 : 0.65,
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? accentColor : const Color(0xFF8A8294),
            size: 20,
          ),
          SizedBox(width: 8.w),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFFB0A8BA),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              fontSize: 15.sp,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}
