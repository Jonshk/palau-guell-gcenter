part of 'carousel_image.dart';

class CarouselWidget extends StatefulWidget {
  final String widgetUuid;
  final List<AppCarouselWidget> images;
  final TrackingCreatorService trackingCreator;
  final int initialIndex;
  final bool fullscreen;
  final bool showNavigation;
  final bool showPagination;
  final bool showFullScreen;
  final double? height;
  final Color? backgroundColor;
  final EdgeInsets? paginationPadding;
  final Color paginationColor;
  final Color paginationColorSelected;
  final List<String> imageCaption;

  const CarouselWidget({
    super.key,
    required this.widgetUuid,
    required this.images,
    required this.trackingCreator,
    this.initialIndex = 0,
    this.fullscreen = false,
    this.showNavigation = true,
    this.showPagination = true,
    this.showFullScreen = true,
    this.imageCaption = const [],
    this.height,
    this.backgroundColor,
    this.paginationPadding,
    this.paginationColor = Colors.white,
    this.paginationColorSelected = Colors.black,
  });

  @override
  State<CarouselWidget> createState() => _CarouselWidgetState();
}

class _CarouselWidgetState extends State<CarouselWidget> with TickerProviderStateMixin {
  late PageController _pageViewController;
  late TabController _tabController;
  int _currentPageIndex = 0;
  List<AppCarouselWidget> get images => widget.images;

  bool _allowPageScroll = true;
  int _pointerCount = 0;

  @override
  void initState() {
    super.initState();
    _currentPageIndex = widget.initialIndex;
    _pageViewController = PageController(initialPage: _currentPageIndex);
    int paginationLength = (images.isNotEmpty) ? images.length : 1;
    _tabController = TabController(initialIndex: _currentPageIndex, length: paginationLength, vsync: this);
  }

  @override
  void dispose() {
    super.dispose();
    _pageViewController.dispose();
    _tabController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !kIsWeb
          ? Platform.isIOS
                ? true
                : false
          : false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (!kIsWeb) {
            OrientationService.lock(OrientationService.portrait);
          }
          Navigator.pop(context, _currentPageIndex);
        }
      },
      child: Container(
        height: widget.height ?? MediaQuery.of(context).size.height,
        color: widget.backgroundColor ?? Colors.grey[100],
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Listener(
              onPointerDown: (event) {
                _pointerCount++;
                if (_pointerCount >= 2) {
                  setState(() {
                    _allowPageScroll = false;
                  });
                }
              },
              onPointerUp: (event) {
                _pointerCount--;
                if (_pointerCount < 2) {
                  setState(() {
                    _allowPageScroll = true;
                  });
                }
              },
              onPointerCancel: (event) {
                _pointerCount--;
                if (_pointerCount < 2) {
                  setState(() {
                    _allowPageScroll = true;
                  });
                }
              },
              child: PageView(
                controller: _pageViewController,
                onPageChanged: _handlePageViewChanged,
                physics: _allowPageScroll ? const ScrollPhysics() : const NeverScrollableScrollPhysics(),
                children: images,
              ),
            ),
            if (widget.showFullScreen) _fullscreenButtonHandler(context),
            if (widget.imageCaption.isNotEmpty && widget.imageCaption[_currentPageIndex] != "")
              Align(
                alignment: Alignment.topLeft,
                child: SafeArea(
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(8),
                    color: Colors.white.withValues(alpha: 0.6),
                    child: Text(
                      widget.imageCaption[_currentPageIndex],
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500, fontSize: 13),
                    ),
                  ),
                ),
              ),
            (widget.showNavigation && _currentPageIndex != 0)
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: SafeArea(
                      child: IconButton(
                        onPressed: _previousPage,
                        padding: const EdgeInsets.all(8),
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 36, weight: 200),
                      ),
                    ),
                  )
                : const SizedBox(),
            (widget.showNavigation && _currentPageIndex < (images.length - 1))
                ? Align(
                    alignment: Alignment.centerRight,
                    child: SafeArea(
                      child: IconButton(
                        onPressed: _nextPage,
                        padding: const EdgeInsets.all(8),
                        icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 36, weight: 200),
                      ),
                    ),
                  )
                : const SizedBox(),
            if (widget.showPagination && images.length > 1)
              Positioned(
                bottom: 30,
                child: PageIndicatorWidget(
                  tabController: _tabController,
                  currentPageIndex: _currentPageIndex,
                  onUpdateCurrentPageIndex: _updateCurrentPageIndex,
                  padding: widget.paginationPadding,
                  color: widget.paginationColor,
                  colorSelected: widget.paginationColorSelected,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handlePageViewChanged(int currentPageIndex) {
    _tabController.index = currentPageIndex;
    setState(() {
      _currentPageIndex = currentPageIndex;
    });
  }

  Future<void> _previousPage() async {
    if (_currentPageIndex != 0) {
      await _pageViewController.previousPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      _addSlideTracking();
    }
  }

  Future<void> _nextPage() async {
    if (_currentPageIndex < (images.length - 1)) {
      await _pageViewController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      _addSlideTracking(true);
    }
  }

  void _updateCurrentPageIndex(int index, [bool closedFullscreen = false]) {
    _tabController.index = index;
    if (closedFullscreen) {
      _pageViewController.jumpToPage(index);
    } else {
      _pageViewController.animateToPage(index, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  Future<void> _openFullscreen(BuildContext context) async {
    if (!kIsWeb) {
      OrientationService.lock(OrientationService.landscape);
    }
    _addFullscreenTracking();
    audio.sensor.enabled = false;
    final int? navigatorIndex = await Get.to<int>(
      () => Scaffold(
        body: CarouselWidget(
          widgetUuid: widget.widgetUuid,
          images: List.from(
            widget.images.map(
              (image) => AppCarouselWidget(appFile: image.appFile, caption: image.caption, fullscreen: true),
            ),
          ),
          trackingCreator: widget.trackingCreator,
          imageCaption: widget.imageCaption,
          initialIndex: _currentPageIndex,
          fullscreen: true,
          showNavigation: widget.showNavigation,
          showPagination: widget.showPagination,
          backgroundColor: widget.backgroundColor,
          paginationColor: widget.paginationColor,
          paginationColorSelected: widget.paginationColorSelected,
          paginationPadding: const EdgeInsets.only(bottom: 16),
        ),
      ),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 300),
    );
    if (navigatorIndex != null) {
      _updateCurrentPageIndex(navigatorIndex, true);
    }
  }

  Future<bool> _closeFullscreen(BuildContext context) async {
    if (widget.fullscreen) {
      if (!kIsWeb) {
        OrientationService.lock(OrientationService.portrait);
      }
      audio.sensor.enabled = true;
      Navigator.pop(context, _currentPageIndex);
    }
    return true;
  }

  Widget _fullscreenButtonHandler(BuildContext context) {
    if (widget.fullscreen) {
      return Align(
        alignment: Alignment.topRight,
        child: SafeArea(
          child: IconButton(
            onPressed: () => _closeFullscreen(context),
            padding: const EdgeInsets.all(12),
            icon: const Icon(Icons.fullscreen_exit, color: Colors.white, size: 36, weight: 300),
          ),
        ),
      );
    } else {
      return Positioned(
        right: 0,
        top: 8,
        child: IconButton(
          onPressed: () => _openFullscreen(context),
          padding: EdgeInsets.all(0),
          icon: Icon(Icons.fullscreen, size: 36, color: AppTheme.light),
          iconSize: 24,
        ),
      );
    }
  }

  void _addSlideTracking([bool next = false]) {
    int from = (next) ? (_currentPageIndex - 1) : (_currentPageIndex + 1);
    widget.trackingCreator.slide(widget.widgetUuid, from, _currentPageIndex);
  }

  void _addFullscreenTracking() {
    widget.trackingCreator.fullscreenMode(widget.widgetUuid);
  }
}
