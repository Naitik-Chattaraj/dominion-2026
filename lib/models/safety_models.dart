import 'package:flutter/material.dart';

enum SafetyStatus {
  allGood,
  staySafe,
  riskyArea,
}

extension SafetyStatusExtension on SafetyStatus {
  String get displayTitle {
    switch (this) {
      case SafetyStatus.allGood:
        return 'All Good';
      case SafetyStatus.staySafe:
        return 'Stay Safe';
      case SafetyStatus.riskyArea:
        return 'Risky Area';
    }
  }

  List<Color> get ambientGradientColors {
    switch (this) {
      case SafetyStatus.allGood:
        return const [
          Color(0xFF4C7524),
          Color(0xFF42671F),
          Color(0xFF355318),
          Color(0xFF284012),
          Color(0xFF1D2E0C),
          Color(0xFF142008),
          Color(0xFF0D1405),
          Color(0xFF090D05),
          Color(0xFF070709),
        ];
      case SafetyStatus.staySafe:
        return const [
          Color(0xFF7A5C1E),
          Color(0xFF6B511A),
          Color(0xFF594314),
          Color(0xFF45340F),
          Color(0xFF32260B),
          Color(0xFF221A07),
          Color(0xFF151005),
          Color(0xFF0C0A05),
          Color(0xFF070709),
        ];
      case SafetyStatus.riskyArea:
        return const [
          Color(0xFF7B2023),
          Color(0xFF6A1B1D),
          Color(0xFF561517),
          Color(0xFF420F11),
          Color(0xFF2F0A0C),
          Color(0xFF1F0608),
          Color(0xFF130405),
          Color(0xFF0B0405),
          Color(0xFF070709),
        ];
    }
  }

  static const List<double> ambientGradientStops = [
    0.0,
    0.10,
    0.22,
    0.36,
    0.50,
    0.64,
    0.78,
    0.90,
    1.0,
  ];

  Color get ambientColor {
    switch (this) {
      case SafetyStatus.allGood:
        return const Color(0xFF587E2B);
      case SafetyStatus.staySafe:
        return const Color(0xFF7E6325);
      case SafetyStatus.riskyArea:
        return const Color(0xFF7E282A);
    }
  }
}

class LocalIncidentReport {
  final String title;
  final String locationName;
  final String sourceTag;
  final String thumbnailAsset; // For now we can use a placeholder or gradient

  LocalIncidentReport({
    required this.title,
    required this.locationName,
    required this.sourceTag,
    required this.thumbnailAsset,
  });
}

class RiskyLocation {
  final String title;
  final String locationDetails;
  final double latitude;
  final double longitude;

  RiskyLocation({
    required this.title,
    required this.locationDetails,
    required this.latitude,
    required this.longitude,
  });
}
