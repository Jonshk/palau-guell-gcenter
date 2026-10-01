part of 'video.dart';

class VrVideoPlayerController {
  final AppFile appFile;
  final String widgetUuid;
  final bool autoplay;
  final AnimationController animationCtrl;
  late final VrPlayerController _videoCtrl;
  late final VrPlayerObserver _observer;
  bool loaded = false;
  Duration totalDuration = Duration.zero;
  Duration currentPosition = Duration.zero;
  VrVideoPlayerState currentState = VrVideoPlayerState.loading;
  EventEmitter<VrVideoPlayerState> onStateChange = EventEmitter<VrVideoPlayerState>();
  EventEmitter<bool> onVideoLoaded = EventEmitter<bool>();

  VrVideoPlayerController({
    required this.appFile,
    required this.widgetUuid,
    required this.animationCtrl,
    this.autoplay = false,
  });

  Future<void> _initialize(VrPlayerController controller, VrPlayerObserver observer) async {
    _videoCtrl = controller;
    _observer = observer;
    if (appFile.uuid.isNotEmpty) {
      if (services.downloader.contentsDownloaded) {
        if (!kIsWeb) {
          await _videoCtrl.loadVideo(videoPath: appFile.file?.uri.toFilePath());
          onVideoLoaded.emit(true);
        } else {
          Logger.error("NOT IMPLEMENTED", "VrVideoPlayerController", "_initialize");
        }
      } else {
        await _videoCtrl.loadVideo(videoUrl: appFile.url);
        onVideoLoaded.emit(true);
      }
    } else {
      Future.delayed(const Duration(milliseconds: 1200)).then((value) {
        if (Get.context!.mounted) {
          ToastService.show(
            "i18n.attentionTitle".tr,
            "i18n.resourceNotFound".tr,
            Colors.redAccent,
            icon: Icons.music_off_rounded,
          );
        }
      });
      Logger.error("AppFile is Empty", "VideoPlayerWidgetController", "initialize");
      onVideoLoaded.emit(false);
    }
  }

  void dispose() {
    _observer.cancelListeners();
    animationCtrl.dispose();
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
    if (currentState == VrVideoPlayerState.paused || currentState == VrVideoPlayerState.stopped) {
      await play(fromUser);
    } else {
      await pause(fromUser);
    }
  }

  Future<void> play(bool fromUser) async {
    await _videoCtrl.play();
    await animationCtrl.forward();
    currentState = VrVideoPlayerState.playing;
    onStateChange.emit(currentState);
    if (fromUser) _addTracking(TrackingAction.play);
  }

  Future<void> pause(bool fromUser) async {
    await _videoCtrl.pause();
    await animationCtrl.reverse();
    currentState = VrVideoPlayerState.paused;
    onStateChange.emit(currentState);
    if (fromUser) _addTracking(TrackingAction.pause);
  }

  Future<void> stop() async {
    await animationCtrl.reverse();
    await _videoCtrl.seekTo(Duration.zero.inMilliseconds);
    currentState = VrVideoPlayerState.stopped;
    onStateChange.emit(currentState);
    _addTracking(TrackingAction.stop);
  }

  Future<void> replay(bool fromUser) async {
    await _videoCtrl.seekTo(Duration.zero.inMilliseconds);
    if (currentState == VrVideoPlayerState.paused || currentState == VrVideoPlayerState.stopped) {
      await play(fromUser);
    }
  }

  void seekTo(double value) {
    _videoCtrl.seekTo(value.toInt());
  }

  void _addTracking(String action) {
    services.tracking.creator.playerMedia(appFile.uuid, action);
  }

  void _addFullscreenTracking() {
    if (widgetUuid.isNotEmpty) {
      services.tracking.creator.fullscreenMode(widgetUuid);
    }
  }

  String formatDuration(Duration? duration) {
    if (duration != null) {
      String twoDigits(int n) => n.toString().padLeft(2, "0");
      String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
      String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
      return "$twoDigitMinutes:$twoDigitSeconds";
    }
    return "00:00";
  }
}
