import '/config.dart';

export 'controller.dart';

class AudioPlayerWidget extends StatefulWidget {
  final AppFile appFile;
  final bool autoplay;
  final bool earpieceEnabled;
  final double height;
  final Size buttonSize;
  final Color backgroundColor;
  final Color iconsColor;
  final Color sliderColor;
  final Color sliderActiveColor;
  final Color sliderInactiveColor;
  final Color sliderFontColor;
  final bool onlySlider;
  final bool disabled;
  final AudioPlayerController? controller;
  final BorderRadius? radius;
  final EdgeInsets? padding;
  final EdgeInsets? innerPadding;
  final VoidCallback? showInMap;

  const AudioPlayerWidget({
    super.key,
    required this.appFile,
    this.autoplay = true,
    this.earpieceEnabled = !kIsWeb,
    this.height = 60,
    this.buttonSize = const Size(40, 40),
    this.backgroundColor = Colors.grey,
    this.iconsColor = Colors.white,
    this.sliderColor = Colors.white,
    this.sliderActiveColor = Colors.black,
    this.sliderInactiveColor = Colors.black38,
    this.sliderFontColor = Colors.black,
    this.onlySlider = false,
    this.disabled = false,
    this.controller,
    this.radius,
    this.padding,
    this.innerPadding,
    this.showInMap,
  });

  @override
  State<AudioPlayerWidget> createState() => AudioPlayerWidgetState();
}

class AudioPlayerWidgetState extends State<AudioPlayerWidget> with SingleTickerProviderStateMixin {
  late final AudioPlayerController controller;
  late final AnimationController _animationCtrl;

  Duration _totalDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;

  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playingStreamSubscription;
  StreamSubscription? _speedChangedSubscription;
  StreamSubscription? _stateChangedSubscription;
  StreamSubscription? _onLoadedSubscription;

  @override
  void initState() {
    if (widget.controller == null) {
      controller = AudioPlayerController(
        appFile: widget.appFile,
        autoplay: widget.autoplay,
        earpieceEnabled: widget.earpieceEnabled,
      );
    } else {
      controller = widget.controller!;
    }
    _animationCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _initializeListeners();
    controller.initialize();
    super.initState();
  }

  @override
  void dispose() {
    _animationCtrl.dispose();
    _disposeListeners();
    controller.dispose();
    super.dispose();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.width,
      padding: widget.padding,
      child: Container(
        padding: widget.innerPadding,
        decoration: BoxDecoration(color: widget.backgroundColor, borderRadius: widget.radius),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!widget.onlySlider)
              SizedBox(
                width: widget.buttonSize.width,
                height: widget.buttonSize.height,
                child: IconButton(
                  onPressed: () => controller.handlePlayPause(true),
                  padding: EdgeInsets.zero,
                  style: ButtonStyle(
                    padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                    fixedSize: WidgetStatePropertyAll(widget.buttonSize),
                    backgroundColor: WidgetStatePropertyAll(widget.backgroundColor),
                  ),
                  icon: AnimatedIcon(
                    progress: _animationCtrl,
                    icon: AnimatedIcons.play_pause,
                    size: 32,
                    color: widget.iconsColor,
                  ),
                ),
              ),
            if (!widget.onlySlider) const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: widget.height,
                child: Stack(
                  children: [
                    SliderTheme(
                      data: SliderThemeData(
                        thumbColor: widget.sliderColor,
                        thumbShape: RoundSliderThumbShape(enabledThumbRadius: !widget.onlySlider ? 4 : 1),
                        activeTrackColor: widget.sliderActiveColor,
                        trackShape: const RoundedRectSliderTrackShape(),
                        trackHeight: 1.0,
                        inactiveTrackColor: widget.sliderInactiveColor,
                        overlayShape: SliderComponentShape.noThumb,
                      ),
                      child: Slider(
                        value: _currentPosition.inMilliseconds.toDouble().clamp(
                          0.0,
                          _totalDuration.inMilliseconds.toDouble(),
                        ),
                        max: _totalDuration.inMilliseconds.toDouble(),
                        onChanged: widget.disabled ? (_) {} : controller.seekTo,
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 16,
                        padding: const EdgeInsetsDirectional.symmetric(horizontal: 4.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              controller.formatDuration(_currentPosition),
                              style: TextStyle(
                                fontSize: 14,
                                color: widget.sliderFontColor,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            Text(
                              controller.formatDuration(_totalDuration),
                              style: TextStyle(
                                fontSize: 14,
                                color: widget.sliderFontColor,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!widget.onlySlider) const SizedBox(width: 8),
            if (!widget.onlySlider)
              Container(
                constraints: const BoxConstraints(maxWidth: 40, maxHeight: 32),
                child: ElevatedButton(
                  onPressed: () => controller.changePlaybackRate(),
                  style: ButtonStyle(
                    padding: WidgetStatePropertyAll(EdgeInsets.zero),
                    backgroundColor: WidgetStateProperty.all(AppTheme.primary700),
                    textStyle: const WidgetStatePropertyAll(
                      TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.light),
                    ),
                  ),
                  child: SizedBox(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        "x ${controller.player.speed}",
                        style: TextStyle(
                          color: AppTheme.primary100,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                          height: 14 / 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (!widget.onlySlider) const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  void _initializeListeners() {
    _positionSubscription = controller.player.positionStream.listen((position) {
      setState(() => _currentPosition = position);
    });
    _durationSubscription = controller.player.durationStream.listen((duration) {
      if (duration != null) setState(() => _totalDuration = duration);
    });
    _playingStreamSubscription = controller.player.playingStream.listen((playing) {
      if (playing) {
        _animationCtrl.forward();
      } else {
        _animationCtrl.reverse();
      }
    });
    _speedChangedSubscription = controller.onSpeedChanged.stream.listen((_) => setState(() {}));
    _onLoadedSubscription = controller.onLoaded.stream.listen((_) => setState(() {}));
  }

  void _disposeListeners() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playingStreamSubscription?.cancel();
    _stateChangedSubscription?.cancel();
    _speedChangedSubscription?.cancel();
    _onLoadedSubscription?.cancel();
  }
}
