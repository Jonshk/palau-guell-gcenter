import '/config.dart';

part 'controller.dart';
part 'player.dart';

enum VrVideoPlayerState { loading, playing, paused, stopped }

class VrVideoWidget extends StatefulWidget {
  final String widgetUuid;
  final PropertyContent<MediaResourceVideo> video;
  final bool autoplay;
  final bool fullscreen;
  final bool showControls;
  final double height;
  final Color backgroundColor;
  final int initialPosition;

  const VrVideoWidget({
    super.key,
    required this.widgetUuid,
    required this.video,
    this.autoplay = true,
    this.fullscreen = false,
    this.showControls = true,
    this.height = 312,
    this.backgroundColor = Colors.black,
    this.initialPosition = 0,
  });

  @override
  State<VrVideoWidget> createState() => VrVideoWidgetState();
}

class VrVideoWidgetState extends State<VrVideoWidget>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final VrVideoPlayerController controller;
  StreamSubscription<bool>? _videoLoadedListener;
  StreamSubscription<VrVideoPlayerState>? _videoStateListener;
  StreamSubscription<bool>? _onHeadsetConnected;
  bool _showPlayer = true;
  bool _isPlayerVisible = true;
  bool _pressed = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    controller = VrVideoPlayerController(
      widgetUuid: widget.widgetUuid,
      appFile: widget.video.mediaResource(),
      animationCtrl: AnimationController(vsync: this, duration: const Duration(milliseconds: 400)),
      autoplay: widget.autoplay,
    );
    _listeners();
    _listenerToShowControls();
    _displayControls();
    audio.sensor.enabled = false;
    audio.session.configureAudioSession(earpieceEnabled: (services.ventour.applicationType == ApplicationType.loan));
    super.initState();
  }

  @override
  void dispose() {
    _videoStateListener?.cancel();
    _videoLoadedListener?.cancel();
    _onHeadsetConnected?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      width: context.width,
      height: widget.height,
      color: widget.backgroundColor,
      child: Stack(
        children: [
          Stack(
            children: [
              VrPlayer(x: 0, y: 0, onCreated: controller._initialize, width: context.width, height: widget.height),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: (widget.fullscreen) ? context.height * 0.3 : 56 * 2,
                  child: InkWell(onTap: _displayControls),
                ),
              ),
              if (widget.showControls)
                Positioned(
                  left: 0,
                  bottom: 0,
                  right: 0,
                  child: Visibility(
                    visible: _isPlayerVisible,
                    maintainState: true,
                    child: AnimatedOpacity(
                      opacity: (_showPlayer) ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 400),
                      child: VrPlayerWidget(
                        controller: controller,
                        openFullscreen: _openFullscreen,
                        closeFullscreen: _closeFullscreen,
                        fullscreen: widget.fullscreen,
                        autoplay: widget.autoplay,
                        gradient: true,
                        showFullscreenButton: true,
                        innerPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          _loadingVideo(),
        ],
      ),
    );
  }

  void _listeners() {
    _videoLoadedListener = controller.onVideoLoaded.stream.listen((loaded) {
      if (loaded) {
        controller._observer.onStateChange = (VrState state) {
          if (state == VrState.ready && !controller.loaded) {
            setState(() {
              controller.currentState = VrVideoPlayerState.stopped;
              controller.loaded = true;
            });
            if (widget.fullscreen) controller.seekTo(widget.initialPosition.toDouble());
            controller.autoPlay();
          }
        };
        controller._observer.onDurationChange = (int milliseconds) {
          setState(() => controller.totalDuration = Duration(milliseconds: milliseconds));
        };
        controller._observer.onPositionChange = (int milliseconds) {
          setState(() => controller.currentPosition = Duration(milliseconds: milliseconds));
        };
        controller._observer.onFinishedChange = (bool ended) {
          if (ended) controller.stop();
        };
      }
    });
    _onHeadsetConnected = audio.headset.onHeadsetConnected.listen((connected) {
      if (services.ventour.applicationType == ApplicationType.loan) {
        double volume = (connected) ? 1 : 0;
        if (mounted) {
          controller.pause(false);
          controller._videoCtrl.setVolume(volume);
        }
      }
    });
  }

  void _listenerToShowControls() {
    _videoStateListener = controller.onStateChange.stream.listen((value) {
      _displayControls();
    });
  }

  void _displayControls() {
    if (!widget.showControls) return;
    if (!_pressed) {
      setState(() {
        _pressed = true;
        _isPlayerVisible = true;
      });
      Future.delayed(const Duration(milliseconds: 400)).then((_) {
        if (mounted) {
          setState(() {
            _showPlayer = true;
            _waitAndHideControls();
          });
        }
      });
    }
  }

  void _waitAndHideControls() {
    Future.delayed(const Duration(seconds: 4)).then((_) {
      if (mounted) {
        if (controller.currentState == VrVideoPlayerState.playing) {
          setState(() => _showPlayer = false);
          Future.delayed(const Duration(milliseconds: 400)).then((_) {
            if (mounted) {
              setState(() {
                _pressed = false;
                _isPlayerVisible = false;
              });
            }
          });
        } else {
          setState(() => _pressed = false);
        }
      }
    });
  }

  Widget _loadingVideo() {
    if (!controller.loaded) {
      return Stack(
        children: [
          SizedBox(
            height: context.height,
            width: context.width,
            child: Image(
              fit: BoxFit.cover,
              image: AppImageProvider(
                appFile: widget.video.mediaResource(
                  field: MediaResourceFields.poster,
                  mimetype: MediaResourceType.image,
                ),
              ),
            ),
          ),
          Center(child: CircularProgressIndicator(color: AppTheme.primary600)),
        ],
      );
    } else if (controller.loaded) {
      return const IgnorePointer(child: SizedBox());
    } else {
      return Center(child: Icon(Icons.videocam_off_outlined, size: 60, color: AppTheme.primary600));
    }
  }

  Future<void> _openFullscreen() async {
    if (controller.currentState == VrVideoPlayerState.playing) {
      controller.pause(false);
    }
    controller._addFullscreenTracking();
    final int? position = await Get.to<int?>(
      () => Scaffold(
        body: VrVideoWidget(
          widgetUuid: widget.widgetUuid,
          video: widget.video,
          fullscreen: true,
          height: Get.height,
          initialPosition: controller.currentPosition.inMilliseconds,
        ),
      ),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 300),
    );

    if (position != null) {
      controller.seekTo(position.toDouble());
      controller.play(false);
      _displayControls();
    }
  }

  void _closeFullscreen() {
    if (widget.fullscreen) {
      Navigator.pop<int?>(context, controller.currentPosition.inMilliseconds);
    }
  }
}
