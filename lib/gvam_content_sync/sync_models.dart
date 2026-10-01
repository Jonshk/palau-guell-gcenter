enum FileSyncStatus { ok, missing, downloading, error }

class ContentFileEntry {
  final String filename;
  final String folder;
  final String? label;
  final String? mimetype;
  final int size;
  final String? sha256;

  const ContentFileEntry({
    required this.filename,
    required this.folder,
    this.label,
    this.mimetype,
    this.size = 0,
    this.sha256,
  });

  String get relativePath => '$folder/$filename';
}

class FileState {
  final ContentFileEntry entry;
  FileSyncStatus status;
  double progress;

  FileState({required this.entry, required this.status, this.progress = 0});
}

class SyncResult {
  final int filesChecked;
  final int filesDownloaded;
  final int filesFailed;
  final int expectedTotal;
  final int correctTotal;
  final int missingTotal;
  final int updateExpected;
  final int updateDone;
  final int cleanupExpected;
  final int cleanupDone;
  final bool manifestChanged;

  const SyncResult({
    required this.filesChecked,
    required this.filesDownloaded,
    required this.filesFailed,
    this.expectedTotal = 0,
    this.correctTotal = 0,
    this.missingTotal = 0,
    this.updateExpected = 0,
    this.updateDone = 0,
    this.cleanupExpected = 0,
    this.cleanupDone = 0,
    this.manifestChanged = false,
  });

  bool get complete => missingTotal == 0 && filesFailed == 0;

  @override
  String toString() => 'Contenido: $correctTotal/$expectedTotal · '
      'Descargados: $filesDownloaded · Fallidos: $filesFailed · '
      'Limpieza: $cleanupDone/$cleanupExpected · Manifest cambiado: $manifestChanged';
}
