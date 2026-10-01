part of '/resources/config/services.dart';

class NavigationService extends GetxService {
  final TrackingCreatorService trackingCreator;
  NavigationService(this.trackingCreator);

  late PageController contentPageViewCtrl = PageController(initialPage: 0);
  var tabs = [GlobalKey<NavigatorState>(), GlobalKey<NavigatorState>(), GlobalKey<NavigatorState>()];

  //Spash Animation
  bool _endSplashAnimation = false;
  EventEmitter<bool> onEndSplashAnimation = EventEmitter<bool>();
  bool get endSplashAnimation => _endSplashAnimation;
  set endSplashAnimation(bool value) {
    onEndSplashAnimation.emit(value);
    _endSplashAnimation = value;
  }

  //TreeIndex
  int _currentTreeIndex = TreeViews.list;
  int get currentTreeIndex => _currentTreeIndex;
  EventEmitter<int> onTreeIndexChanged = EventEmitter<int>();
  set currentTreeIndex(int value) {
    onTreeIndexChanged.emit(value);
    _currentTreeIndex = value;
  }

  //Current Content
  int _currentContentIndex = -1;
  int get currentContentIndex => _currentContentIndex;
  EventEmitter<int> onCurrentContentIndexChanged = EventEmitter<int>();
  set currentContentIndex(int value) {
    onCurrentContentIndexChanged.emit(value);
    _currentContentIndex = value;
  }

  //Tour
  EventEmitter<bool> onTourListVisitedChanged = EventEmitter<bool>();

  void initialize() {
    services.filteredContents = services.availableContents;
    onTreeIndexChanged = EventEmitter<int>();
    _currentTreeIndex = TreeViews.list;
    contentPageViewCtrl = PageController(initialPage: 0);
    onCurrentContentIndexChanged = EventEmitter<int>();
    _currentContentIndex = -1;
    NavigatorExtension.counter = 0;
  }

  void dispose() {
    onTreeIndexChanged.dispose();
    contentPageViewCtrl.dispose();
    currentTreeIndex = TreeViews.list;
    onCurrentContentIndexChanged.dispose();
    _currentContentIndex = -1;
  }

  bool isInTreePage(int page) {
    return page == currentTreeIndex;
  }

  void goTreeNavigation(int page) {
    tabs[currentTreeIndex].currentState?.popUntil((route) => route.isFirst);
    services.filteredContents = services.availableContents;
    if (services.textController != null) {
      services.textController!.clear();
    }
    currentTreeIndex = page;
  }

  void goContent(BuildContext context, CustomerPlaceContent content, [String mode = TrackingMode.tour]) {
    if (services.textController != null) {
      services.textController!.text = "a";
      services.textController!.clear();
    }
    services.filteredContents = services.availableContents;
    services.contents.setCurrent(content);
    int contentIndex = _getContentIndex(content);
    _addToVisitedContent(content.uuid);
    currentContentIndex = contentIndex;
    contentPageViewCtrl = PageController(initialPage: contentIndex);
    addTrackingContentAccess(content.uuid, mode);
    Navigator.of(context).pushSlideRight(const ContentView());
  }

  Future<dynamic> openContentOutOfTour(
    BuildContext context,
    CustomerPlaceContent content, [
    String mode = TrackingMode.keyboard,
  ]) async {
    services.contents.setCurrent(content);
    _addToVisitedContent(content.uuid);
    addTrackingContentAccess(content.uuid, mode);
    return Get.to(() => ContentOutOfTourView(content: content));
  }

  Future<Null> prev() async {
    int prevIndex = currentContentIndex - 1;
    if (prevIndex == -1) return null;
    await _removeChilds();
    CustomerPlaceContent content = services.availableContents[prevIndex];
    final isFirstRouteInCurrentTab = !services.navigation.tabs[services.navigation.currentTreeIndex].currentState!
        .canPop();
    if (isFirstRouteInCurrentTab) {
      goContent(tabs[currentTreeIndex].currentContext!, content);
    } else {
      addTrackingContentViewed(services.contents.current.uuid);
      services.contents.setCurrent(content);
      _addToVisitedContent(content.uuid);
      addTrackingContentAccess(content.uuid, TrackingMode.tour);
      slideTo(prevIndex);
    }
  }

  Future<Null> next() async {
    int nextIndex = currentContentIndex + 1;
    if (nextIndex > (services.availableContents.length - 1)) return null;
    await _removeChilds();
    CustomerPlaceContent content = services.availableContents[nextIndex];
    final isFirstRouteInCurrentTab = !services.navigation.tabs[services.navigation.currentTreeIndex].currentState!
        .canPop();
    if (isFirstRouteInCurrentTab) {
      goContent(tabs[currentTreeIndex].currentContext!, content);
    } else {
      addTrackingContentViewed(services.contents.current.uuid);
      services.contents.setCurrent(content);
      addTrackingContentAccess(content.uuid, TrackingMode.tour);
      _addToVisitedContent(content.uuid);
      slideTo(nextIndex);
    }
  }

  Future<void> _removeChilds() async {
    int counter = NavigatorExtension.counter;
    if (counter > 1) {
      while (counter > 1) {
        final navigator = services.navigation.tabs[services.navigation.currentTreeIndex].currentState!;
        if (navigator.canPop()) {
          navigator.pop();
        }
        counter--;
      }
      await Future.delayed(const Duration(milliseconds: 600), () {});
    }
  }

  void _addToVisitedContent(String uuid) {
    services.alertModal.checkAlert();
    services.visitedContents.add(uuid);
    if (services.availableContents.isNotEmpty) {
      if (services.visitedContents.length / services.availableContents.length > 0.1) {
        if (!services.visitedTours.contains(services.tours.current.tour.uuid)) {
          services.visitedTours.add(services.tours.current.tour.uuid);
          onTourListVisitedChanged.emit(true);
        }
      }
    }
  }

  void slideTo(int page) {
    currentContentIndex = page;
    contentPageViewCtrl.animateToPage(page, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
  }

  int _getContentIndex(CustomerPlaceContent content) => services.availableContents.indexOf(content);

  void addTrackingContentAccess(String contentUuid, String mode) => trackingCreator.contentAccess(contentUuid, mode);

  void addTrackingContentViewed(String contentUuid) => trackingCreator.contentViewed(contentUuid);

  bool hasPrev() {
    return currentContentIndex - 1 >= 0;
  }

  bool hasNext() {
    return currentContentIndex < (services.availableContents.length - 1);
  }
}

class TreeViews {
  static const int list = 0;
  static const int map = 1;
  static const int keyboard = 2;
  static const int outContentView = 3;
}
