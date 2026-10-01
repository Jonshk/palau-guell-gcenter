import "/config.dart";

class MobileFrame extends StatelessWidget {
  final Widget child;
  final double breakpoint;
  final double phoneAspectRatio;
  final double phoneMaxHeight;
  final double screenPaddingTop;
  final double screenPaddingBottom;
  final double screenPaddingLeft;
  final double screenPaddingRight;

  const MobileFrame({
    super.key,
    required this.child,
    this.breakpoint = 700.0,
    this.phoneAspectRatio = 500 / 886,
    this.phoneMaxHeight = 886.0,
    this.screenPaddingTop = 0.055,
    this.screenPaddingBottom = 0.040,
    this.screenPaddingLeft = 0.062,
    this.screenPaddingRight = 0.08,
  });

  @override
  Widget build(BuildContext context) {
    final isMobileDevice =
        defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android;
    if (!kIsWeb || isMobileDevice) return child;

    return LayoutBuilder(
      builder: (context, constraints) {
        final showFrame = constraints.maxWidth > breakpoint;

        final phoneHeight = showFrame
            ? (constraints.maxHeight * 0.92).clamp(0.0, phoneMaxHeight)
            : constraints.maxHeight;
        final phoneWidth = showFrame ? phoneHeight * phoneAspectRatio : constraints.maxWidth;

        final screenTop = showFrame ? phoneHeight * screenPaddingTop - 12 : 0.0;
        final screenBottom = showFrame ? phoneHeight * screenPaddingBottom : 0.0;
        final screenH = phoneHeight - screenTop - screenBottom;
        final screenLeft = showFrame ? phoneWidth * screenPaddingLeft : 0.0;
        final screenRight = showFrame ? phoneWidth * screenPaddingRight : 0.0;
        final screenW = phoneWidth - screenLeft - screenRight;

        return Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            color: showFrame ? Colors.white : null,
            child: Center(
              child: SizedBox(
                width: phoneWidth,
                height: phoneHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: screenTop,
                      left: screenLeft,
                      width: screenW,
                      height: screenH,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(showFrame ? phoneWidth * 0.06 : 0),
                        child: _AppViewport(width: screenW, height: screenH, child: child),
                      ),
                    ),
                    Positioned.fill(
                      child: Visibility(
                        visible: showFrame,
                        child: IgnorePointer(child: Image.asset('assets/img/mobile.png', fit: BoxFit.fill)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AppViewport extends StatelessWidget {
  final double width;
  final double height;
  final Widget child;

  const _AppViewport({required this.width, required this.height, required this.child});

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        size: Size(width, height),
        padding: EdgeInsets.zero,
        viewInsets: EdgeInsets.zero,
        viewPadding: EdgeInsets.zero,
      ),
      child: SizedBox(width: width, height: height, child: child),
    );
  }
}
