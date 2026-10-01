import 'dart:async';

import 'package:battery_plus/battery_plus.dart';

import 'device_command_service.dart';
import 'device_report_service.dart';
import 'device_usage_service.dart';

class ChargingSyncListener {
  final Battery _battery = Battery();

  final DeviceUsageService _usage =
      DeviceUsageService();

  final DeviceReportService _reporter =
      DeviceReportService();

  final DeviceCommandService _commands =
      DeviceCommandService();

  StreamSubscription<BatteryState>? _subscription;

  bool _handling = false;

  void start() {
    _subscription?.cancel();

    _subscription =
        _battery.onBatteryStateChanged.listen(
      (state) async {
        final charging =
            state == BatteryState.charging ||
                state == BatteryState.full;

        if (!charging || _handling) {
          return;
        }

        _handling = true;

        try {
          await _reporter.sendReport(
            phase: 'charging',
          );

          if (await _usage.isIdle()) {
            await _commands.pollOnce();
          }
        } finally {
          _handling = false;
        }
      },
    );
  }

  Future<void>
      checkImmediatelyIfCharging() async {
    final state =
        await _battery.batteryState;

    final charging =
        state == BatteryState.charging ||
            state == BatteryState.full;

    if (!charging || _handling) {
      return;
    }

    _handling = true;

    try {
      await _reporter.sendReport(
        phase: 'charging',
      );

      if (await _usage.isIdle()) {
        await _commands.pollOnce();
      }
    } finally {
      _handling = false;
    }
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
