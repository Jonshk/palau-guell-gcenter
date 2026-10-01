import '/config.dart';

class AudioPlayerController {
  final AppFile appFile;
  final bool autoplay;
  final bool earpieceEnabled;
  final AudioPlayer player = audio.handler.player;
  EventEmitter<bool> onLoaded = EventEmitter<bool>();
  EventEmitter<double> onSpeedChanged = EventEmitter<double>();
  StreamSubscription<bool>? _onHeadsetConnected;

  AudioPlayerController({required this.appFile, this.autoplay = false, this.earpieceEnabled = false});

  static bool _isShuttingDown = false;

  static Future<void> shutdownPrevious() async {
    if (_isShuttingDown) return;
    _isShuttingDown = true;

    try {
      await audio.handler.stop();
      await audio.handler.player.setSpeed(1.0);
      await audio.handler.player.seek(Duration.zero);
    } catch (_) {}

    _isShuttingDown = false;
  }

  Future<void> initialize() async {
    await AudioPlayerController.shutdownPrevious();

    audio.sensor.enabled = earpieceEnabled;
    audio.session.configureAudioSession(earpieceEnabled: earpieceEnabled);
    if (earpieceEnabled) {
      _onHeadsetConnected = audio.headset.onHeadsetConnected.listen((connected) {
        audio.sensor.enabled = (!connected);
      });
    }
    await _loadSource();
  }

  void dispose() {
    onSpeedChanged.dispose();
    _onHeadsetConnected?.cancel();
    _onHeadsetConnected = null;
    onLoaded.dispose();
  }

  Future<void> _loadSource() async {
    try {
      MediaItem? mediaItem;
      if (audio.useBackgroundAudio) {
        mediaItem = MediaItem(
          id: appFile.uuid,
          title: services.contents.current.getTemplate().basicInformation?.title.translateRichText() ?? "",
          album: (Get.context?.findAncestorWidgetOfExactType<GetMaterialApp>())?.title,
          artUri: (Platform.isIOS) ? await _getImageFileFromAssets() : null,
        );
      }
      await audio.handler.setAudioSource(
        services.downloader.contentsDownloaded,
        AudioExtensionFile(
          uuid: appFile.uuid,
          url: appFile.url,
          file: appFile.file,
          mediaItem: mediaItem,
          webFile: appFile.webFile?.toJson(),
        ),
      );
      player.setVolume(1);
      onLoaded.emit(true);
      autoPlay();
    } catch (e) {
      Logger.error("Can't load audio $e", "AudioPlayerController", "_loadSource");
      onLoaded.emit(false);
    }
  }

  Future<void> autoPlay() async {
    try {
      await play(false);
      if (!autoplay) {
        await Future.delayed(const Duration(milliseconds: 60));
        await pause(false);
      } else {
        await Future.delayed(const Duration(milliseconds: 500));
        await play(false);
      }
      onLoaded.emit(true);
    } catch (e) {
      Logger.error("Can't play audio $e", "AudioPlayerController", "autoPlay");
      onLoaded.emit(false);
    }

    if (kIsWeb) return;

    bool hasHeadset = await audio.headset.isHeadsetConnected();

    if ((!hasHeadset && !audio.modal.getNotShowAgain(AudioModalType.headset)) && earpieceEnabled) {
      await audio.modal.show(AudioModalType.headset);
      await Future.delayed(const Duration(milliseconds: 60));
      await pause(false);
      return;
    }
  }

  Future<void> handlePlayPause(bool fromUser) async {
    try {
      if (audio.handler.player.playing) {
        await pause(fromUser);
      } else {
        await play(fromUser);
      }
    } catch (e) {
      Logger.error("Can't handlePlayPause $e", "AudioPlayerController", "handlePlayPause");
    }
  }

  Future<void> play(bool fromUser) async {
    audio.handler.play();
    if (fromUser) _addTracking(TrackingAction.play);
  }

  Future<void> pause(bool fromUser) async {
    audio.handler.pause();
    if (fromUser) _addTracking(TrackingAction.pause);
  }

  Future<void> stop() async {
    audio.handler.stop();
    _addTracking(TrackingAction.stop);
  }

  Future<void> changePlaybackRate() async {
    double currentSpeed = audio.handler.player.speed;
    if (currentSpeed < 2) {
      currentSpeed += 0.5;
    } else {
      currentSpeed = 1.0;
    }
    onSpeedChanged.emit(currentSpeed);
    await audio.handler.player.setSpeed(currentSpeed);
  }

  Future<void> seekTo(double sliderValue) async {
    final newPosition = Duration(milliseconds: sliderValue.toInt());
    audio.handler.seek(newPosition);
  }

  void _addTracking(String action) {
    services.tracking.creator.playerMedia(appFile.uuid, action);
  }

  String formatDuration(Duration duration) {
    if (duration == Duration.zero) return "00:00";
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  Future<Uri> _getImageFileFromAssets() async {
    final byteData = await rootBundle.load('assets/img/icon.png');
    final buffer = byteData.buffer;
    Directory tempDir = await getApplicationDocumentsDirectory();
    String filePath = "${tempDir.path}/icon.png";
    return (await File(filePath).writeAsBytes(buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes))).uri;
  }
}

Future<void> cancelAudio() async {
  await AudioPlayerController.shutdownPrevious();
}
