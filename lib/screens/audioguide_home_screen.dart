import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../gvam_content_sync/content_sync_service.dart';

/// Audioguía propia, mínima, que NO usa ventour_connector — lee
/// directamente el publication-released real y reproduce el contenido
/// real descargado. Sirve para demostrar el mecanismo de sincronización
/// con una experiencia parecida a la app final, sin depender de
/// Bitbucket ni de ningún paquete privado de GVAM.
class AudioguideHomeScreen extends StatefulWidget {
  const AudioguideHomeScreen({super.key});

  @override
  State<AudioguideHomeScreen> createState() =>
      _AudioguideHomeScreenState();
}

class _AudioguideHomeScreenState extends State<AudioguideHomeScreen>
    with SingleTickerProviderStateMixin {
  final ContentSyncService _syncService = ContentSyncService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  late TabController _tabController;

  List<FileState> _fileStates = [];
  bool _loading = true;
  String? _error;
  bool _syncing = false;
  String? _lastSyncMessage;
  String _bundleId = '';
  Directory? _externalDir;
  String? _currentlyPlaying;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _refresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final bundleId = await _syncService.getBundleId();
      final dir = await _syncService.getExternalFilesDir();
      final manifest = await _syncService.fetchRemoteManifest();
      final entries = _syncService.extractFileEntries(manifest);
      final states = await _syncService.checkLocalState(entries);

      if (!mounted) return;

      setState(() {
        _fileStates = states;
        _bundleId = bundleId;
        _externalDir = dir;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'No se pudo conectar al servidor de contenido.\n'
            'Verifica la IP en content_sync_service.dart, que server.py '
            'esté corriendo, y que exista la carpeta "$_bundleId" en '
            'D:\\CONTENIDOS\\.\n\nDetalle: $e';
        _loading = false;
      });
    }
  }

  /// Botón SOLO para pruebas manuales.
  Future<void> _forceSyncDebug() async {
    if (mounted) {
      setState(() {
        _syncing = true;
        _lastSyncMessage = null;
      });
    }

    try {
      final result = await _syncService.syncNow(
        onFileStatusChanged: (filename, status, progress) {
          if (!mounted) return;

          setState(() {
            final idx = _fileStates.indexWhere(
              (f) => f.entry.filename == filename,
            );

            if (idx != -1) {
              _fileStates[idx].status = status;
              _fileStates[idx].progress = progress;
            }
          });
        },
      );

      if (!mounted) return;

      setState(() {
        _lastSyncMessage = result.toString();
        _syncing = false;
      });

      await _refresh();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _lastSyncMessage = 'Error al sincronizar: $e';
        _syncing = false;
      });
    }
  }

  Future<void> _playAudio(FileState state) async {
    final externalDir = _externalDir;
    if (externalDir == null) return;

    final path =
        '${externalDir.path}/${state.entry.folder}/${state.entry.filename}';

    final file = File(path);

    if (!await file.exists()) return;

    if (_currentlyPlaying == state.entry.filename) {
      await _audioPlayer.stop();

      if (!mounted) return;

      setState(() => _currentlyPlaying = null);
      return;
    }

    try {
      await _audioPlayer.setFilePath(path);
      await _audioPlayer.play();

      if (!mounted) return;

      setState(() {
        _currentlyPlaying = state.entry.filename;
      });

      _audioPlayer.playerStateStream.listen((playerState) {
        if (playerState.processingState == ProcessingState.completed) {
          if (mounted) {
            setState(() => _currentlyPlaying = null);
          }
        }
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo reproducir: $e'),
        ),
      );
    }
  }

  List<FileState> _byFolder(String folder) {
    return _fileStates
        .where((f) => f.entry.folder == folder)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Audioguía PoC'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              _error!,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _refresh,
          child: const Icon(Icons.refresh),
        ),
      );
    }

    final audios = _byFolder('audio');
    final images = _byFolder('image');
    final videos = _byFolder('video');

    return Scaffold(
      appBar: AppBar(
        title: Text(_bundleId),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'Audios (${audios.length})',
              icon: const Icon(Icons.audiotrack),
            ),
            Tab(
              text: 'Imágenes (${images.length})',
              icon: const Icon(Icons.image),
            ),
            Tab(
              text: 'Videos (${videos.length})',
              icon: const Icon(Icons.videocam),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_lastSyncMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              color: Colors.amber.shade50,
              child: Text(
                _lastSyncMessage!,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _AudioList(
                  audios: audios,
                  currentlyPlaying: _currentlyPlaying,
                  onTap: _playAudio,
                ),
                _ImageGrid(
                  images: images,
                  externalDir: _externalDir,
                ),
                _VideoList(videos: videos),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _syncing ? null : _forceSyncDebug,
        label: Text(
          _syncing
              ? 'Sincronizando...'
              : 'Forzar sync (solo debug)',
        ),
        icon: _syncing
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.sync),
      ),
    );
  }
}

class _AudioList extends StatelessWidget {
  final List<FileState> audios;
  final String? currentlyPlaying;
  final void Function(FileState) onTap;

  const _AudioList({
    required this.audios,
    required this.currentlyPlaying,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (audios.isEmpty) {
      return const Center(
        child: Text('No hay audios en el manifest.'),
      );
    }

    return ListView.builder(
      itemCount: audios.length,
      itemBuilder: (context, index) {
        final state = audios[index];
        final downloaded =
            state.status == FileSyncStatus.ok;
        final playing =
            currentlyPlaying == state.entry.filename;

        return ListTile(
          leading: Icon(
            playing
                ? Icons.pause_circle_filled
                : Icons.play_circle_fill,
            color: downloaded
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
            size: 36,
          ),
          title: Text(
            state.entry.label ?? state.entry.filename,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            downloaded
                ? 'Descargado'
                : 'Pendiente de sincronizar',
            style: TextStyle(
              color:
                  downloaded ? Colors.green : Colors.red,
            ),
          ),
          onTap: downloaded
              ? () => onTap(state)
              : null,
        );
      },
    );
  }
}

class _ImageGrid extends StatelessWidget {
  final List<FileState> images;
  final Directory? externalDir;

  const _ImageGrid({
    required this.images,
    required this.externalDir,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const Center(
        child: Text('No hay imágenes en el manifest.'),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final state = images[index];
        final downloaded =
            state.status == FileSyncStatus.ok;

        final dir = externalDir;

        if (!downloaded || dir == null) {
          return Container(
            color: Colors.grey.shade300,
            child: const Icon(
              Icons.hourglass_empty,
              color: Colors.grey,
            ),
          );
        }

        final path =
            '${dir.path}/${state.entry.folder}/${state.entry.filename}';

        return Image.file(
          File(path),
          fit: BoxFit.cover,
        );
      },
    );
  }
}

class _VideoList extends StatelessWidget {
  final List<FileState> videos;

  const _VideoList({
    required this.videos,
  });

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) {
      return const Center(
        child: Text('No hay videos en el manifest.'),
      );
    }

    return ListView.builder(
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final state = videos[index];
        final downloaded =
            state.status == FileSyncStatus.ok;

        return ListTile(
          leading: Icon(
            Icons.videocam,
            color:
                downloaded ? Colors.green : Colors.grey,
          ),
          title: Text(
            state.entry.label ?? state.entry.filename,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            downloaded
                ? 'Descargado'
                : 'Pendiente de sincronizar',
            style: TextStyle(
              color:
                  downloaded ? Colors.green : Colors.red,
            ),
          ),
        );
      },
    );
  }
}
