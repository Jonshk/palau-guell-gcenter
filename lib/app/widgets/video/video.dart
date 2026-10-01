import '/config.dart';

part 'accessibility.dart';
part 'controller.dart';
part 'player.dart';

enum VideoPlayerState { loading, playing, paused, stopped }

class VideoWidget extends StatefulWidget {
  final String widgetUuid;
  final PropertyContent<MediaResourceVideo> video;
  final bool autoplay;
  final bool fullscreen;
  final bool showControls;
  final double? height;
  final Color? backgroundColor;
  final VideoPlayerWidgetController? controller;

  const VideoWidget({
    super.key,
    required this.widgetUuid,
    required this.video,
    this.autoplay = true,
    this.fullscreen = false,
    this.showControls = true,
    this.height,
    this.backgroundColor,
    this.controller,
  });

  @override
  State<VideoWidget> createState() => VideoWidgetState();
}

class VideoWidgetState extends State<VideoWidget> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final VideoPlayerWidgetController controller;
  StreamSubscription<bool>? _videoLoadedListener;
  StreamSubscription<VideoPlayerState>? _videoStateListener;
  StreamSubscription<bool>? _onHeadsetConnected;
  bool _showPlayer = true;
  bool _isPlayerVisible = true;
  bool _pressed = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    if (widget.fullscreen) {
      if (widget.controller != null) {
        controller = widget.controller!;
        controller._videoCtrl.addListener(_listeners);
      } else {
        Logger.error("Controller not assinged on Fullscreen", "VideoWidgetState", "initState");
      }
    } else {
      controller = VideoPlayerWidgetController(
        appFile: widget.video.mediaResource(),
        widgetUuid: widget.widgetUuid,
        autoplay: widget.autoplay,
      )..initialize(_listeners);
    }
    controller.animationCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _animationOnFullscreen();
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
    if (!widget.fullscreen) {
      controller.animationCtrl.dispose();
      controller.dispose(_listeners);
    }
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    route?.animation?.addStatusListener(_statusListener);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _closeFullscreen();
        }
      },
      child: Container(
        height: widget.height ?? context.height,
        color: widget.backgroundColor ?? Colors.black,
        child: Stack(
          children: [
            if (controller.loaded)
              SizedBox(
                width: context.width,
                height: context.height,
                child: InkWell(
                  onTap: _displayControls,
                  child: Stack(
                    children: [
                      Center(
                        child: FittedBox(
                          alignment: Alignment.center,
                          fit: BoxFit.contain,
                          child: SizedBox(
                            width: controller._videoCtrl.value.size.width,
                            height: controller._videoCtrl.value.size.height,
                            child: VideoPlayer(controller._videoCtrl),
                          ),
                        ),
                      ),
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
                              child: VideoPlayerWidget(
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
                ),
              ),
            _loadingVideo(),
          ],
        ),
      ),
    );
  }

  void _listeners() {
    _videoLoadedListener = controller.onVideoLoaded.stream.listen((loaded) {
      if (loaded) {
        if (controller._videoCtrl.value.isInitialized) {
          if (!controller.loaded) {
            setState(() {
              controller.currentState = VideoPlayerState.stopped;
              controller.totalDuration = controller._videoCtrl.value.duration;
              controller.loaded = true;
            });
            controller.autoPlay();
          }
        }
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
    if (controller._videoCtrl.value.isCompleted) {
      controller.stop();
    }
    setState(() {
      controller.currentPosition = controller._videoCtrl.value.position;
    });
  }

  void _animationOnFullscreen() {
    if (widget.fullscreen) {
      if (controller.currentState == VideoPlayerState.playing) {
        controller.animationCtrl.forward();
      }
    }
  }

  void _listenerToShowControls() {
    _videoStateListener = controller.onStateChange.stream.listen((value) {
      setState(() {});
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
        if (controller.currentState == VideoPlayerState.playing) {
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
          Center(child: CircularProgressIndicator(/* color: AppTheme.primary */)),
        ],
      );
    } else if (controller.loaded) {
      return const IgnorePointer(child: SizedBox());
    } else {
      return Center(child: Icon(Icons.videocam_off_outlined, size: 60/* , color: AppTheme.primary */));
    }
  }

  Future<void> _openFullscreen() async {
    if (!kIsWeb) {
      OrientationService.lock(OrientationService.landscape);
    }
    controller._addFullscreenTracking();

    await Get.to(
      () => Scaffold(
        body: VideoWidget(
          widgetUuid: widget.widgetUuid,
          video: widget.video,
          controller: controller,
          fullscreen: true,
          showControls: true,
          autoplay: true,
        ),
      ),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    )?.then((_) {
      _displayControls();
    });
  }

  Future<bool> _closeFullscreen() async {
    if (widget.fullscreen) {
      controller._videoCtrl.removeListener(_listeners);
      if (!kIsWeb) {
        OrientationService.lock(OrientationService.portrait);
      }
      Get.back();
    }
    return true;
  }

  void _statusListener(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (controller.currentState == VideoPlayerState.playing) {
        Future.delayed(const Duration(milliseconds: 400)).then((_) {
          controller.play(false);
        });
      }
    }
  }
}
