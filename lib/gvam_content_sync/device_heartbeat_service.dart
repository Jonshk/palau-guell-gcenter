import 'dart:async';

import 'device_command_service.dart';
import 'device_report_service.dart';

class DeviceHeartbeatService {
  final DeviceReportService _reporter =
      DeviceReportService();

  final DeviceCommandService _commands;

  Timer? _timer;
  bool _tickRunning = false;

  DeviceHeartbeatService({
    DeviceCommandService? commands,
  }) : _commands =
            commands ??
                DeviceCommandService();

  void start() {
    _timer?.cancel();

    _tick();

    _timer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _tick(),
    );
  }

  /// Envía el estado inmediatamente a GCenter.
  ///
  /// Se permite que coincida con el heartbeat periódico:
  /// un reporte duplicado es preferible a esperar 15 s
  /// cuando acabamos de recibir físicamente un equipo.
  Future<void> sendNow({
    bool pollCommands = true,
  }) async {
    await _reporter.sendReport(
      phase: 'heartbeat',
    );

    if (pollCommands) {
      await _commands.pollOnce();
    }
  }

  Future<void> _tick() async {
    if (_tickRunning) return;

    _tickRunning = true;

    try {
      await _reporter.sendReport(
        phase: 'heartbeat',
      );

      await _commands.pollOnce();
    } finally {
      _tickRunning = false;
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
