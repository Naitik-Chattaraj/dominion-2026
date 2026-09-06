import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../models/safety_models.dart';
import '../models/danger_zone.dart';
import '../database/riskgrid_database.dart';
import '../utils/app_haptics.dart';
import 'dynamic_island_service.dart';

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

  final ValueNotifier<DangerZone?> mapFocusZoneNotifier =
      ValueNotifier<DangerZone?>(null);

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

  bool _isMockingLocation = false;
  LatLng? _mockLocation;
  String? _mockLocationName;
  Position? _lastRealPosition;
  final ValueNotifier<LatLng?> mapRecenterNotifier = ValueNotifier<LatLng?>(null);

  void recenterMap(LatLng target) {
    mapRecenterNotifier.value = target;
  }

  void enableMockLocation(double lat, double lng, {String? locationName}) {
    _isMockingLocation = true;
    _mockLocation = LatLng(lat, lng);
    _mockLocationName = locationName;
    locationNotifier.value = _mockLocation;
    mapRecenterNotifier.value = _mockLocation;
    _recalculateSafetyStatus(lat, lng);
  }

  void disableMockLocation() {
    _isMockingLocation = false;
    _mockLocation = null;
    _mockLocationName = null;
    if (_lastRealPosition != null) {
      _updateUserPosition(_lastRealPosition!);
      mapRecenterNotifier.value = LatLng(_lastRealPosition!.latitude, _lastRealPosition!.longitude);
    } else {
      Geolocator.getCurrentPosition().then((pos) {
        if (!_isMockingLocation) {
          _updateUserPosition(pos);
          mapRecenterNotifier.value = LatLng(pos.latitude, pos.longitude);
        }
      }).catchError((_) {});
    }
  }

  bool get isMockingLocation => _isMockingLocation;
  LatLng? get mockLocation => _mockLocation;
  String? get mockLocationName => _mockLocationName;

  void _updateUserPosition(Position pos) {
    _lastRealPosition = pos;
    if (_isMockingLocation) return;
    locationNotifier.value = LatLng(pos.latitude, pos.longitude);
    _recalculateSafetyStatus(pos.latitude, pos.longitude);
  }

  void _recalculateSafetyStatus(double lat, double lng) {
    bool inRedZone = false;
    bool inAmberZone = false;
    String? matchedZoneName;
    DangerZone? matchedDangerZone;

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
          matchedDangerZone = zone;
          matchedZoneName = '${zone.category} (${zone.radiusMeters.toInt()}m Danger)';
          break; // Red takes highest priority
        } else if (zone.level == 'amber' || zone.isHistorical) {
          inAmberZone = true;
          matchedDangerZone ??= zone;
          matchedZoneName = zone.isHistorical
              ? 'AI Historical Risk: ${zone.category}'
              : '${zone.category} (Reported Hazard)';
        }
      }
    }

    currentZoneInfoNotifier.value = matchedZoneName;

    final previousStatus = statusNotifier.value;
    SafetyStatus newStatus = SafetyStatus.allGood;

    if (inRedZone) {
      newStatus = SafetyStatus.riskyArea;
    } else if (inAmberZone) {
      newStatus = SafetyStatus.staySafe;
    }

    if (newStatus == SafetyStatus.riskyArea && previousStatus != SafetyStatus.riskyArea) {
      AppHaptics.flagDanger();
      if (matchedDangerZone != null) {
        DynamicIslandService.instance.showDangerZoneAlert(
          matchedDangerZone,
          showNativeNotification: true, // Show native priority notification when user physically enters zone
        );
      }
    } else if (newStatus == SafetyStatus.staySafe && previousStatus == SafetyStatus.allGood) {
      AppHaptics.flagSuspicion();
      if (matchedDangerZone != null) {
        DynamicIslandService.instance.showDangerZoneAlert(
          matchedDangerZone,
          showNativeNotification: true, // Show native priority notification when user physically enters zone
        );
      }
    }

    statusNotifier.value = newStatus;
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

    // Trigger in-app Dynamic Island alert (no native notification on manual flag)
    DynamicIslandService.instance.showDangerZoneAlert(
      newZone,
      isNewFlag: true,
      showNativeNotification: false,
    );

    return newZone;
  }

  /// Elevates an existing suspicious zone to a red Danger zone (removes suspicion, enables danger)
  Future<DangerZone> elevateSuspiciousZoneToDanger({
    required DangerZone existingZone,
    String? category,
    String? description,
  }) async {
    final elevatedZone = DangerZone(
      id: const Uuid().v4(),
      latitude: existingZone.latitude,
      longitude: existingZone.longitude,
      radiusMeters: existingZone.radiusMeters,
      level: 'red',
      category: (category != null && category.isNotEmpty) ? category : existingZone.category,
      description: (description != null && description.isNotEmpty)
          ? description
          : (existingZone.description.isNotEmpty
              ? '${existingZone.description} • Elevated to Danger'
              : 'Elevated from Suspicion to Danger zone • Active 100m threat'),
      timestamp: DateTime.now(),
      isHistorical: false,
    );

    await _db.elevateZoneToDanger(
      oldZoneId: existingZone.id,
      elevatedZone: elevatedZone,
    );
    await refreshZones();

    await AppHaptics.flagDanger();

    // Trigger in-app Dynamic Island alert
    DynamicIslandService.instance.showDangerZoneAlert(
      elevatedZone,
      isNewFlag: true,
      showNativeNotification: false,
    );

    return elevatedZone;
  }

  void dispose() {
    _positionSubscription?.cancel();
  }
}
