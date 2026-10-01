import '/config.dart';

import 'apk_update_service.dart';
import 'content_sync_service.dart';
import 'gcenter_runtime.dart';

typedef GCenterProgressCallback = void Function(
  String status,
  double progress,
);

class GCenterSettingsBridge {
  static const String tag = 'gcenter_bridge';

  static final ContentSyncService _content =
      ContentSyncService();

  static final ApkUpdateService _apk =
      ApkUpdateService();

  static void register() {
    if (Get.isRegistered<Map<String, dynamic>>(
      tag: tag,
    )) {
      return;
    }

    Get.put<Map<String, dynamic>>(
      {
        'checkUpdates': () async {
          return _checkUpdates();
        },

        'updateContent':
            (GCenterProgressCallback cb) async {
          await _updateContent(cb);
        },

        'updateApk':
            (GCenterProgressCallback cb) async {
          await _updateApk(cb);
        },

        'updateAll':
            (GCenterProgressCallback cb) async {
          await _updateAll(cb);
        },
      },
      tag: tag,
      permanent: true,
    );
  }

  static Future<Map<String, dynamic>>
      _checkUpdates() async {
    final manifest =
        await _content.fetchRemoteManifest();

    final remotePublication =
        _extractPublicationId(manifest);

    if (remotePublication == null ||
        remotePublication.trim().isEmpty) {
      throw Exception(
        'El servidor no informó '
        'el Publication ID.',
      );
    }

    final localPublication =
        GCenterRuntime.publicationId;

    final contentUpdate =
        localPublication == null ||
            localPublication.trim().isEmpty ||
            localPublication.trim() !=
                remotePublication.trim();

    final apk =
        await _apk.checkForUpdate();

    return {
      'contentUpdate': contentUpdate,
      'apkUpdate': apk.updateAvailable,
      'localPublication':
          localPublication,
      'remotePublication':
          remotePublication,
      'remoteApkVersion':
          apk.version,
      'remoteApkBuild':
          apk.build,
    };
  }

  static String? _extractPublicationId(
    dynamic manifest,
  ) {
    if (manifest is! Map) {
      return null;
    }

    const possibleKeys = [
      'publication_released_uuid',
      'publicationReleaseId',
      'publication_release_id',
      'publicationId',
      'publication_id',
      'uuid',
    ];

    for (final key in possibleKeys) {
      final value = manifest[key];

      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    for (final value in manifest.values) {
      if (value is Map) {
        final found =
            _extractPublicationId(value);

        if (found != null) {
          return found;
        }
      }
    }

    return null;
  }

  static Future<void> _updateContent(
    GCenterProgressCallback cb,
  ) async {
    cb(
      'Comprobando contenido…',
      0,
    );

    final result =
        await _content.syncNow(
      maxParallelDownloads: 4,
      onFileStatusChanged: (
        filename,
        status,
        progress,
      ) {
        cb(
          status == FileSyncStatus.error
              ? 'Error: $filename'
              : 'Actualizando contenido · '
                  '${(progress * 100).round()} %',
          progress,
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

    cb(
      'Contenido actualizado. Reiniciando…',
      1,
    );

    await Future.delayed(
      const Duration(milliseconds: 900),
    );

    await TerminateRestart.instance.restartApp(
      options:
          const TerminateRestartOptions(
        terminate: true,
      ),
    );
  }

  static Future<void> _updateApk(
    GCenterProgressCallback cb,
  ) async {
    cb(
      'Comprobando APK…',
      0.15,
    );

    final result =
        await _apk.updateIfAvailable();

    cb(
      !result.updateAvailable
          ? 'La APK ya está actualizada'
          : result.installerOpened
              ? 'APK descargada. '
                  'Abriendo instalador…'
              : 'APK descargada',
      1,
    );
  }

  static Future<void> _updateAll(
    GCenterProgressCallback cb,
  ) async {
    cb(
      'Actualizando contenido…',
      0,
    );

    final result =
        await _content.syncNow(
      maxParallelDownloads: 4,
      onFileStatusChanged: (
        filename,
        status,
        progress,
      ) {
        cb(
          status == FileSyncStatus.error
              ? 'Error: $filename'
              : 'Contenido · '
                  '${(progress * 100).round()} %',
          (progress * 0.75).clamp(
            0.0,
            0.75,
          ),
        );
      },
    );

    if (!result.complete) {
      throw Exception(
        'Contenido incompleto',
      );
    }

    cb(
      'Comprobando APK…',
      0.85,
    );

    final apk =
        await _apk.updateIfAvailable();

    if (apk.installerOpened) {
      cb(
        'Contenido listo. '
        'Abriendo instalador APK…',
        1,
      );

      return;
    }

    cb(
      'Actualización completa. '
      'Reiniciando…',
      1,
    );

    await Future.delayed(
      const Duration(milliseconds: 900),
    );

    await TerminateRestart.instance.restartApp(
      options:
          const TerminateRestartOptions(
        terminate: true,
      ),
    );
  }
}