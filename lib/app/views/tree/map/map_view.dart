import '/config.dart';

part 'map_floor_selector.dart';
part 'map_marker.dart';

class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final AppMapService controller = services.map;
  CustomerPlaceContent? contentSelected;
  double zoom = 0;
  int selectedPointIndex = -1;
  Widget map = const SizedBox();
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _onMapMoveToContent();
  }

  @override
  void initState() {
    super.initState();
    controller.animationCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _loadMapSize();
    services.tracking.screen.start();
    controller.transformationCtrl.addListener(() {
      setState(() {
        zoom = controller.transformationCtrl.value.getColumn(2)[2];
      });
    });
    _onMapMoveToContent();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void dispose() {
    controller.animationCtrl?.dispose();
    contentSelected = null;
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if ((!controller.loaded)) {
      return SizedBox(child: map);
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _mapHeader(),
          Flexible(
            child: Container(
              color: Color(0xFFEDEDED),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _setInitialTransform(constraints.maxWidth, constraints.maxHeight);
                  return InteractiveViewer(
                    transformationController: controller.transformationCtrl,
                    boundaryMargin: const EdgeInsets.all(60.0),
                    minScale: 0.1,
                    maxScale: 4.0,
                    constrained: false,
                    child: SizedBox(child: Stack(children: [map, ..._getPoints()])),
                  );
                },
              ),
            ),
          ),
          if (services.maps.tourMaps.length > 1)
            Container(
              height: 84,
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.symmetric(vertical: 20),
              color: const Color(0xFFEDEDED),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [MapFloorSelector(onFloordChanged: _onFloorChanged)],
                  ),
                ),
              ),
            ),
        ],
      );
    }
  }

  Widget _mapHeader() {
    return Container(
      color: Color(0xFFEDEDED),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsGeometry.fromLTRB(0, 50, 0, 38),
            child: Text(
              "i18n.maps.${services.maps.currentFloor}".tr.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.primary900,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                fontFamily: 'archivo', fontFamilyFallback: AppTheme.fontFallback,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _setInitialTransform(double screenWidth, double screenHeight) {
    if (_initialized) return;
    double scale = screenWidth / controller.mapSize.width;
    String scaleStr = scale.toStringAsFixed(2);
    scale = double.parse(scaleStr);
    controller.initialScale = scale;

    double offsetX = (screenWidth - (controller.mapSize.width * controller.initialScale)) / 2;
    double offsetY = (screenHeight - (controller.mapSize.height * controller.initialScale)) / 2;

    controller.initialPosition = Matrix4.identity()
      ..translate(offsetX, offsetY)
      ..scale(controller.initialScale);
    controller.setMapInitialPosition();

    _initialized = true;
  }

  void _loadMapSize() async {
    if (services.maps.current.uuid.isNotEmpty) {
      final PictureInfo info = await vg.loadPicture(services.maps.current.mediaResource.getBytesLoader(), null);
      controller.mapSize = info.size;
      _loadMap();
    } else {
      setState(() {
        map = Center(
          child: Text(
            "i18n.mapNotAvailable".tr,
            style: const TextStyle(fontFamily: AppTheme.fontSecondary, fontFamilyFallback: AppTheme.fontFallback, fontSize: 20, color: AppTheme.marron100),
          ),
        );
      });
    }
  }

  void _loadMap() {
    setState(() {
      map = SvgPicture(services.maps.current.mediaResource.getBytesLoader(), fit: BoxFit.contain);
      if (!controller.loaded) {
        controller.loaded = true;
        controller.setMapInitialPosition();
      }
    });
  }

  void _onMapMoveToContent() {
    int? currentContentFloor = services.map.getCurrentContentFloorOrNull();
    if (currentContentFloor != null) {
      _onFloorChanged(currentContentFloor);
      Future.delayed(const Duration(milliseconds: 400)).then((_) {
        if (mounted) {
          contentSelected = services.contents.current;
          _focusOnContent();
        }
      });
    }
  }

  void _onFloorChanged(int floor) {
    _unselectAll();
    setState(() {
      contentSelected = null;
      services.maps.setCurrentFloor(floor);
      _loadMapSize();
      controller.setMapInitialPosition();
    });
  }

  void _focusOnContent() {
    if (contentSelected != null) {
      int index = _findMapContentIndex(contentSelected!.uuid);
      if (index > -1) {
        _selectContent(index);
        services.map.mapTranslate(index);
      }
    }
  }

  int _findMapContentIndex(String contentUuid) {
    return services.maps.currentMapContents.indexWhere((content) => content.contentUuid == contentUuid);
  }

  List<Widget> _getPoints() {
    List<Widget> points = [];
    controller.pointKeys = [];
    double offsetY = 4;
    double offsetX = 4;

    for (var i = 0; i < services.maps.currentMapContents.length; i++) {
      MapContent content = services.maps.currentMapContents[i];
      GlobalKey pointKey = GlobalKey();
      controller.pointKeys.add(pointKey);
      points.add(
        Positioned(
          key: pointKey,
          top: ((controller.mapSize.height * content.y) / 100) + offsetY,
          left: ((controller.mapSize.width * content.x) / 100) - offsetX,
          child: services.isContentUuidHidden(content.contentUuid)
              ? const SizedBox.shrink()
              : Transform.scale(
                  scale: (zoom > 1) ? (1 / zoom) : 1,
                  child: InkWell(
                    onTap: () => _selectContent(i, content.contentUuid),
                    child: MapViewMarker(
                      size: const Size(44, 44),
                      keyboardCode: _getContentKeyboard(content.contentUuid),
                      contentUuid: content.contentUuid ?? "",
                      isSelected: services.maps.currentMapContents[i].selected,
                      showKeyboardCode: true,
                    ),
                  ),
                ),
        ),
      );
    }
    return points;
  }

  void _selectContent(int index, [String? contentUuid]) {
    if (services.isContentUuidHidden(contentUuid)) return;
    if (contentSelected != null && contentSelected!.uuid == contentUuid) {
      setState(() => _closeUnselect());
      return;
    }
    setState(() {
      selectedPointIndex = index;
      _unselectAll();
      services.maps.currentMapContents[index].selected = true;
    });
    if (contentUuid != null && contentUuid.isNotEmpty) {
      contentSelected = services.contents.getContentById(contentUuid);
      if (contentSelected != null) {
        controller.mapTranslate(index);
        ContentCard.showModal(context, contentSelected!, () {
          services.navigation.goContent(context, contentSelected!, TrackingMode.map);
        });
        setState(() {});
      } else {
        contentSelected = services.contents.getContentFromAllById(contentUuid);
        if (contentSelected != null) {
          controller.mapTranslate(index);
          ContentCard.showModal(context, contentSelected!, () {
            Navigator.pop(context);
            services.navigation.goContent(context, contentSelected!, TrackingMode.map);
          });
          setState(() {});
        }
      }
    }
  }

  void _closeUnselect() {
    _closeContent();
    _unselectAll();
  }

  void _closeContent() {
    setState(() => contentSelected = null);
  }

  void _unselectAll() {
    for (var mapContent in services.maps.currentMapContents) {
      mapContent.selected = false;
    }
  }

  String _getContentKeyboard(String? contentUuid) {
    if (contentUuid == null) return "";
    var content = services.contents.getContentFromAllById(contentUuid);
    if (content != null) {
      return content.keyboardCode;
    }
    return "";
  }
}

class FloorLegendItem {
  final String number;
  final String textKey;
  final LegendType type;

  const FloorLegendItem({required this.number, required this.textKey, this.type = LegendType.normal});
}

enum LegendType { normal, access }
