part of 'video.dart';

class VideoPlayerWidgetController {
  final AppFile appFile;
  final String widgetUuid;
  final bool autoplay;
  late final VideoPlayerController _videoCtrl;
  late AnimationController animationCtrl;
  bool loaded = false;
  Duration totalDuration = Duration.zero;
  Duration currentPosition = Duration.zero;
  VideoPlayerState currentState = VideoPlayerState.stopped;
  EventEmitter<VideoPlayerState> onStateChange = EventEmitter<VideoPlayerState>();
  EventEmitter<bool> onVideoLoaded = EventEmitter<bool>();

  VideoPlayerWidgetController({
    required this.appFile,
    required this.widgetUuid,
    this.autoplay = false,
  });

  Future<void> initialize(void Function() listeners) async {
    if (appFile.uuid.isNotEmpty) {
      _videoCtrl = appFile.getController();
      if (_videoCtrl.dataSource.isNotEmpty) {
        _videoCtrl.addListener(listeners);
        await _videoCtrl.initialize();
        onVideoLoaded.emit(true);
      } else {
        Logger.error("VideoController is NULL", "VideoPlayerWidgetController", "_initializeVideoPlayer");
        onVideoLoaded.emit(false);
      }
    } else {
      _videoCtrl = VideoPlayerController.asset("");
      Future.delayed(const Duration(milliseconds: 1200)).then((value) {
        if (Get.context!.mounted) {
          /* ToastService.show(
            "i18n.attentionTitle".tr,
            "i18n.resourceNotFound".tr,
            AppTheme.danger,
            icon: Icons.music_off_rounded,
          ); */
        }
      });
      Logger.error("AppFile is Empty", "VideoPlayerWidgetController", "initialize");
      onVideoLoaded.emit(false);
    }
  }

  void dispose(void Function() listeners) {
    _videoCtrl.removeListener(listeners);
    _videoCtrl.dispose();
    onStateChange.dispose();
  }

  Future<void> autoPlay() async {
    if (autoplay) {
      bool hasHeadset = await audio.headset.isHeadsetConnected();
      double volume = (hasHeadset || services.ventour.applicationType != ApplicationType.loan) ? 1 : 0;
      _videoCtrl.setVolume(volume);
      if (!hasHeadset &&
          !audio.modal.getNotShowAgain(AudioModalType.video) &&
          services.ventour.applicationType == ApplicationType.loan) {
        audio.modal.show(AudioModalType.video);
      } else {
        play(false);
      }
    }
  }

  Future<void> handlePlayPause(bool fromUser) async {
    if (currentState == VideoPlayerState.paused || currentState == VideoPlayerState.stopped) {
      await play(fromUser);
    } else {
      await pause(fromUser);
    }
  }

  Future<void> play(bool fromUser) async {
    await _videoCtrl.play();
    await animationCtrl.forward();
    currentState = VideoPlayerState.playing;
    onStateChange.emit(currentState);
    if (fromUser) _addTracking(TrackingAction.play);
  }

  Future<void> pause(bool fromUser) async {
    await _videoCtrl.pause();
    await animationCtrl.reverse();
    currentState = VideoPlayerState.paused;
    onStateChange.emit(currentState);
    if (fromUser) _addTracking(TrackingAction.pause);
  }

  Future<void> stop() async {
    await animationCtrl.reverse();
    await _videoCtrl.seekTo(Duration.zero);
    currentState = VideoPlayerState.stopped;
    onStateChange.emit(currentState);
    _addTracking(TrackingAction.stop);
  }

  Future<void> replay(bool fromUser) async {
    await _videoCtrl.seekTo(Duration.zero);
    if (currentState == VideoPlayerState.paused || currentState == VideoPlayerState.stopped) {
      await play(fromUser);
    }
  }

  Future<void> seekTo(double value) async {
    final newPosition = Duration(milliseconds: value.toInt());
    await _videoCtrl.seekTo(newPosition);
  }

  void _addTracking(String action) {
    services.tracking.creator.playerMedia(appFile.uuid, action);
  }

  void _addFullscreenTracking() {
    if (widgetUuid.isNotEmpty) {
      services.tracking.creator.fullscreenMode(widgetUuid);
    }
  }

  String formatDuration(Duration duration) {
    if (duration == Duration.zero) return "00:00";
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
