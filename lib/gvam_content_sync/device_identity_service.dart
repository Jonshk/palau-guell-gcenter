import 'package:shared_preferences/shared_preferences.dart';

import 'gcenter_runtime.dart';

class DeviceIdentityService {
  static const String _legacyDeviceIdKey =
      'gvam_device_manager_device_id';

  Future<String> getOrCreateDeviceId() async {
    final ventourUuid = GCenterRuntime.deviceUuid?.trim();
    if (ventourUuid != null && ventourUuid.isNotEmpty) {
      return ventourUuid;
    }

    // Compatibilidad temporal: si algún servicio consulta la identidad antes de
    // inicializar Ventour, reutilizamos el ID previo pero NO generamos uno nuevo.
    // En V5.4 el heartbeat se inicia únicamente después de GCenterRuntime.configure.
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(_legacyDeviceIdKey)?.trim();
    if (legacy != null && legacy.isNotEmpty) {
      return legacy;
    }

    throw StateError(
      'GCenter todavía no tiene el UUID Ventour. '
      'Inicializa GCenterRuntime antes de arrancar heartbeat/comandos.',
    );
  }
}
