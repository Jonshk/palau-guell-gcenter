import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'apk_update_service.dart';
import 'content_sync_service.dart';
import 'device_identity_service.dart';
import 'device_usage_service.dart';

class DeviceCommandService {
  static const String baseUrl = 'http://192.168.1.96:8080';

  final DeviceIdentityService _identity = DeviceIdentityService();
  final DeviceUsageService _usage = DeviceUsageService();
  final ContentSyncService _contentSync = ContentSyncService();
  final ApkUpdateService _apkUpdate = ApkUpdateService();
  bool _running = false;

  static const MethodChannel _appChannel = MethodChannel('gcenter/app');

  DeviceCommandService();

  Future<void> pollOnce() async {
    if (_running || !await _usage.isIdle()) return;
    _running = true;

    try {
      final deviceId = await _identity.getOrCreateDeviceId();
      final response = await http
          .get(Uri.parse('$baseUrl/api/device/$deviceId/next-command'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final command = data['command'];
      if (command == null) return;

      final leaseId = data['lease_id'];
      if (leaseId is! int) return;

      final parallel =
          (data['parallel_downloads'] as num?)?.toInt() ?? 2;

      await _setStatus(deviceId, leaseId, 'running');

      try {
        var restartAfterDone = false;

        switch (command) {
          case 'update_content':
            restartAfterDone = await _runContentUpdate(parallel);
            break;

          case 'update_apk':
            await _showProgress(
              5,
              title: 'Actualizando APK',
              detail: 'Comprobando nueva versión…',
            );
            final apkResult = await _apkUpdate.updateIfAvailable();
            if (!apkResult.updateAvailable) {
              await _showProgress(
                100,
                title: 'APK actualizada',
                detail: 'Ya tienes la última versión',
              );
              await Future.delayed(const Duration(milliseconds: 900));
              await _hideProgress();
            } else {
              await _showProgress(
                100,
                title: 'APK descargada',
                detail: 'Abriendo instalador…',
              );
            }
            break;

          case 'update_all':
            restartAfterDone = await _runContentUpdate(parallel);
            final apkResult = await _apkUpdate.updateIfAvailable();
            if (apkResult.installerOpened) {
              restartAfterDone = false;
            }
            break;

          default:
            throw Exception('Comando desconocido: $command');
        }

        await _setStatus(deviceId, leaseId, 'done');

        if (restartAfterDone) {
          await _showProgress(
            100,
            title: 'Contenido actualizado',
            detail: 'Aplicando cambios…',
          );
          await Future.delayed(const Duration(milliseconds: 1400));
          await _restartApp();
        }
      } catch (e) {
        await _showProgress(
          0,
          title: 'No se pudo actualizar',
          detail: 'La aplicación seguirá funcionando',
        );
        await _setStatus(
          deviceId,
          leaseId,
          'error',
          error: e.toString(),
        );
        await Future.delayed(const Duration(seconds: 3));
        await _hideProgress();
      }
    } catch (_) {
      // Si GCenter no responde, la audioguía sigue funcionando.
    } finally {
      _running = false;
    }
  }

  Future<bool> _runContentUpdate(int parallel) async {
    await _showProgress(
      0,
      title: 'Actualizando contenido',
      detail: 'Preparando actualización…',
    );

    var lastPercent = -1;

    final result = await _contentSync.syncNow(
      maxParallelDownloads: parallel,
      onFileStatusChanged: (filename, status, progress) {
        final percent = (progress * 100).round().clamp(0, 99);

        // Evitamos enviar cientos de actualizaciones iguales al canal nativo.
        if (percent == lastPercent && status != FileSyncStatus.error) {
          return;
        }
        lastPercent = percent;

        String detail;
        switch (status) {
          case FileSyncStatus.downloading:
            detail = percent <= 0
                ? 'Descargando contenido…'
                : 'Descargando contenido · $percent %';
            break;
          case FileSyncStatus.ok:
            detail = 'Verificando archivos · $percent %';
            break;
          case FileSyncStatus.error:
            detail = 'Error al descargar un archivo';
            break;
          default:
            detail = 'Comprobando contenido…';
        }

        _showProgress(
          percent,
          title: 'Actualizando contenido',
          detail: detail,
        );
      },
    );

    if (!result.complete) {
      throw Exception(
        'Sincronización incompleta: '
        '${result.missingTotal} pendientes, '
        '${result.filesFailed} fallidos',
      );
    }

    final changed = result.filesDownloaded > 0 ||
        result.cleanupDone > 0 ||
        result.manifestChanged;

    if (!changed) {
      await _showProgress(
        100,
        title: 'Contenido actualizado',
        detail: 'No hay cambios pendientes',
      );
      await Future.delayed(const Duration(milliseconds: 900));
      await _hideProgress();
    }

    return changed;
  }

  Future<void> _showProgress(
    int percent, {
    required String title,
    required String detail,
  }) async {
    try {
      await _appChannel.invokeMethod<void>(
        'showSyncProgress',
        {
          'percent': percent.clamp(0, 100),
          'title': title,
          'detail': detail,
        },
      );
    } catch (_) {
      // La actualización de contenido no depende de que el overlay esté disponible.
    }
  }

  Future<void> _hideProgress() async {
    try {
      await _appChannel.invokeMethod<void>('hideSyncProgress');
    } catch (_) {}
  }

  Future<void> _restartApp() async {
    try {
      await _appChannel.invokeMethod<void>('restartApp');
    } catch (_) {
      await _hideProgress();
      // El contenido ya quedó instalado aunque el reinicio no esté disponible.
    }
  }

  Future<void> _setStatus(
    String deviceId,
    int leaseId,
    String state, {
    String? error,
  }) async {
    try {
      await http
          .post(
            Uri.parse('$baseUrl/api/device/$deviceId/command-status'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'lease_id': leaseId,
              'state': state,
              'error': error,
            }),
          )
          .timeout(const Duration(seconds: 8));
    } catch (_) {}
  }
}
