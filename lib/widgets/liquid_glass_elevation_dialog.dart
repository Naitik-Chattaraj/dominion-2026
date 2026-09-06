import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/danger_zone.dart';
import '../utils/app_haptics.dart';
import 'liquid_glass_container.dart';

class LiquidGlassElevationDialog extends StatelessWidget {
  final DangerZone existingZone;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const LiquidGlassElevationDialog({
    super.key,
    required this.existingZone,
    required this.onConfirm,
    this.onCancel,
  });

  static Future<bool?> show(
    BuildContext context, {
    required DangerZone existingZone,
    required VoidCallback onConfirm,
  }) {
    AppHaptics.openModal();
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.70),
      barrierDismissible: true,
      builder: (ctx) => LiquidGlassElevationDialog(
        existingZone: existingZone,
        onConfirm: () {
          Navigator.of(ctx).pop(true);
          onConfirm();
        },
        onCancel: () {
          Navigator.of(ctx).pop(false);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26.r),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xEE14051B),
                  borderRadius: BorderRadius.circular(26.r),
                  border: Border.all(
                    color: const Color(0xFFFF1744).withValues(alpha: 0.65),
                    width: 1.5.w,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF1744).withValues(alpha: 0.25),
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.85),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(22.r),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Warning Icon with pulsating danger halo
                    Container(
                      width: 54.r,
                      height: 54.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFF1744).withValues(alpha: 0.18),
                        border: Border.all(
                          color: const Color(0xFFFF1744).withValues(alpha: 0.75),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: const Color(0xFFFF1744),
                        size: 30.r,
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Dialog Title
                    Text(
                      'Elevate to Danger?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(height: 10.h),

                    // Current Suspicion Tag
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB800).withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: const Color(0xFFFFB800).withValues(alpha: 0.60),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        'Currently: Suspicious (${existingZone.category})',
                        style: TextStyle(
                          color: const Color(0xFFFFB800),
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                    SizedBox(height: 14.h),

                    // Descriptive Explanation
                    Text(
                      'This area is already marked suspicious. Do you want to elevate it to a Danger zone? Suspicion will be removed and full danger alerts will be enabled.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFFC7C0CE),
                        fontSize: 13.sp,
                        fontFamily: 'Inter',
                        height: 1.35,
                      ),
                    ),
                    SizedBox(height: 22.h),

                    // Action Buttons Row
                    Row(
                      children: [
                        // Cancel
                        Expanded(
                          child: LiquidGlassContainer(
                            onTap: onCancel ?? () => Navigator.of(context).pop(false),
                            borderRadius: 14,
                            tintColor: const Color(0xFF24152A),
                            tintOpacity: 0.80,
                            padding: EdgeInsets.symmetric(vertical: 13.h),
                            child: Center(
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),

                        // Yes, Elevate to Danger
                        Expanded(
                          child: LiquidGlassContainer(
                            onTap: () {
                              AppHaptics.flagDanger();
                              onConfirm();
                            },
                            borderRadius: 14,
                            tintColor: const Color(0xFF6B121C),
                            tintOpacity: 0.95,
                            padding: EdgeInsets.symmetric(vertical: 13.h),
                            child: Center(
                              child: Text(
                                'Elevate',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
