import 'package:flutter/services.dart';

/// Centralized haptic feedback controller providing distinct physical rhythms
/// and vibrations tailored for safety threat levels and interactive UI gestures.
class AppHaptics {
  AppHaptics._();

  /// Cautionary dual-pulse rhythm for registering or interacting with Suspicion (Amber)
  static Future<void> flagSuspicion() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 110));
    await HapticFeedback.lightImpact();
  }

  /// High-urgency triple-burst impact rhythm for registering Danger (Red)
  static Future<void> flagDanger() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 90));
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.vibrate();
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
      await HapticFeedback.heavyImpact();
    } else {
      await HapticFeedback.mediumImpact();
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
