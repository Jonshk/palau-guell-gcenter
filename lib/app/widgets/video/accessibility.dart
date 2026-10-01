part of 'video.dart';

class AccessibilityVideoWidget extends StatefulWidget {
  final String widgetUuid;
  final PropertyContent<MediaResourceVideo> video;
  final bool autoplay;
  final bool showControls;
  final Offset? initialPosition;
  const AccessibilityVideoWidget({
    super.key,
    required this.widgetUuid,
    required this.video,
    this.autoplay = true,
    this.showControls = true,
    this.initialPosition,
  });

  @override
  State<AccessibilityVideoWidget> createState() => _AccessibilityVideoWidget1State();
}

class _AccessibilityVideoWidget1State extends State<AccessibilityVideoWidget> {
  final Size videoSize = const Size(300, 200);
  Offset _position = const Offset(16, 16);

  @override
  void initState() {
    super.initState();
    if (widget.initialPosition != null) {
      _position = widget.initialPosition!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: _position.dy,
          left: _position.dx,
          child: SizedBox(
            width: videoSize.width,
            height: videoSize.height,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanUpdate: _moveVideo,
              child: VideoWidget(
                height: videoSize.height,
                widgetUuid: widget.widgetUuid,
                video: widget.video,
                autoplay: widget.autoplay,
                showControls: widget.showControls,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _moveVideo(DragUpdateDetails details) {
    setState(() {
      _position += details.delta;
      _position = Offset(
        _position.dx.clamp(0, context.width - videoSize.width),
        _position.dy.clamp(
          (MediaQuery.of(context).padding.top),
          context.height - (AppConstants.tabbarHeight * 2 + videoSize.height + 30),
        ),
      );
    });
  }
}
