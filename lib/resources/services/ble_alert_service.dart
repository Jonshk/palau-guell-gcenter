part of '/resources/config/services.dart';

class BleAlertService {
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  bool _modalShown = false;
  bool _isScanning = false;
  OverlayEntry? overlayEntry;

  void initialize() {
    scan();
  }

  Future<void> _safeStopScan() async {
    if (_isScanning) {
      try {
        await _scanSubscription?.cancel();
        _scanSubscription = null;
        _isScanning = false;
        await FlutterBluePlus.stopScan();
      } catch (e) {
        Logger.error(e, "BleAlertService", "_safeStopScan");
      }
    } else {}
  }

  Future<void> scan() async {
    try {
      final permissionsGranted = await _requestPermissions();
      if (!permissionsGranted) {
        return;
      }
      final availability = await _checkAvailability();
      if (!availability["status"]) {
        return;
      }
      await _startScan();
    } catch (e) {
      Logger.error(e, "BleAlertService", "scan");
    }
  }

  Future<bool> _requestPermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    statuses.forEach((permission, status) {});

    final allGranted = statuses.values.every((s) => s == PermissionStatus.granted);

    if (!allGranted) {
      final anyPermanentlyDenied = statuses.values.any((s) => s == PermissionStatus.permanentlyDenied);
      if (anyPermanentlyDenied) {
        await openAppSettings();
      }
    }

    return allGranted;
  }

  Future<Map<String, dynamic>> _checkAvailability() async {
    if (!await FlutterBluePlus.isSupported) {
      return {"status": false, "message": "Bluetooth no disponible"};
    }
    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      return {"status": false, "message": "Bluetooth apagado"};
    }
    return {"status": true};
  }

  Future<void> _startScan() async {
    await _safeStopScan();
    await Future.delayed(const Duration(milliseconds: 400));
    await _scanWithFilters();
  }

  Future<void> _scanWithFilters() async {
    _isScanning = true;

    _scanSubscription = FlutterBluePlus.scanResults.listen(
      _processScanResults,
      onError: (error) {
        _startScan();
      },
    );

    await FlutterBluePlus.startScan(continuousUpdates: true, androidScanMode: AndroidScanMode.lowLatency);
  }

  Future<void> _processScanResults(List<ScanResult> results) async {
    if (results.isEmpty) return;

    for (final result in results) {
      final serviceData = result.advertisementData.serviceData;

      if (serviceData.isEmpty) continue;

      final uuid = serviceData.keys.first;
      final bytes = serviceData[uuid];
      if (bytes == null || bytes.isEmpty) continue;

      final byteData = ByteData.view(Uint8List.fromList(bytes).buffer);

      final beacon = decodeEddystone(byteData);

      if (beacon != null) {
        if (beacon.namespace.replaceAll(RegExp(r'[^\x20-\x7E]'), '').trim() == AppConstants.namespace) {
          final distance = _calculateDistance(result.rssi);

          if (distance > 0 && distance <= AppConstants.triggerDistance && !_modalShown) {
            _openOverlay();
          }
        }
      }
    }
  }

  void _openOverlay() {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;
    if (Get.context != null) {
      _modalShown = true;
      overlayEntry = OverlayEntry(
        builder: (_) => GestureDetector(
          child: BLEAlertOverlay(
            close: () {
              if (overlayEntry != null) {
                overlayEntry?.remove();
                overlayEntry?.dispose();
                overlayEntry = null;
                Future.delayed(const Duration(seconds: 5), () => _modalShown = false);
              }
            },
          ),
        ),
      );
      overlay.insert(overlayEntry!);
    }
  }

  double _calculateDistance(int rssi, {int txPower = -71}) {
    if (rssi == 0) return -1.0;
    final ratio = rssi / txPower;
    if (ratio < 1.0) return pow(ratio, 10).toDouble();
    return 0.89976 * pow(ratio, 7.7095) + 0.111;
  }
}
