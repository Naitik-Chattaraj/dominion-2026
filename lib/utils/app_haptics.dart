import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Centralized haptic feedback controller providing distinct physical rhythms
/// and vibrations tailored for safety threat levels and interactive UI gestures.
class AppHaptics {
  AppHaptics._();

  static Future<void> _customVibrate(List<int> pattern, List<int> intensities) async {
    try {
      bool? hasVibrator = await Vibration.hasVibrator();
      bool? hasCustomVibrationsSupport = await Vibration.hasCustomVibrationsSupport();
      
      if (hasVibrator == true) {
        if (hasCustomVibrationsSupport == true) {
          await Vibration.vibrate(pattern: pattern, intensities: intensities);
        } else {
          await Vibration.vibrate();
        }
      } else {
        await HapticFeedback.vibrate();
      }
    } catch (_) {
      try {
        await HapticFeedback.vibrate();
      } catch (_) {}
    }
  }

  /// Cautionary dual-pulse rhythm for registering or interacting with Suspicion (Amber)
  static Future<void> flagSuspicion() async {
    // short-short pattern
    await HapticFeedback.mediumImpact();
    await _customVibrate([0, 50, 100, 50], [0, 128, 0, 128]);
  }

  /// High-urgency triple-burst impact rhythm for registering Danger (Red)
  static Future<void> flagDanger() async {
    // intense long pattern
    await HapticFeedback.heavyImpact();
    await _customVibrate([0, 150, 50, 200, 50, 250], [0, 255, 0, 255, 0, 255]);
  }

  /// Feedback when choosing the Suspicion threat level in modal
  static Future<void> selectSuspicion() async {
    await HapticFeedback.mediumImpact();
  }

  /// Feedback when choosing the Danger threat level in modal
  static Future<void> selectDanger() async {
    await HapticFeedback.heavyImpact();
  }

  /// Tactile feedback when selecting a hazard category chip
  static Future<void> categoryChip() async {
    await HapticFeedback.selectionClick();
  }

  /// Feedback when tapping a danger circle on the map to trigger Dynamic Island
  static Future<void> threatZoneTap({required bool isDanger}) async {
    if (isDanger) {
      await flagDanger();
    } else {
      await flagSuspicion();
    }
  }

  /// Tactile snap feedback when the Dynamic Island contracts and dismisses
  static Future<void> dynamicIslandDismiss() async {
    await HapticFeedback.lightImpact();
  }

  /// Tactile pulse when opening the floating flag modal
  static Future<void> openModal() async {
    await HapticFeedback.mediumImpact();
  }

  /// Tactile feedback when tapping the map recenter button
  static Future<void> recenterMap() async {
    await HapticFeedback.selectionClick();
  }

  /// Generic crisp card or news tile tap
  static Future<void> cardTap() async {
    await HapticFeedback.selectionClick();
  }

  /// Pull-to-refresh activation feedback
  static Future<void> pullRefresh() async {
    await HapticFeedback.mediumImpact();
  }
}
