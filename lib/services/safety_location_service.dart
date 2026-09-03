import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../models/safety_models.dart';
import '../models/danger_zone.dart';
import '../database/riskgrid_database.dart';

class SafetyLocationService {
  static final SafetyLocationService instance = SafetyLocationService._internal();

  SafetyLocationService._internal();

  final RiskGridDatabase _db = RiskGridDatabase.instance;

  final ValueNotifier<SafetyStatus> statusNotifier =
      ValueNotifier<SafetyStatus>(SafetyStatus.allGood);

  final ValueNotifier<LatLng?> locationNotifier = ValueNotifier<LatLng?>(null);

  final ValueNotifier<List<DangerZone>> zonesNotifier =
      ValueNotifier<List<DangerZone>>([]);

  final ValueNotifier<String?> currentZoneInfoNotifier =
      ValueNotifier<String?>(null);

  StreamSubscription<Position>? _positionSubscription;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    await refreshZones();

    // Check permissions
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    // Initial position fetch
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _updateUserPosition(pos);
    } catch (_) {}

    // Continuous location streaming
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Update every 5 meters
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position pos) {
      _updateUserPosition(pos);
    });
  }

  Future<void> refreshZones() async {
    await _db.deleteExpiredDangerZones();
    final zones = await _db.getActiveDangerZones();
    zonesNotifier.value = zones;

    final currentLoc = locationNotifier.value;
    if (currentLoc != null) {
      _recalculateSafetyStatus(currentLoc.latitude, currentLoc.longitude);
    }
  }

  void _updateUserPosition(Position pos) {
    locationNotifier.value = LatLng(pos.latitude, pos.longitude);
    _recalculateSafetyStatus(pos.latitude, pos.longitude);
  }

  void _recalculateSafetyStatus(double lat, double lng) {
    bool inRedZone = false;
    bool inAmberZone = false;
    String? matchedZoneName;

    for (final zone in zonesNotifier.value) {
      final double distance = Geolocator.distanceBetween(
        lat,
        lng,
        zone.latitude,
        zone.longitude,
      );

      // User is inside the circular radius
      if (distance <= zone.radiusMeters) {
        if (zone.level == 'red') {
          inRedZone = true;
          matchedZoneName = '${zone.category} (${zone.radiusMeters.toInt()}m Danger)';
          break; // Red takes highest priority
        } else if (zone.level == 'amber' || zone.isHistorical) {
          inAmberZone = true;
          matchedZoneName = zone.isHistorical
              ? 'AI Historical Risk: ${zone.category}'
              : '${zone.category} (Reported Hazard)';
        }
      }
    }

    currentZoneInfoNotifier.value = matchedZoneName;

    if (inRedZone) {
      statusNotifier.value = SafetyStatus.riskyArea;
    } else if (inAmberZone) {
      statusNotifier.value = SafetyStatus.staySafe;
    } else {
      statusNotifier.value = SafetyStatus.allGood;
    }
  }

  /// Flags a 100-meter circular risk zone centered strictly at user's current GPS location
  Future<DangerZone?> flagRiskAtCurrentLocation({
    required String level, // 'amber' or 'red'
    required String category,
    required String description,
  }) async {
    LatLng? currentPos = locationNotifier.value;

    // If stream hasn't produced a location yet, fetch fresh GPS
    if (currentPos == null) {
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        currentPos = LatLng(pos.latitude, pos.longitude);
        locationNotifier.value = currentPos;
      } catch (e) {
        return null;
      }
    }

    final newZone = DangerZone(
      id: const Uuid().v4(),
      latitude: currentPos.latitude,
      longitude: currentPos.longitude,
      radiusMeters: 100.0, // Fixed 100m circular radius centered at user
      level: level,
      category: category,
      description: description,
      timestamp: DateTime.now(),
      isHistorical: false,
    );

    await _db.createDangerZone(newZone);
    await refreshZones();

    return newZone;
  }

  void dispose() {
    _positionSubscription?.cancel();
  }
}
