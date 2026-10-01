part of 'mastersync.dart';

class BLEScanOptions {
  final _format = Guid("180f");
  // Añadir las MAC de las raspberry que quiera escanear
  final List<String> remoteIds = ["88:A2:9E:9C:CE:35"];
  final bool enableFilterByContent;
  final String contentUuid;

  BLEScanOptions({required this.contentUuid, this.enableFilterByContent = true});

  List<Guid> servicesGuid() {
    List<Guid> services = [];
    if (enableFilterByContent) {
      services.add(_format);
      var guid = _stringToGuid(contentUuid);
      if (guid != null) {
        services.add(guid);
      }
    }
    return services;
  }

  Guid? _stringToGuid(String uuid) {
    if (uuid.isEmpty) return null;
    String hexStr = uuid.replaceAll('-', '');
    List<int> bytes = [];
    for (int i = 0; i < hexStr.length; i += 2) {
      bytes.add(int.parse(hexStr.substring(i, i + 2), radix: 16));
    }
    return Guid.fromBytes(bytes.toList());
  }
}

class BLEService {
  final PlayerController _controller;
  final List<int> _arraySeconds = [];
  DateTime _lastTimestamp = DateTime(0, 0, 0);
  BLEScanOptions _options = BLEScanOptions(contentUuid: "");
  Timer? _timer;

  StreamSubscription<List<ScanResult>>? _scanSubscription;

  BLEService({required PlayerController controller}) : _controller = controller;

  void _initialize(String contentUuid) {
    _options = BLEScanOptions(contentUuid: contentUuid);
    scan();
  }

  Future<void> stop() async {
    _arraySeconds.clear();
    _timer?.cancel();
    _timer = null;
    _controller.isSync.value = false;
    await _safeStopScan();
  }

  Future<void> _safeStopScan() async {
    if (_controller.isScanning.value) {
      try {
        await _scanSubscription?.cancel();
        _scanSubscription = null;
        _controller.isScanning.value = false;
        await FlutterBluePlus.stopScan();
      } catch (e) {
        /* ToastService.show(
          "Error al detener",
          "$e",
          AppTheme.danger,
          duration: const Duration(microseconds: 2400),
          icon: Icons.sensors_off,
        ); */
      }
    }
  }

  Future<void> scan() async {
    try {
      var availability = await _checkAvailability();
      if (!availability["status"]) {
        /* ToastService.show(
          "Error de disponibilidad",
          availability["message"],
          AppTheme.danger,
          duration: const Duration(microseconds: 2400),
          icon: availability["icon"],
        ); */
        return;
      }

      await _startScan();
    } catch (e) {
      /* ToastService.show(
        "Error en escaneo",
        "$e",
        AppTheme.danger,
        duration: const Duration(microseconds: 2400),
        icon: Icons.sensors_off,
      ); */
    }
  }

  Future<Map<String, dynamic>> _checkAvailability() async {
    if (!await FlutterBluePlus.isSupported) {
      return {"status": false, "message": "Bluetooth no disponible", "icon": Icons.bluetooth_disabled};
    }
    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      return {"status": false, "message": "Bluetooth está apagado", "icon": Icons.bluetooth_disabled};
    }
    return {"status": true, "message": "Okay"};
  }

  Future<void> _startScan() async {
    await _safeStopScan();
    await Future.delayed(const Duration(milliseconds: 400));
    await _scanWithFilters();
  }

  Future<void> _scanWithFilters() async {
    _controller.isScanning.value = true;
    _controller.isSync.value = true;
    _scanSubscription = FlutterBluePlus.scanResults.listen(
      _processScanResults,
      onError: (error) {
        _startScan();
      },
    );

    await FlutterBluePlus.startScan(
      withRemoteIds: _options.remoteIds,
      continuousUpdates: true,
      androidScanMode: AndroidScanMode.lowLatency,
      removeIfGone: const Duration(milliseconds: 10),
    );
  }

  Future<void> _processScanResults(List<ScanResult> results) async {
    for (var result in results) {
      final resultUuids = result.advertisementData.serviceUuids;
      final requiredUuids = _options.servicesGuid();
      final match = requiredUuids.every((uuid) => resultUuids.contains(uuid));
      if (!match) {
        continue;
      }
      if (!_lastTimestamp.isBefore(result.timeStamp)) {
        continue;
      }
      final serviceData = result.advertisementData.serviceData[_options._format];
      if (serviceData != null && serviceData.isNotEmpty) {
        try {
          final String secondStr = String.fromCharCodes(serviceData);
          int milliseconds = int.parse(secondStr);
          _lastTimestamp = result.timeStamp;
          await _controller._playAudio(milliseconds);
          await stop();
          return;
        } catch (e) {
          /* ToastService.show(
            "Error al decodificar el mensaje",
            "$e",
            AppTheme.danger,
            duration: const Duration(microseconds: 2400),
            icon: Icons.sensors_off,
          ); */
        }
      }
    }
  }
}
