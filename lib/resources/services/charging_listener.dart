import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'content_sync_service.dart';

class ChargingListener {
  final Battery _battery = Battery();
  StreamSubscription<BatteryState>? _subscription;
  final ContentSyncService _syncService = ContentSyncService();

  void start() {
    _subscription = _battery.onBatteryStateChanged.listen((state) async {
      if (state == BatteryState.charging) {
        try {
          await _syncService.syncNow();
        } catch (_) {
          // Reintenta en el próximo evento de carga.
        }
      }
    });
  }

  void dispose() => _subscription?.cancel();
}