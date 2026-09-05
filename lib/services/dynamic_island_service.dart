import 'package:flutter/foundation.dart';
import '../models/danger_zone.dart';
import '../models/dynamic_island_alert.dart';
import '../utils/app_haptics.dart';
import 'notification_service.dart';

class DynamicIslandService {
  static final DynamicIslandService instance = DynamicIslandService._internal();

  DynamicIslandService._internal();

  final ValueNotifier<DynamicIslandAlert?> alertNotifier =
      ValueNotifier<DynamicIslandAlert?>(null);

  void showDangerZoneAlert(
    DangerZone zone, {
    bool isNewFlag = false,
    Duration duration = const Duration(seconds: 8),
  }) {
    DynamicIslandType type;
    if (zone.isHistorical) {
      type = DynamicIslandType.historical;
    } else if (zone.level == 'red') {
      type = DynamicIslandType.danger;
    } else {
      type = DynamicIslandType.suspicion;
    }

    final title = isNewFlag
        ? 'RISK FLAGGED: ${zone.category.toUpperCase()}'
        : (zone.level == 'red'
            ? 'CRITICAL ALERT: ${zone.category.toUpperCase()}'
            : '${zone.category.toUpperCase()} ALERT');

    final description = zone.description.isNotEmpty
        ? zone.description
        : (zone.isHistorical
            ? 'Permanent predictive risk from safety records'
            : 'Active 100m threat • Auto-expires in 6h');

    AppHaptics.threatZoneTap(isDanger: zone.level == 'red');

    // Also trigger native notification so it appears in notification tray
    NotificationService.instance.showHighPriorityNotification(
      id: zone.id.hashCode,
      title: title,
      body: description,
    );

    alertNotifier.value = DynamicIslandAlert(
      id: '${zone.id}_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      type: type,
      level: zone.level,
      zone: zone,
      autoDismissDuration: duration,
    );
  }

  void showAlert(DynamicIslandAlert alert) {
    AppHaptics.threatZoneTap(isDanger: alert.type == DynamicIslandType.danger);
    alertNotifier.value = alert;
  }

  void dismiss() {
    AppHaptics.dynamicIslandDismiss();
    alertNotifier.value = null;
  }
}
