import 'dart:convert';
import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import 'device_identity_service.dart';
import 'device_usage_service.dart';
import 'gcenter_runtime.dart';

class DeviceReportService {
  static const String baseUrl =
      'http://192.168.1.96:8080';

  final DeviceIdentityService _identity =
      DeviceIdentityService();

  final DeviceUsageService _usage =
      DeviceUsageService();

  final Battery _battery = Battery();

  final DeviceInfoPlugin _deviceInfo =
      DeviceInfoPlugin();

  Future<void> sendReport({
    required String phase,

    // IMPORTANTE:
    // Estos valores son nullable para que un heartbeat
    // NO sobrescriba con 0 el último estado de contenido.
    int? expectedTotal,
    int? correctTotal,
    int? missingTotal,
    int? updateExpected,
    int? updateDone,
    int? cleanupExpected,
    int? cleanupDone,

    int? bytesTotal,
    int? bytesDone,
    double? speedBps,
    int? etaSeconds,
    int? elapsedSeconds,

    String? currentFile,
    String? error,
  }) async {
    try {
      final packageInfo =
          await PackageInfo.fromPlatform();

      final deviceId =
          await _identity.getOrCreateDeviceId();

      
      final usageState =
          await _usage.getState();

      final batteryLevel =
          await _battery.batteryLevel;

      final batteryState =
          await _battery.batteryState;

      String? manufacturer;
      String? model;
      String? androidVersion;
      int? sdkInt;

      if (Platform.isAndroid) {
        final android =
            await _deviceInfo.androidInfo;

        manufacturer =
            android.manufacturer;

        model =
            android.model;

        androidVersion =
            android.version.release;

        sdkInt =
            android.version.sdkInt;
      }

      final body = <String, dynamic>{
        'device_id':
            deviceId,

        
        'bundle_id':
            packageInfo.packageName,

        'usage_state':
            usageState,

        'phase':
            phase,

        'app_version':
            packageInfo.version,

        'app_build':
            int.tryParse(
              packageInfo.buildNumber,
            ) ??
                0,

        'battery_level':
            batteryLevel,

        'charging':
            batteryState ==
                    BatteryState.charging ||
                batteryState ==
                    BatteryState.full,

        'manufacturer':
            manufacturer,

        'model':
            model,

        'android_version':
            androidVersion,

        'sdk_int':
            sdkInt,

        'publication_id':
            GCenterRuntime.publicationId,

        'current_file':
            currentFile,

        'error':
            error,
      };

      // -------------------------------------------------
      // CONTENIDO
      //
      // Solo añadimos estas claves cuando realmente
      // tenemos información nueva que enviar.
      //
      // Así el heartbeat NO pone 0/0 después de reiniciar.
      // -------------------------------------------------

      if (expectedTotal != null) {
        body['expected_total'] =
            expectedTotal;
      }

      if (correctTotal != null) {
        body['ok_total'] =
            correctTotal;
      }

      if (missingTotal != null) {
        body['missing_total'] =
            missingTotal;
      }

      if (updateExpected != null) {
        body['update_expected'] =
            updateExpected;
      }

      if (updateDone != null) {
        body['update_done'] =
            updateDone;
      }

      if (cleanupExpected != null) {
        body['cleanup_expected'] =
            cleanupExpected;
      }

      if (cleanupDone != null) {
        body['cleanup_done'] =
            cleanupDone;
      }

      // -------------------------------------------------
      // TRANSFERENCIA
      // -------------------------------------------------

      if (bytesTotal != null) {
        body['bytes_total'] =
            bytesTotal;
      }

      if (bytesDone != null) {
        body['bytes_done'] =
            bytesDone;
      }

      if (speedBps != null) {
        body['speed_bps'] =
            speedBps;
      }

      if (etaSeconds != null) {
        body['eta_seconds'] =
            etaSeconds;
      }

      if (elapsedSeconds != null) {
        body['elapsed_seconds'] =
            elapsedSeconds;
      }

      await http
          .post(
            Uri.parse(
              '$baseUrl/api/device/report',
            ),
            headers: const {
              'Content-Type':
                  'application/json',
            },
            body: jsonEncode(
              body,
            ),
          )
          .timeout(
            const Duration(
              seconds: 8,
            ),
          );
    } catch (_) {
      // La telemetría de GCenter nunca debe
      // bloquear el funcionamiento de la audioguía.
    }
  }
}