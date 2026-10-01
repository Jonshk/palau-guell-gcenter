import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class ApkUpdateResult {
  final bool updateAvailable;
  final bool installerOpened;
  final String? version;
  final int? build;

  const ApkUpdateResult({
    required this.updateAvailable,
    required this.installerOpened,
    this.version,
    this.build,
  });
}

class ApkUpdateService {
  static const String baseUrl = 'http://192.168.1.96:8080';

  static const MethodChannel _channel =
      MethodChannel('gcenter/app');

  /// Solo comprueba.
  /// NO descarga ni abre el instalador.
  Future<ApkUpdateResult> checkForUpdate() async {
    final info = await PackageInfo.fromPlatform();
    final bundleId = info.packageName;

    final response = await http
        .get(
          Uri.parse(
            '$baseUrl/api/apk/latest/$bundleId',
          ),
        )
        .timeout(
          const Duration(seconds: 15),
        );

    if (response.statusCode != 200) {
      throw Exception(
        'No se pudo consultar la APK. '
        'HTTP ${response.statusCode}',
      );
    }

    final data = jsonDecode(
      utf8.decode(response.bodyBytes),
    ) as Map<String, dynamic>;

    if (data['available'] != true) {
      return const ApkUpdateResult(
        updateAvailable: false,
        installerOpened: false,
      );
    }

    final remoteVersion =
        data['version']?.toString();

    final remoteBuild =
        (data['build'] as num?)?.toInt() ?? 0;

    final localBuild =
        int.tryParse(info.buildNumber) ?? 0;

    final updateAvailable =
        remoteBuild > localBuild ||
            (remoteVersion != null &&
                remoteVersion != info.version);

    return ApkUpdateResult(
      updateAvailable: updateAvailable,
      installerOpened: false,
      version: remoteVersion,
      build: remoteBuild,
    );
  }

  Future<ApkUpdateResult>
      updateIfAvailable() async {
    final check = await checkForUpdate();

    if (!check.updateAvailable) {
      return check;
    }

    final info = await PackageInfo.fromPlatform();
    final bundleId = info.packageName;

    final apkResponse = await http
        .get(
          Uri.parse(
            '$baseUrl/api/apk/download/$bundleId',
          ),
        )
        .timeout(
          const Duration(minutes: 5),
        );

    if (apkResponse.statusCode != 200) {
      throw Exception(
        'No se pudo descargar la APK. '
        'HTTP ${apkResponse.statusCode}',
      );
    }

    final root =
        await getExternalStorageDirectory();

    if (root == null) {
      throw Exception(
        'No se pudo acceder al almacenamiento '
        'para guardar la APK.',
      );
    }

    final dir = Directory(
      '${root.path}/gcenter_apk',
    );

    await dir.create(
      recursive: true,
    );

    final apk = File(
      '${dir.path}/gcenter-update.apk',
    );

    await apk.writeAsBytes(
      apkResponse.bodyBytes,
      flush: true,
    );

    await _channel.invokeMethod<void>(
      'installApk',
      {
        'path': apk.path,
      },
    );

    return ApkUpdateResult(
      updateAvailable: true,
      installerOpened: true,
      version: check.version,
      build: check.build,
    );
  }
}