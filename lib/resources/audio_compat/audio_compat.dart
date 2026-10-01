import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_session/audio_session.dart';
import 'package:proximity_sensor/proximity_sensor.dart';

export 'package:just_audio/just_audio.dart';
export 'package:just_audio_background/just_audio_background.dart'
    show MediaItem;

/// ---------------------------------------------------------------
/// REEMPLAZO LOCAL de `audio_extension`.
///
/// Esta implementación mantiene la interfaz que utiliza Palau Güell
/// y añade comprobaciones para evitar enviar a just_audio rutas
/// vacías, archivos inexistentes o URLs inválidas.
/// ---------------------------------------------------------------

enum AudioModalType {
  headset,
  video,
}

/// Representa un recurso de audio.
///
/// Puede venir de:
/// - un archivo local ya descargado;
/// - una URL remota;
/// - webFile, mantenido por compatibilidad con el código existente.
class AudioExtensionFile {
  final String uuid;
  final String? url;
  final dynamic file;
  final MediaItem? mediaItem;
  final dynamic webFile;

  AudioExtensionFile({
    required this.uuid,
    this.url,
    this.file,
    this.mediaItem,
    this.webFile,
  });
}

/// Configuración general de audio.
class AudioExtensionConfiguration {
  final Widget headsetModal;
  final Widget videoModal;

  final bool useSensorAutoplayAudio;
  final bool useBackgroundAudio;
  final bool requestHeadsetPermission;
  final bool showModalsWithFunction;

  final Future<void> Function(
    BuildContext context,
  ) showHeadsetModal;

  AudioExtensionConfiguration({
    required this.headsetModal,
    required this.videoModal,
    this.useSensorAutoplayAudio = false,
    this.useBackgroundAudio = false,
    this.requestHeadsetPermission = false,
    this.showModalsWithFunction = false,
    required this.showHeadsetModal,
  });
}

/// ---------------------------------------------------------------
/// AUDIO HANDLER
/// ---------------------------------------------------------------

class _AudioHandler {
  final AudioPlayer player = AudioPlayer();

  Future<void> setAudioSource(
    bool contentsDownloaded,
    AudioExtensionFile file,
  ) async {
    AudioSource? source;

    debugPrint(
      '[AUDIO] Preparando recurso ${file.uuid}',
    );

    // -------------------------------------------------------------
    // 1. Intentar archivo local.
    // -------------------------------------------------------------

    final dynamic rawFile = file.file;

    if (rawFile != null) {
      try {
        String? rawPath;

        try {
          final dynamic value = rawFile.path;

          if (value != null) {
            rawPath = value.toString();
          }
        } catch (_) {
          rawPath = null;
        }

        final path = rawPath?.trim();

        if (path == null || path.isEmpty) {
          debugPrint(
            '[AUDIO] Archivo local con ruta vacía '
            'para ${file.uuid}.',
          );
        } else {
          final localFile = File(path);

          if (await localFile.exists()) {
            debugPrint(
              '[AUDIO] Usando archivo local: '
              '${localFile.path}',
            );

            source = AudioSource.uri(
              Uri.file(
                localFile.path,
              ),
              tag: file.mediaItem,
            );
          } else {
            debugPrint(
              '[AUDIO] El archivo local no existe: '
              '${localFile.path}',
            );
          }
        }
      } catch (error, stackTrace) {
        debugPrint(
          '[AUDIO] Error comprobando archivo local '
          '${file.uuid}: $error',
        );

        debugPrintStack(
          stackTrace: stackTrace,
        );
      }
    }

    // -------------------------------------------------------------
    // 2. Si el archivo local no es válido, probar URL.
    // -------------------------------------------------------------

    if (source == null) {
      final String? rawUrl = file.url;

      final url = rawUrl?.trim();

      if (url != null && url.isNotEmpty) {
        final uri = Uri.tryParse(url);

        if (uri != null &&
            uri.hasScheme &&
            (
              uri.scheme == 'http' ||
              uri.scheme == 'https' ||
              uri.scheme == 'file'
            )) {
          debugPrint(
            '[AUDIO] Usando URL: $url',
          );

          source = AudioSource.uri(
            uri,
            tag: file.mediaItem,
          );
        } else {
          debugPrint(
            '[AUDIO] URL inválida para '
            '${file.uuid}: $url',
          );
        }
      }
    }

    // -------------------------------------------------------------
    // 3. No enviar jamás una ruta vacía a ExoPlayer.
    // -------------------------------------------------------------

    if (source == null) {
      final message =
          'No existe una fuente de audio válida '
          'para ${file.uuid}. '
          'file=${file.file}, '
          'url=${file.url}';

      debugPrint(
        '[AUDIO] $message',
      );

      throw Exception(message);
    }

    // -------------------------------------------------------------
    // 4. Cargar la fuente.
    // -------------------------------------------------------------

    try {
      await player.setAudioSource(
        source,
      );

      debugPrint(
        '[AUDIO] Recurso cargado correctamente: '
        '${file.uuid}',
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[AUDIO] Error cargando ${file.uuid}: '
        '$error',
      );

      debugPrint(
        '[AUDIO] file=${file.file}',
      );

      debugPrint(
        '[AUDIO] url=${file.url}',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  Future<void> play() async {
    try {
      await player.play();
    } catch (error, stackTrace) {
      debugPrint(
        '[AUDIO] Error en play(): $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  Future<void> pause() async {
    try {
      await player.pause();
    } catch (error) {
      debugPrint(
        '[AUDIO] Error en pause(): $error',
      );
    }
  }

  Future<void> stop() async {
    try {
      await player.stop();
    } catch (error) {
      debugPrint(
        '[AUDIO] Error en stop(): $error',
      );
    }
  }

  Future<void> seek(
    Duration position,
  ) async {
    try {
      await player.seek(
        position,
      );
    } catch (error) {
      debugPrint(
        '[AUDIO] Error en seek(): $error',
      );
    }
  }

  Future<void> dispose() async {
    try {
      await player.dispose();
    } catch (error) {
      debugPrint(
        '[AUDIO] Error liberando reproductor: '
        '$error',
      );
    }
  }
}

/// ---------------------------------------------------------------
/// SENSOR DE PROXIMIDAD
/// ---------------------------------------------------------------

class _AudioSensor {
  bool enabled = false;

  StreamSubscription<int>? _subscription;

  void _ensureListening() {
    if (_subscription != null) {
      return;
    }

    try {
      _subscription =
          ProximitySensor.events.listen(
        (event) {
          if (!enabled) {
            return;
          }

          final near =
              event > 0;

          // Conservamos el comportamiento utilizado hasta ahora.
          // Queda preparado para modificar posteriormente volumen,
          // salida auricular, etc.
          audio.handler.player.setVolume(
            near ? 1.0 : 1.0,
          );
        },
        onError: (Object error) {
          debugPrint(
            '[AUDIO] Error sensor proximidad: '
            '$error',
          );
        },
      );
    } catch (error) {
      debugPrint(
        '[AUDIO] No se pudo iniciar '
        'el sensor de proximidad: $error',
      );
    }
  }

  Future<void> dispose() async {
    try {
      await _subscription?.cancel();
    } catch (error) {
      debugPrint(
        '[AUDIO] Error cerrando sensor: $error',
      );
    }

    _subscription = null;
  }
}

/// ---------------------------------------------------------------
/// AUDIO SESSION
/// ---------------------------------------------------------------

class _AudioSession {
  Future<void> configureAudioSession({
    required bool earpieceEnabled,
  }) async {
    try {
      final session =
          await AudioSession.instance;

      await session.configure(
        AudioSessionConfiguration(
          avAudioSessionCategory:
              AVAudioSessionCategory.playback,
          avAudioSessionCategoryOptions:
              earpieceEnabled
                  ? AVAudioSessionCategoryOptions
                      .allowBluetooth
                  : const AVAudioSessionCategoryOptions(
                      0,
                    ),
          avAudioSessionMode:
              AVAudioSessionMode.defaultMode,
          androidAudioAttributes:
              const AndroidAudioAttributes(
            contentType:
                AndroidAudioContentType.speech,
            usage:
                AndroidAudioUsage.media,
          ),
          androidAudioFocusGainType:
              AndroidAudioFocusGainType.gain,
        ),
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[AUDIO] Error configurando '
        'AudioSession: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }
}

/// ---------------------------------------------------------------
/// DETECCIÓN DE AURICULARES
/// ---------------------------------------------------------------

class _AudioHeadset {
  final StreamController<bool>
      _controller =
      StreamController<bool>.broadcast();

  Stream<bool> get onHeadsetConnected =>
      _controller.stream;

  StreamSubscription<dynamic>?
      _devicesSubscription;

  Future<void> init() async {
    if (_devicesSubscription != null) {
      return;
    }

    try {
      final session =
          await AudioSession.instance;

      _devicesSubscription =
          session.devicesChangedEventStream.listen(
        (_) async {
          try {
            final connected =
                await isHeadsetConnected();

            if (!_controller.isClosed) {
              _controller.add(
                connected,
              );
            }
          } catch (error) {
            debugPrint(
              '[AUDIO] Error comprobando '
              'auriculares: $error',
            );
          }
        },
        onError: (Object error) {
          debugPrint(
            '[AUDIO] Error en devicesChanged: '
            '$error',
          );
        },
      );
    } catch (error) {
      debugPrint(
        '[AUDIO] No se pudo inicializar '
        'detección de auriculares: $error',
      );
    }
  }

  Future<bool> isHeadsetConnected() async {
    try {
      final session =
          await AudioSession.instance;

      final devices =
          await session.getDevices();

      return devices.any(
        (device) =>
            device.type ==
                AudioDeviceType.bluetoothA2dp ||
            device.type ==
                AudioDeviceType.bluetoothSco ||
            device.type ==
                AudioDeviceType.wiredHeadset ||
            device.type ==
                AudioDeviceType.wiredHeadphones,
      );
    } catch (error) {
      debugPrint(
        '[AUDIO] Error obteniendo '
        'dispositivos de audio: $error',
      );

      return false;
    }
  }

  Future<void> dispose() async {
    try {
      await _devicesSubscription?.cancel();
    } catch (_) {}

    _devicesSubscription = null;

    if (!_controller.isClosed) {
      await _controller.close();
    }
  }
}

/// ---------------------------------------------------------------
/// MODALES
/// ---------------------------------------------------------------

class _AudioModal {
  final Map<AudioModalType, bool>
      _notShowAgain = {};

  Future<void> Function(
    BuildContext context,
  )? _showHeadsetModalFn;

  void setNotShowAgain(
    AudioModalType type,
    bool value,
  ) {
    _notShowAgain[type] =
        value;
  }

  bool getNotShowAgain(
    AudioModalType type,
  ) {
    return _notShowAgain[type] ??
        false;
  }

  Future<void> show(
    AudioModalType type,
  ) async {
    if (getNotShowAgain(type)) {
      return;
    }

    final context =
        audio.navigatorKey
            ?.currentContext;

    if (context == null) {
      debugPrint(
        '[AUDIO] No hay contexto disponible '
        'para mostrar modal.',
      );

      return;
    }

    final showFunction =
        _showHeadsetModalFn;

    if (showFunction == null) {
      return;
    }

    try {
      await showFunction(
        context,
      );
    } catch (error) {
      debugPrint(
        '[AUDIO] Error mostrando modal: $error',
      );
    }
  }

  void close() {
    final context =
        audio.navigatorKey
            ?.currentContext;

    if (context == null) {
      return;
    }

    try {
      Navigator.of(
        context,
      ).maybePop();
    } catch (error) {
      debugPrint(
        '[AUDIO] Error cerrando modal: $error',
      );
    }
  }
}

/// ---------------------------------------------------------------
/// AUDIO EXTENSION
/// ---------------------------------------------------------------

class _AudioExtension {
  final _AudioHandler handler =
      _AudioHandler();

  final _AudioSensor sensor =
      _AudioSensor();

  final _AudioSession session =
      _AudioSession();

  final _AudioHeadset headset =
      _AudioHeadset();

  final _AudioModal modal =
      _AudioModal();

  bool useBackgroundAudio =
      false;

  GlobalKey<NavigatorState>?
      navigatorKey;

  bool _initialized = false;

  void setNavigatorKey(
    GlobalKey<NavigatorState> key,
  ) {
    navigatorKey = key;
  }

  Future<void> setStorage(
    dynamic storage, {
    bool initModalCtrl = false,
  }) async {
    // El paquete privado original persistía probablemente aquí
    // preferencias como "no volver a mostrar".
    //
    // Esta implementación mantiene la firma para compatibilidad,
    // pero actualmente no modifica el storage recibido.
  }

  Future<void> initialize(
    AudioExtensionConfiguration config,
  ) async {
    useBackgroundAudio =
        config.useBackgroundAudio;

    modal._showHeadsetModalFn =
        config.showHeadsetModal;

    sensor._ensureListening();

    await headset.init();

    if (config.useBackgroundAudio &&
        !_initialized) {
      try {
        await JustAudioBackground.init(
          androidNotificationChannelId:
              'com.gvam.audioguide.channel',
          androidNotificationChannelName:
              'Reproducción de audioguía',
          androidNotificationOngoing:
              true,
        );
      } catch (error, stackTrace) {
        debugPrint(
          '[AUDIO] Error inicializando '
          'JustAudioBackground: $error',
        );

        debugPrintStack(
          stackTrace: stackTrace,
        );

        rethrow;
      }
    }

    _initialized = true;
  }

  Future<void> dispose() async {
    await sensor.dispose();
    await headset.dispose();
    await handler.dispose();

    _initialized = false;
  }
}

final _AudioExtension audio =
    _AudioExtension();