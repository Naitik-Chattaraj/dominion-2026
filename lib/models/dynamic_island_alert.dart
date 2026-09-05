import 'package:flutter/material.dart';
import 'danger_zone.dart';

enum DynamicIslandType {
  danger,
  suspicion,
  historical,
  safe,
  info,
}

class DynamicIslandAlert {
  final String id;
  final String title;
  final String description;
  final DynamicIslandType type;
  final String level; // 'red', 'amber', 'purple', 'cyan'
  final DangerZone? zone;
  final Duration autoDismissDuration;
  final VoidCallback? onTap;

  const DynamicIslandAlert({
    required this.id,
    required this.title,
    required this.description,
    this.type = DynamicIslandType.danger,
    this.level = 'red',
    this.zone,
    this.autoDismissDuration = const Duration(seconds: 7),
    this.onTap,
  });

  Color get accentColor {
    switch (type) {
      case DynamicIslandType.danger:
        return const Color(0xFFFF1744); // Neon Crimson
      case DynamicIslandType.suspicion:
        return const Color(0xFFFFB800); // Amber warning
      case DynamicIslandType.historical:
        return const Color(0xFFB388FF); // AI predictive purple
      case DynamicIslandType.safe:
        return const Color(0xFF00E5FF); // Neon cyan
      case DynamicIslandType.info:
        return const Color(0xFF64B5F6);
    }
  }

  IconData get icon {
    switch (type) {
      case DynamicIslandType.danger:
        return Icons.warning_rounded;
      case DynamicIslandType.suspicion:
        return Icons.report_problem_rounded;
      case DynamicIslandType.historical:
        return Icons.history_edu_rounded;
      case DynamicIslandType.safe:
        return Icons.verified_user_rounded;
      case DynamicIslandType.info:
        return Icons.info_outline_rounded;
    }
  }

  String get tagLabel {
    switch (type) {
      case DynamicIslandType.danger:
        return 'CRITICAL DANGER';
      case DynamicIslandType.suspicion:
        return 'ACTIVE SUSPICION';
      case DynamicIslandType.historical:
        return 'AI PREDICTED';
      case DynamicIslandType.safe:
        return 'ZONE CLEARED';
      case DynamicIslandType.info:
        return 'SAFETY NOTICE';
    }
  }
}
