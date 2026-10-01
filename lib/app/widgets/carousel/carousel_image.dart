import '/config.dart';

part 'carousel.dart';
part 'paginator.dart';

class AppCarouselWidget extends StatelessWidget {
  final AppFile appFile;
  final String? caption;
  final bool fullscreen;
  final AlignmentGeometry aligment;
  const AppCarouselWidget({
    super.key,
    required this.appFile,
    this.caption,
    this.fullscreen = false,
    this.aligment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InteractiveViewer(
        panEnabled: fullscreen,
        scaleEnabled: fullscreen,
        minScale: 1,
        maxScale: 2,
        onInteractionEnd: _checkIfZoomToAddTracking,
        child: Stack(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height,
              width: context.width,
              child: Image(
                image: AppImageProvider(appFile: appFile),
                fit: _setBoxFit(),
                alignment: aligment,
              ),
            ),
            if (caption != null)
              Container(
                color: AppTheme.primary900.withValues(alpha: 0.7),
                margin: EdgeInsets.only(right: 44),
                padding: EdgeInsets.all(8),
                child: Text(caption!, style: TextStyle(color: AppTheme.light, fontSize: 14)),
              ),
          ],
        ),
      ),
    );
  }

  BoxFit _setBoxFit() => fullscreen ? BoxFit.scaleDown : BoxFit.cover;

  void _checkIfZoomToAddTracking(ScaleEndDetails details) {
    if (fullscreen && details.pointerCount == 2) {
      services.tracking.creator.zoomImage(appFile.uuid);
    }
  }
}
