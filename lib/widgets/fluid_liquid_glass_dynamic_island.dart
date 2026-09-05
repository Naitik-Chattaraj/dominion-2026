import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/danger_zone.dart';
import '../models/dynamic_island_alert.dart';
import '../services/dynamic_island_service.dart';
import '../utils/app_haptics.dart';

class FluidLiquidGlassDynamicIsland extends StatefulWidget {
  final void Function(DangerZone zone)? onViewOnMap;

  const FluidLiquidGlassDynamicIsland({
    super.key,
    this.onViewOnMap,
  });

  @override
  State<FluidLiquidGlassDynamicIsland> createState() =>
      _FluidLiquidGlassDynamicIslandState();
}

class _FluidLiquidGlassDynamicIslandState
    extends State<FluidLiquidGlassDynamicIsland>
    with TickerProviderStateMixin {
  late AnimationController _morphController;
  late Animation<double> _morphAnimation;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  Timer? _autoDismissTimer;
  DynamicIslandAlert? _currentAlert;

  @override
  void initState() {
    super.initState();

    // Elastic liquid morph physics
    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    );

    _morphAnimation = CurvedAnimation(
      parent: _morphController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );

    // Continuous pulse for active threat radar beacon
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOutQuad),
    );

    DynamicIslandService.instance.alertNotifier.addListener(_onAlertChanged);
  }

  @override
  void dispose() {
    DynamicIslandService.instance.alertNotifier.removeListener(_onAlertChanged);
    _autoDismissTimer?.cancel();
    _morphController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onAlertChanged() {
    final alert = DynamicIslandService.instance.alertNotifier.value;
    if (alert != null) {
      _autoDismissTimer?.cancel();
      setState(() => _currentAlert = alert);
      _morphController.forward(from: 0.0);

      _autoDismissTimer = Timer(alert.autoDismissDuration, () {
        if (mounted) _dismiss();
      });
    } else {
      _dismiss();
    }
  }

  void _dismiss() {
    _autoDismissTimer?.cancel();
    _morphController.reverse().then((_) {
      if (mounted) {
        setState(() => _currentAlert = null);
        DynamicIslandService.instance.alertNotifier.value = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _morphAnimation,
      builder: (context, _) {
        final double t = _morphAnimation.value;
        if (_currentAlert == null && t == 0.0) {
          return const SizedBox.shrink();
        }

        final double tClamped = t.clamp(0.0, 1.0);
        final screenWidth = MediaQuery.of(context).size.width;
        final topPadding = MediaQuery.of(context).padding.top;

        // Fluid morph dimensions: from a compact punch-hole pill into expanded glass capsule
        final targetWidth = (screenWidth - 24.w).clamp(310.0, 420.0);
        final double currentWidth = ui.lerpDouble(90.w, targetWidth, tClamped)!;
        final double currentHeight = ui.lerpDouble(28.h, 86.h, tClamped)!;
        final double borderRadius = ui.lerpDouble(18.r, 26.r, tClamped)!;

        final alert = _currentAlert;
        final Color accentColor = alert?.accentColor ?? const Color(0xFFFF1744);

        return Stack(
          alignment: Alignment.topCenter,
          children: [
            // Background interceptor to dismiss island when tapping anywhere else
            if (_currentAlert != null || t > 0.0)
              Positioned.fill(
                child: Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: (_) {
                    if (_currentAlert != null) {
                      AppHaptics.dynamicIslandDismiss();
                      _dismiss();
                    }
                  },
                ),
              ),
            
            // The actual island
            Positioned(
              top: topPadding + 4.h,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: (details) {
                  if (details.primaryDelta! < -4) {
                    AppHaptics.dynamicIslandDismiss();
                    _dismiss();
                  }
                },
                onTap: () {
                  if (alert?.zone != null && widget.onViewOnMap != null) {
                    AppHaptics.threatZoneTap(isDanger: alert!.level == 'red');
                    widget.onViewOnMap!(alert.zone!);
                    _dismiss();
                  }
                },
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: currentWidth,
                    height: currentHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(borderRadius),
                      // Outer glowing refraction border & ambient illumination
                      border: Border.all(
                        color: accentColor.withValues(
                          alpha: ui.lerpDouble(0.35, 0.85, tClamped)!,
                        ),
                        width: 1.4.w,
                      ),
                      boxShadow: [
                        // Dynamic accent neon aura
                        BoxShadow(
                          color: accentColor.withValues(
                            alpha: ui.lerpDouble(0.05, 0.40, tClamped)!,
                          ),
                          blurRadius: ui.lerpDouble(8.0, 24.0, tClamped)!,
                          spreadRadius: ui.lerpDouble(0.0, 2.0, tClamped)!,
                        ),
                        // Deep ambient occlusion
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.75),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(borderRadius),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xF2120816),
                                const Color(0xEE09050C),
                                accentColor.withValues(alpha: 0.12),
                              ],
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Top specular liquid reflection glint
                              Positioned(
                                top: 0,
                                left: 20.w,
                                right: 20.w,
                                height: 1.2.h,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.white.withValues(alpha: 0.65),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // Content Transition
                              if (tClamped < 0.45)
                                _buildCompactNotchPill(accentColor)
                              else
                                // Using OverflowBox to anchor content bounds to the final expanded size, 
                                // preventing the text from sliding horizontally while the container morphs.
                                OverflowBox(
                                  minWidth: targetWidth,
                                  maxWidth: targetWidth,
                                  minHeight: 86.h,
                                  maxHeight: 86.h,
                                  alignment: Alignment.center,
                                  child: _buildExpandedIslandContent(
                                    alert: alert,
                                    accentColor: accentColor,
                                    fadeProgress: ((tClamped - 0.45) / 0.55).clamp(0.0, 1.0),
                                  ),
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
          ],
        );
      },
    );
  }

  /// Compact punch-hole resting state
  Widget _buildCompactNotchPill(Color accentColor) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7.r,
            height: 7.r,
            decoration: BoxDecoration(
              color: accentColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 5.w),
          Text(
            'ALERT',
            style: TextStyle(
              color: accentColor,
              fontSize: 9.5.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  /// Fully expanded fluid liquid-glass presentation
  Widget _buildExpandedIslandContent({
    required DynamicIslandAlert? alert,
    required Color accentColor,
    required double fadeProgress,
  }) {
    if (alert == null) return const SizedBox.shrink();

    return Opacity(
      opacity: fadeProgress,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        child: Row(
          children: [
            // Glowing Icon with live pulsing radar ring
            SizedBox(
              width: 48.r,
              height: 48.r,
              child: Stack(
                alignment: Alignment.center,
                children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, _) {
                    final p = _pulseAnimation.value;
                    return Container(
                      width: 36.r + (12.r * p),
                      height: 36.r + (12.r * p),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: accentColor.withValues(alpha: (1.0 - p) * 0.45),
                          width: 1.5,
                        ),
                      ),
                    );
                  },
                ),
                Container(
                  width: 36.r,
                  height: 36.r,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.70),
                      width: 1.4,
                    ),
                  ),
                  child: Icon(
                    alert.icon,
                    color: accentColor,
                    size: 20.r,
                  ),
                ),
              ],
            ),
            ),
            SizedBox(width: 12.w),

            // Threat Details
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          alert.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.55),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          alert.tagLabel,
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 8.5.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    alert.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFFC7C0CE),
                      fontSize: 11.sp,
                      fontFamily: 'Inter',
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),

            // Action: View on Map or Dismiss
            if (alert.zone != null && widget.onViewOnMap != null)
              GestureDetector(
                onTap: () {
                  AppHaptics.threatZoneTap(isDanger: alert.level == 'red');
                  widget.onViewOnMap!(alert.zone!);
                  _dismiss();
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.map_rounded,
                        color: Colors.white,
                        size: 13.r,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'Map',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: () {
                  AppHaptics.dynamicIslandDismiss();
                  _dismiss();
                },
                child: Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white60,
                    size: 18.r,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
