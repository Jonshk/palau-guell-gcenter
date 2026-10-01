import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'device_report_service.dart';
import 'gcenter_runtime.dart';
import 'sync_models.dart';

export 'sync_models.dart';

typedef FileStatusChangedCallback = void Function(
  String filename,
  FileSyncStatus status,
  double progress,
);

class ContentSyncService {
  static const String baseUrl = 'http://192.168.1.96:8080';
  static const String manifestFileName = 'publication-released';
  static const String localIndexName = '.gcenter-index.json';

  static const Set<String> _managedFolders = {
    'audio',
    'image',
    'video',
    'file',
  };

  final DeviceReportService _reporter = DeviceReportService();

  Future<String> getBundleId() => _bundleId();

  Future<Directory> getExternalFilesDir() => _storageRoot();

  Future<dynamic> fetchRemoteManifest() => _downloadManifest();

  // ---------------------------------------------------------------------------
  // Compatibilidad con audioguide_home_screen.dart
  // ---------------------------------------------------------------------------

  List<ContentFileEntry> extractFileEntries(dynamic manifest) {
    final unique = <String, ContentFileEntry>{};

    void walk(dynamic node) {
      if (node is Map) {
        final filename = node['filename'];
        final mimetype = node['mimetype'];

        if (filename is String &&
            filename.trim().isNotEmpty &&
            mimetype is String &&
            mimetype.trim().isNotEmpty) {
          String folder;

          if (mimetype.startsWith('audio/')) {
            folder = 'audio';
          } else if (mimetype.startsWith('video/')) {
            folder = 'video';
          } else if (mimetype.startsWith('image/')) {
            folder = 'image';
          } else {
            folder = 'file';
          }

          final rawLabel = node['label'];

          final label =
              rawLabel is String && rawLabel.trim().isNotEmpty
                  ? rawLabel.trim()
                  : null;

          final entry = ContentFileEntry(
            filename: filename,
            folder: folder,
            label: label,
            mimetype: mimetype,
          );

          unique[entry.relativePath] = entry;
        }

        for (final value in node.values) {
          walk(value);
        }
      } else if (node is List) {
        for (final value in node) {
          walk(value);
        }
      }
    }

    walk(manifest);

    final files = unique.values.toList()
      ..sort(
        (a, b) => a.relativePath.compareTo(
          b.relativePath,
        ),
      );

    return files;
  }

  Future<List<FileState>> checkLocalState(
    List<ContentFileEntry> entries,
  ) async {
    final root = await _storageRoot();

    final states = <FileState>[];

    for (final entry in entries) {
      final file = File(
        '${root.path}/${entry.relativePath}',
      );

      final exists = await file.exists();

      states.add(
        FileState(
          entry: entry,
          status: exists
              ? FileSyncStatus.ok
              : FileSyncStatus.missing,
          progress: exists ? 1.0 : 0.0,
        ),
      );
    }

    return states;
  }

  Future<String> _bundleId() async {
    final info = await PackageInfo.fromPlatform();

    return info.packageName;
  }

  Future<Directory> _storageRoot() async {
    final directory = await getExternalStorageDirectory();

    if (directory == null) {
      throw Exception(
        'No se pudo acceder al almacenamiento externo.',
      );
    }

    return directory;
  }

  Future<dynamic> _downloadManifest() async {
    final bundleId = await _bundleId();

    final response = await http
        .get(
          Uri.parse(
            '$baseUrl/$bundleId/$manifestFileName',
          ),
        )
        .timeout(
          const Duration(seconds: 30),
        );

    if (response.statusCode != 200) {
      throw Exception(
        'No se pudo descargar $manifestFileName. '
        'HTTP ${response.statusCode}',
      );
    }

    return jsonDecode(
      utf8.decode(
        response.bodyBytes,
      ),
    );
  }

  Future<List<ContentFileEntry>>
      _downloadContentIndex() async {
    final bundleId = await _bundleId();

    final response = await http
        .get(
          Uri.parse(
            '$baseUrl/api/content-index/$bundleId',
          ),
        )
        .timeout(
          const Duration(minutes: 2),
        );

    final decoded = jsonDecode(
      utf8.decode(
        response.bodyBytes,
      ),
    );

    final data = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{};

    if (response.statusCode != 200) {
      final source = data['source']?.toString();

      final missing =
          (data['missing_on_server_count'] as num?)
                  ?.toInt() ??
              0;

      final listed =
          (data['listed_count'] as num?)
                  ?.toInt() ??
              0;

      throw Exception(
        'Índice de contenido no disponible. '
        'HTTP ${response.statusCode}'
        '${source == null ? '' : ' · fuente: $source'}'
        '${listed > 0 ? ' · listados: $listed' : ''}'
        '${missing > 0 ? ' · faltan en servidor: $missing' : ''}',
      );
    }

    if (data['ready'] == false) {
      throw Exception(
        'La publicación no está lista para sincronizar.',
      );
    }

    final files =
        data['files'] as List? ?? const [];

    final out = <ContentFileEntry>[];

    for (final raw in files) {
      if (raw is! Map) {
        continue;
      }

      final path = (raw['path'] ?? '')
          .toString()
          .replaceAll('\\', '/');

      final slash = path.indexOf('/');

      if (slash <= 0 ||
          slash >= path.length - 1) {
        continue;
      }

      final folder =
          path.substring(0, slash);

      final filename =
          path.substring(slash + 1);

      if (!_managedFolders.contains(folder)) {
        continue;
      }

      out.add(
        ContentFileEntry(
          folder: folder,
          filename: filename,
          size:
              (raw['size'] as num?)?.toInt() ??
                  0,
          sha256:
              raw['sha256']?.toString(),
        ),
      );
    }

    out.sort(
      (a, b) => a.relativePath.compareTo(
        b.relativePath,
      ),
    );

    return out;
  }

  Future<Map<String, dynamic>>
      _loadLocalIndex(
    Directory root,
  ) async {
    final file = File(
      '${root.path}/$localIndexName',
    );

    if (!await file.exists()) {
      return {};
    }

    try {
      final raw = jsonDecode(
        await file.readAsString(),
      );

      return raw is Map<String, dynamic>
          ? raw
          : {};
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveLocalIndex(
    Directory root,
    List<ContentFileEntry> expected,
  ) async {
    final files =
        <String, dynamic>{};

    for (final entry in expected) {
      files[entry.relativePath] = {
        'size': entry.size,
        'sha256': entry.sha256,
      };
    }

    final target = File(
      '${root.path}/$localIndexName',
    );

    final temporary = File(
      '${target.path}.tmp',
    );

    await temporary.writeAsString(
      jsonEncode({
        'saved_at':
            DateTime.now().toIso8601String(),
        'files': files,
      }),
      flush: true,
    );

    if (await target.exists()) {
      await target.delete();
    }

    await temporary.rename(
      target.path,
    );
  }

  Future<bool> _isCurrent(
    Directory root,
    ContentFileEntry entry,
    Map<String, dynamic> localIndex,
  ) async {
    final file = File(
      '${root.path}/${entry.relativePath}',
    );

    if (!await file.exists()) {
      return false;
    }

    if (entry.size > 0 &&
        await file.length() != entry.size) {
      return false;
    }

    final files = localIndex['files'];

    if (files is Map &&
        files[entry.relativePath] is Map) {
      final old =
          files[entry.relativePath] as Map;

      final oldHash =
          old['sha256']?.toString();

      if (entry.sha256 != null &&
          oldHash != null &&
          entry.sha256 != oldHash) {
        return false;
      }
    }

    return true;
  }

  Future<List<ContentFileEntry>>
      _findPending(
    Directory root,
    List<ContentFileEntry> expected,
    Map<String, dynamic> localIndex,
  ) async {
    final out =
        <ContentFileEntry>[];

    for (final entry in expected) {
      if (!await _isCurrent(
        root,
        entry,
        localIndex,
      )) {
        out.add(entry);
      }
    }

    return out;
  }

  Future<List<ContentFileEntry>>
      _findPhysicallyInvalid(
    Directory root,
    List<ContentFileEntry> expected,
  ) async {
    final out =
        <ContentFileEntry>[];

    for (final entry in expected) {
      final file = File(
        '${root.path}/${entry.relativePath}',
      );

      if (!await file.exists()) {
        out.add(entry);
        continue;
      }

      if (entry.size > 0 &&
          await file.length() != entry.size) {
        out.add(entry);
      }
    }

    return out;
  }

  Future<List<File>> _findOrphans(
    Directory root,
    List<ContentFileEntry> expected,
  ) async {
    final valid = expected
        .map(
          (e) => e.relativePath,
        )
        .toSet();

    final out = <File>[];

    for (final folder
        in _managedFolders) {
      final directory = Directory(
        '${root.path}/$folder',
      );

      if (!await directory.exists()) {
        continue;
      }

      await for (final entity
          in directory.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is! File) {
          continue;
        }

        final relativePath =
            entity.path
                .substring(
                  root.path.length + 1,
                )
                .replaceAll(
                  '\\',
                  '/',
                );

        if (relativePath.endsWith(
              '.download',
            ) ||
            !valid.contains(
              relativePath,
            )) {
          out.add(entity);
        }
      }
    }

    return out;
  }

  Future<int> _downloadResumable(
    http.Client client,
    String bundleId,
    ContentFileEntry entry,
    Directory root,
    void Function(int delta) onBytes,
  ) async {
    final target = File(
      '${root.path}/${entry.relativePath}',
    );

    await target.parent.create(
      recursive: true,
    );

    final temporary = File(
      '${target.path}.download',
    );

    var offset = await temporary.exists()
        ? await temporary.length()
        : 0;

    if (entry.size > 0 &&
        offset > entry.size) {
      await temporary.delete();

      offset = 0;
    }

    final request = http.Request(
      'GET',
      Uri.parse(
        '$baseUrl/$bundleId/${entry.relativePath}',
      ),
    );

    if (offset > 0) {
      request.headers['Range'] =
          'bytes=$offset-';
    }

    final response = await client
        .send(request)
        .timeout(
          const Duration(minutes: 3),
        );

    if (response.statusCode != 200 &&
        response.statusCode != 206) {
      throw Exception(
        'HTTP ${response.statusCode}: '
        '${entry.relativePath}',
      );
    }

    if (offset > 0 &&
        response.statusCode == 200) {
      await temporary.writeAsBytes(
        const [],
        flush: true,
      );

      offset = 0;
    }

    final sink = temporary.openWrite(
      mode: offset > 0
          ? FileMode.append
          : FileMode.write,
    );

    var received = 0;

    try {
      await for (final chunk
          in response.stream) {
        sink.add(chunk);

        received += chunk.length;

        onBytes(
          chunk.length,
        );
      }
    } finally {
      await sink.flush();

      await sink.close();
    }

    final finalLength =
        await temporary.length();

    if (entry.size > 0 &&
        finalLength != entry.size) {
      throw Exception(
        'Tamaño incorrecto '
        '${entry.relativePath}: '
        '$finalLength/${entry.size}',
      );
    }

    if (await target.exists()) {
      await target.delete();
    }

    await temporary.rename(
      target.path,
    );

    return received;
  }

  Future<SyncResult> syncNow({
    FileStatusChangedCallback?
        onFileStatusChanged,
    int maxParallelDownloads = 2,
  }) async {
    final startedAt =
        DateTime.now();

    final bundleId =
        await _bundleId();

    final root =
        await _storageRoot();

    final localIndex =
        await _loadLocalIndex(root);

    await _reporter.sendReport(
      phase: 'checking',
    );

    final expected =
        await _downloadContentIndex();

    final manifest =
        await _downloadManifest();

    final manifestJson =
        jsonEncode(manifest);

    var manifestChanged = true;

    for (final name in const [
      'publication-released.json',
      'publication-released',
    ]) {
      final localManifest = File(
        '${root.path}/$name',
      );

      if (await localManifest.exists()) {
        try {
          manifestChanged =
              await localManifest
                      .readAsString() !=
                  manifestJson;

          break;
        } catch (_) {}
      }
    }

    final pending =
        await _findPending(
      root,
      expected,
      localIndex,
    );

    pending.sort(
      (a, b) => a.size.compareTo(
        b.size,
      ),
    );

    final orphans =
        await _findOrphans(
      root,
      expected,
    );

    final expectedTotal =
        expected.length;

    final updateExpected =
        pending.length;

    final cleanupExpected =
        orphans.length;

    final bytesTotal =
        pending.fold<int>(
      0,
      (sum, entry) =>
          sum +
          math.max(
            0,
            entry.size,
          ),
    );

    var bytesDone = 0;

    for (final entry in pending) {
      final partial = File(
        '${root.path}/${entry.relativePath}.download',
      );

      if (await partial.exists()) {
        bytesDone += math.min(
          entry.size,
          await partial.length(),
        );
      }
    }

    var downloaded = 0;
    var failed = 0;

    var correct =
        expectedTotal -
            updateExpected;

    var lastReport =
        DateTime.fromMillisecondsSinceEpoch(
      0,
    );

    final speedSamples =
        <MapEntry<DateTime, int>>[];

    double speedNow() {
      final cutoff =
          DateTime.now().subtract(
        const Duration(seconds: 30),
      );

      speedSamples.removeWhere(
        (entry) =>
            entry.key.isBefore(cutoff),
      );

      if (speedSamples.length < 2) {
        return 0;
      }

      final deltaTime =
          speedSamples.last.key
                  .difference(
                    speedSamples
                        .first.key,
                  )
                  .inMilliseconds /
              1000.0;

      if (deltaTime <= 0) {
        return 0;
      }

      return (speedSamples.last.value -
              speedSamples.first.value) /
          deltaTime;
    }

    Future<void> report(
      String phase, {
      String? currentFile,
      String? error,
      bool force = false,
    }) async {
      final now =
          DateTime.now();

      if (!force &&
          now
                  .difference(
                    lastReport,
                  )
                  .inMilliseconds <
              1000) {
        return;
      }

      lastReport = now;

      speedSamples.add(
        MapEntry(
          now,
          bytesDone,
        ),
      );

      final speed =
          speedNow();

      final remaining =
          math.max(
        0,
        bytesTotal -
            bytesDone,
      );

      final eta = speed > 1
          ? (remaining / speed).ceil()
          : null;

      await _reporter.sendReport(
        phase: phase,
        expectedTotal:
            expectedTotal,
        correctTotal:
            correct,
        missingTotal:
            math.max(
          0,
          expectedTotal -
              correct,
        ),
        updateExpected:
            updateExpected,
        updateDone:
            downloaded,
        cleanupExpected:
            cleanupExpected,
        cleanupDone:
            0,
        bytesTotal:
            bytesTotal,
        bytesDone:
            math.min(
          bytesDone,
          bytesTotal,
        ),
        speedBps:
            speed,
        etaSeconds:
            eta,
        elapsedSeconds:
            DateTime.now()
                .difference(
                  startedAt,
                )
                .inSeconds,
        currentFile:
            currentFile,
        error:
            error,
      );
    }

    await report(
      updateExpected == 0
          ? 'verifying'
          : 'downloading',
      force: true,
    );

    final client =
        http.Client();

    var cursor = 0;

    final workers =
        math.max(
      1,
      math.min(
        maxParallelDownloads,
        8,
      ),
    );

    Future<void> worker() async {
      while (true) {
        final index =
            cursor++;

        if (index >=
            pending.length) {
          return;
        }

        final entry =
            pending[index];

        onFileStatusChanged?.call(
          entry.filename,
          FileSyncStatus.downloading,
          updateExpected == 0
              ? 0
              : downloaded /
                  updateExpected,
        );

        Object? lastError;

        var success = false;

        for (var attempt = 1;
            attempt <= 3 &&
                !success;
            attempt++) {
          try {
            await _downloadResumable(
              client,
              bundleId,
              entry,
              root,
              (delta) {
                bytesDone += delta;
              },
            );

            downloaded++;

            correct++;

            success = true;

            onFileStatusChanged?.call(
              entry.filename,
              FileSyncStatus.ok,
              updateExpected == 0
                  ? 1
                  : downloaded /
                      updateExpected,
            );

            await report(
              'downloading',
              currentFile:
                  entry.relativePath,
            );
          } catch (error) {
            lastError =
                error;

            if (attempt < 3) {
              await Future.delayed(
                Duration(
                  seconds:
                      attempt * 2,
                ),
              );
            }
          }
        }

        if (!success) {
          failed++;

          onFileStatusChanged?.call(
            entry.filename,
            FileSyncStatus.error,
            updateExpected == 0
                ? 0
                : downloaded /
                    updateExpected,
          );

          await report(
            'error',
            currentFile:
                entry.relativePath,
            error:
                lastError.toString(),
            force: true,
          );
        }
      }
    }

    try {
      await Future.wait(
        List.generate(
          workers,
          (_) => worker(),
        ),
      );
    } finally {
      client.close();
    }

    final missingAfter =
        await _findPhysicallyInvalid(
      root,
      expected,
    );

    final contentReady =
        missingAfter.isEmpty &&
            failed == 0;

    var cleanupDone = 0;

    if (contentReady) {
      await report(
        'cleaning',
        force: true,
      );

      for (final file in orphans) {
        try {
          if (await file.exists()) {
            await file.delete();
          }

          cleanupDone++;
        } catch (_) {}
      }

      await File(
        '${root.path}/publication-released',
      ).writeAsString(
        manifestJson,
        flush: true,
      );

      await File(
        '${root.path}/publication-released.json',
      ).writeAsString(
        manifestJson,
        flush: true,
      );

      await _saveLocalIndex(
        root,
        expected,
      );

      if (manifest is Map) {
        final publicationId =
            manifest[
                    'publication_released_uuid']
                ?.toString();

        if (publicationId != null &&
            publicationId
                .trim()
                .isNotEmpty) {
          GCenterRuntime
              .updatePublication(
            publicationId,
          );
        }
      }
    }

    final finalCorrect =
        contentReady
            ? expectedTotal
            : expectedTotal -
                missingAfter.length;

    await _reporter.sendReport(
      phase:
          contentReady
              ? 'complete'
              : 'error',
      expectedTotal:
          expectedTotal,
      correctTotal:
          finalCorrect,
      missingTotal:
          missingAfter.length,
      updateExpected:
          updateExpected,
      updateDone:
          downloaded,
      cleanupExpected:
          cleanupExpected,
      cleanupDone:
          cleanupDone,
      bytesTotal:
          bytesTotal,
      bytesDone:
          math.min(
        bytesDone,
        bytesTotal,
      ),
      speedBps:
          speedNow(),
      etaSeconds:
          contentReady
              ? 0
              : null,
      elapsedSeconds:
          DateTime.now()
              .difference(
                startedAt,
              )
              .inSeconds,
      error:
          contentReady
              ? null
              : 'Sincronización incompleta',
    );

    return SyncResult(
      filesChecked:
          expectedTotal,
      filesDownloaded:
          downloaded,
      filesFailed:
          failed,
      expectedTotal:
          expectedTotal,
      correctTotal:
          finalCorrect,
      missingTotal:
          missingAfter.length,
      updateExpected:
          updateExpected,
      updateDone:
          downloaded,
      cleanupExpected:
          cleanupExpected,
      cleanupDone:
          cleanupDone,
      manifestChanged:
          manifestChanged,
    );
  }
}