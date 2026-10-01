part of '/resources/config/services.dart';

class AppMapService extends GetxService {
  final GlobalKey mapKey = GlobalKey();
  AnimationController? animationCtrl;
  TransformationController transformationCtrl = TransformationController();
  List<GlobalKey> pointKeys = [];
  Size mapSize = const Size(0, 0);
  bool loaded = false;
  double initialScale = 0.5;
  double maxScale = 4.0;
  Matrix4 initialPosition = Matrix4.identity();

  void dispose() {
    pointKeys = [];
    mapSize = const Size(0, 0);
    loaded = false;
    animationCtrl = null;
    transformationCtrl = TransformationController();
  }

  void setMapInitialPosition() {
    Future.microtask(() {
      transformationCtrl.value = initialPosition;
    });
  }

  void mapTranslate(int index) {
    if (pointKeys.isNotEmpty) {
      BuildContext? context = pointKeys[index].currentContext;
      if (context != null) {
        Positioned point = context.widget as Positioned;

        double scaleFactor = 1.6;
        double dx = (Get.size.width / 2) - ((point.left! + 20) * scaleFactor);
        double dy = (Get.size.height / 4) - (point.top! * scaleFactor);

        Matrix4Tween matrix = Matrix4Tween(
          begin: transformationCtrl.value,
          end: Matrix4.compose(Vector3(dx, dy, 0.0), Quaternion.identity(), Vector3.all(scaleFactor)),
        );

        animationCtrl?.addListener(() {
          transformationCtrl.value = matrix.transform(animationCtrl!.value);
        });

        animationCtrl?.reset();
        animationCtrl?.forward();
      }
    }
  }

  void zoom([bool increase = true]) {
    const scaleFactor = 0.5;
    final currentScale = transformationCtrl.value.getMaxScaleOnAxis();
    final newScale = (increase) ? currentScale + scaleFactor : currentScale - scaleFactor;

    if (newScale >= 0.5 && newScale <= 3.0) {
      final translation = transformationCtrl.value.getTranslation();
      final viewWidth = Get.size.width;
      final viewHeight = Get.size.height;

      final centerX = viewWidth / 2;
      final centerY = viewHeight / 2;

      final offsetX = centerX - translation.x;
      final offsetY = centerY - translation.y;
      Matrix4Tween matrix = Matrix4Tween(
        begin: transformationCtrl.value,
        end: Matrix4.identity()
          ..translate(
            translation.x - offsetX * (newScale / currentScale - 1),
            translation.y - offsetY * (newScale / currentScale - 1),
          )
          ..scale(newScale),
      );

      animationCtrl?.addListener(() {
        transformationCtrl.value = matrix.transform(animationCtrl!.value);
      });
      animationCtrl?.reset();
      animationCtrl?.forward();
    }
  }

  Future<dynamic> showMapModal(BuildContext context, Widget mapModal) {
    return showModalBottomSheet(
      backgroundColor: AppTheme.primary800,
      isScrollControlled: true,
      context: context,
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: (4 / 5) * MediaQuery.of(context).size.height),
        child: mapModal,
      ),
    );
  }

  int? getCurrentContentFloorOrNull() {
    int? contentFloor;
    if (services.contents.current.uuid.isEmpty) return null;
    for (var map in services.maps.tourMaps) {
      MapContent? mapContent = map.contents.firstWhereOrNull((content) {
        return (content.contentUuid == services.contents.current.uuid);
      });
      if (mapContent != null) {
        contentFloor = map.floor;
        break;
      }
    }
    return contentFloor;
  }
}
