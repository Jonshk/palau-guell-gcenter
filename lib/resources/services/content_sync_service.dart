import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ContentSyncService {
  static const String baseUrl = 'http://192.168.1.96:8080';
  static const String manifestFileName = 'publication-released';

  Future<Directory> getExternalFilesDir() async {
    final dir = await getExternalStorageDirectory();
    if (dir == null) {
      throw Exception('No se pudo acceder al almacenamiento externo.');
    }
    return dir;
  }

  Future<String> getBundleId() async {
    final info = await PackageInfo.fromPlatform();
    return info.packageName;
  }

  Future<dynamic> fetchRemoteManifest() async {
    final bundleId = await getBundleId();
    final response = await http
        .get(Uri.parse('$baseUrl/$bundleId/$manifestFileName'))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('No se pudo descargar el manifest (${response.statusCode})');
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  String? extractPlaceName(dynamic manifest) {
    if (manifest is Map) {
      final place = manifest['customer_place'];
      if (place is Map) {
        final name = place['name'];
        if (name is String && name.isNotEmpty) return name;
      }
    }
    return null;
  }

  List<FileEntry> extractFileEntries(dynamic node) {
    final List<FileEntry> result = [];

    void walk(dynamic n, String? currentLabel) {
      if (n is Map) {
        String? label = currentLabel;
        final description = n['description'];
        if (description is String && description.isNotEmpty) label = description;
        final langCode = n['language_iso_code'];
        if (langCode is String && langCode.isNotEmpty) {
          label = label != null ? '$label ($langCode)' : langCode;
        }

        final filename = n['filename'];
        final mimetype = n['mimetype'];
        if (filename is String && mimetype is String) {
          result.add(FileEntry(
            filename: filename,
            folder: _folderForMimetype(mimetype),
            label: label,
          ));
        }
        for (final value in n.values) {
          walk(value, label);
        }
      } else if (n is List) {
        for (final item in n) {
          walk(item, currentLabel);
        }
      }
    }

    walk(node, null);
    return result;
  }

  List<TourInfo> extractTours(dynamic manifest) {
    if (manifest is! Map) return [];
    final place = manifest['customer_place'];
    if (place is! Map) return [];
    final tours = place['tours'];
    if (tours is! List) return [];

    final List<TourInfo> result = [];
    for (final t in tours) {
      if (t is! Map) continue;
      final position = t['position'];
      final minutes = t['minutes_duration'];
      final totalContents = t['total_contents'];
      final uuid = t['uuid'];

      FileEntry? thumbnail;
      String? title;
      final card = t['card'];
      if (card is Map) {
        final defaultImage = card['default_image'];
        if (defaultImage is Map) {
          final languages = defaultImage['languages'];
          if (languages is Map && languages.isNotEmpty) {
            final lang = (languages['es-ES'] ?? languages.values.first);
            if (lang is Map) {
              final props = lang['props'];
              if (props is Map) {
                final defaultProps = props['default'];
                if (defaultProps is Map) {
                  final filename = defaultProps['filename'];
                  final mimetype = defaultProps['mimetype'];
                  if (filename is String && mimetype is String) {
                    thumbnail = FileEntry(filename: filename, folder: _folderForMimetype(mimetype));
                  }
                }
              }
            }
          }
        }
        final titleField = card['title'];
        if (titleField is Map) {
          final titleLanguages = titleField['languages'];
          if (titleLanguages is Map && titleLanguages.isNotEmpty) {
            final lang = (titleLanguages['es-ES'] ?? titleLanguages.values.first);
            if (lang is Map) {
              final props = lang['props'];
              if (props is Map) {
                final content = props['content'];
                if (content is String && content.isNotEmpty) title = content;
              }
            }
          }
        }
      }

      result.add(TourInfo(
        uuid: uuid is String ? uuid : '',
        position: position is int ? position : 0,
        minutesDuration: minutes is int ? minutes : 0,
        totalContents: totalContents is int ? totalContents : 0,
        thumbnail: thumbnail,
        title: title,
      ));
    }
    result.sort((a, b) => a.position.compareTo(b.position));
    return result;
  }

  String _folderForMimetype(String mimetype) {
    if (mimetype.startsWith('audio/')) return 'audio';
    if (mimetype.startsWith('video/')) return 'video';
    if (mimetype.startsWith('image/')) return 'image';
    return 'file';
  }

  Future<List<FileState>> checkLocalState(List<FileEntry> entries) async {
    final dir = await getExternalFilesDir();
    final List<FileState> states = [];
    for (final entry in entries) {
      final file = File('${dir.path}/${entry.folder}/${entry.filename}');
      states.add(FileState(
        entry: entry,
        status: await file.exists() ? FileSyncStatus.ok : FileSyncStatus.missing,
      ));
    }
    return states;
  }

  Future<SyncResult> syncNow({
    void Function(String filename, FileSyncStatus status, double progress)? onFileStatusChanged,
  }) async {
    final bundleId = await getBundleId();
    final externalDir = await getExternalFilesDir();

    final remoteManifest = await fetchRemoteManifest();
    final remoteFiles = extractFileEntries(remoteManifest);

    int downloaded = 0;
    int failed = 0;

    for (final entry in remoteFiles) {
      final targetFile = File('${externalDir.path}/${entry.folder}/${entry.filename}');
      if (await targetFile.exists()) continue;

      onFileStatusChanged?.call(entry.filename, FileSyncStatus.downloading, 0.0);
      try {
        await _downloadFile(bundleId, entry, targetFile);
        downloaded++;
        onFileStatusChanged?.call(entry.filename, FileSyncStatus.ok, 1.0);
      } catch (_) {
        failed++;
        onFileStatusChanged?.call(entry.filename, FileSyncStatus.corrupted, 0.0);
      }
    }

    if (failed == 0) {
      final localManifestFile = File('${externalDir.path}/$manifestFileName');
      await localManifestFile.writeAsString(jsonEncode(remoteManifest));
    }

    return SyncResult(
      filesChecked: remoteFiles.length,
      filesDownloaded: downloaded,
      filesFailed: failed,
    );
  }

  Future<void> _downloadFile(String bundleId, FileEntry entry, File targetFile) async {
    final url = '$baseUrl/$bundleId/${entry.folder}/${entry.filename}';
    final response = await http.get(Uri.parse(url)).timeout(const Duration(minutes: 2));
    if (response.statusCode != 200) {
      throw Exception('Fallo al descargar ${entry.filename} (${response.statusCode})');
    }
    await targetFile.parent.create(recursive: true);
    await targetFile.writeAsBytes(response.bodyBytes);
  }
}

class FileEntry {
  final String filename;
  final String folder;
  final String? label;
  FileEntry({required this.filename, required this.folder, this.label});
}

enum FileSyncStatus { ok, missing, corrupted, downloading }

class FileState {
  final FileEntry entry;
  FileSyncStatus status;
  FileState({required this.entry, required this.status});
}

class TourInfo {
  final String uuid;
  final int position;
  final int minutesDuration;
  final int totalContents;
  final FileEntry? thumbnail;
  final String? title;

  TourInfo({
    required this.uuid,
    required this.position,
    required this.minutesDuration,
    required this.totalContents,
    this.thumbnail,
    this.title,
  });
}

class SyncResult {
  final int filesChecked;
  final int filesDownloaded;
  final int filesFailed;

  SyncResult({
    required this.filesChecked,
    required this.filesDownloaded,
    required this.filesFailed,
  });

  @override
  String toString() =>
      '$filesChecked archivos revisados, $filesDownloaded descargados, $filesFailed fallidos.';
}