class DangerZone {
  final String id;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final String level; // 'amber' (warning/suspicious) or 'red' (danger/immediate)
  final String category; // 'Fight', 'Accident', 'Theft', 'Harassment', 'Suspicious', 'Other'
  final String description;
  final DateTime timestamp;
  final bool isHistorical; // true = permanent AI predicted zone, false = 6h user-flagged
  final bool isSuppressed; // true if hidden because of a higher level elevation
  final String? suppressedZoneId; // ID of the zone it suppressed, if any

  DangerZone({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 100.0,
    required this.level,
    this.category = 'Suspicious',
    this.description = '',
    required this.timestamp,
    this.isHistorical = false,
    this.isSuppressed = false,
    this.suppressedZoneId,
  });

  bool get isExpired {
    if (isHistorical) return false; // Historical AI zones are permanent
    return DateTime.now().difference(timestamp).inHours >= 6;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
      'level': level,
      'category': category,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'isHistorical': isHistorical ? 1 : 0,
      'isSuppressed': isSuppressed ? 1 : 0,
      'suppressedZoneId': suppressedZoneId,
    };
  }

  factory DangerZone.fromMap(Map<String, dynamic> map) {
    return DangerZone(
      id: map['id'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      radiusMeters: (map['radiusMeters'] as num?)?.toDouble() ?? 100.0,
      level: map['level'] as String? ?? 'amber',
      category: map['category'] as String? ?? 'Suspicious',
      description: map['description'] as String? ?? '',
      timestamp: DateTime.parse(map['timestamp'] as String),
      isHistorical: (map['isHistorical'] as int?) == 1,
      isSuppressed: (map['isSuppressed'] as int?) == 1,
      suppressedZoneId: map['suppressedZoneId'] as String?,
    );
  }
}
