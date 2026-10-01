part of 'video.dart';

class VideoPlayerWidget extends StatefulWidget {
  final VideoPlayerWidgetController controller;
  final void Function()? openFullscreen;
  final void Function()? closeFullscreen;
  final bool autoplay;
  final bool fullscreen;
  final bool gradient;
  final bool showFullscreenButton;
  final bool showReplayButton;
  final double height;
  final Size buttonSize;
  final Color backgroundColor;
  final Color iconsColor;
  final Color sliderColor;
  final Color sliderActiveColor;
  final Color sliderInactiveColor;
  final Color sliderFontColor;
  final BorderRadius? radius;
  final EdgeInsets? padding;
  final EdgeInsets? innerPadding;

  const VideoPlayerWidget({
    super.key,
    required this.controller,
    required this.openFullscreen,
    required this.closeFullscreen,
    this.autoplay = true,
    this.fullscreen = false,
    this.gradient = false,
    this.showFullscreenButton = false,
    this.showReplayButton = false,
    this.height = 56,
    this.buttonSize = const Size(40, 40),
    this.backgroundColor = Colors.grey,
    this.iconsColor = Colors.white,
    this.sliderColor = Colors.white,
    this.sliderActiveColor = Colors.white,
    this.sliderInactiveColor = Colors.white,
    this.sliderFontColor = Colors.white,
    this.radius,
    this.padding,
    this.innerPadding,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerWidgetController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.width,
      padding: widget.padding,
      child: Container(
        padding: (widget.fullscreen) ? const EdgeInsets.symmetric(horizontal: 16) : widget.innerPadding,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          /* gradient: (widget.gradient)
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, AppTheme.dark],
                  stops: [0.0, 1],
                )
              : null, */
          borderRadius: widget.radius,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: (widget.fullscreen)
                  ? EdgeInsets.only(left: MediaQuery.of(context).padding.left)
                  : EdgeInsets.zero,
              child: SizedBox(
                width: widget.buttonSize.width,
                height: widget.buttonSize.height,
                child: IconButton(
                  onPressed: () => controller.handlePlayPause(true),
                  padding: EdgeInsets.zero,
                  style: ButtonStyle(
                    padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                    fixedSize: WidgetStatePropertyAll(widget.buttonSize),
                    backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
                  ),
                  icon: AnimatedIcon(
                    progress: controller.animationCtrl,
                    icon: AnimatedIcons.play_pause,
                    size: 32,
                    color: widget.iconsColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: widget.height,
                child: Stack(
                  children: [
                    SliderTheme(
                      data: SliderThemeData(
                        thumbColor: widget.sliderColor,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                        activeTrackColor: widget.sliderActiveColor,
                        trackShape: const RoundedRectSliderTrackShape(),
                        trackHeight: 1.0,
                        inactiveTrackColor: widget.sliderInactiveColor,
                        overlayShape: SliderComponentShape.noThumb,
                      ),
                      child: Slider(
                        value: controller.currentPosition.inMilliseconds.toDouble().clamp(
                          0.0,
                          controller.totalDuration.inMilliseconds.toDouble(),
                        ),
                        max: controller.totalDuration.inMilliseconds.toDouble(),
                        onChanged: controller.seekTo,
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 16,
                        padding: const EdgeInsetsDirectional.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              controller.formatDuration(controller.currentPosition),
                              style: TextStyle(
                                fontSize: 14,
                                color: widget.sliderFontColor,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            Text(
                              controller.formatDuration(controller.totalDuration),
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
            const SizedBox(width: 8),
            if (widget.showReplayButton)
              IconButton(
                onPressed: () => controller.replay(false),
                padding: EdgeInsets.zero,
                style: ButtonStyle(
                  fixedSize: WidgetStatePropertyAll(widget.buttonSize),
                  backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
                ),
                icon: Icon(Icons.replay_rounded, color: widget.iconsColor),
              ),
            _fullscreenButtonHandler(),
          ],
        ),
      ),
    );
  }

  Widget _fullscreenButtonHandler() {
    if (widget.showFullscreenButton) {
      if (widget.fullscreen) {
        return SizedBox(
          width: 40,
          height: 40,
          child: IconButton(
            onPressed: widget.closeFullscreen,
            icon: const Icon(Icons.fullscreen_exit_rounded/* , color: AppTheme.light */),
          ),
        );
      } else {
        return SizedBox(
          width: 40,
          height: 40,
          child: IconButton(
            onPressed: widget.openFullscreen,
            icon: const Icon(Icons.fullscreen_rounded, /* color: AppTheme.light */),
          ),
        );
      }
    } else {
      return const SizedBox();
    }
  }
}
