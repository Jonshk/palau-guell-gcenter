part of '/resources/config/services.dart';

class TextSizeService extends GetxService {
  final TrackingCreatorService _trackingCreator;
  String uuid = "";
  int _oldZoomValue = 1;
  int _zoomValue = 1;
  int size = 14;
  EventEmitter<int> onTextSizeChange = EventEmitter<int>();

  TextSizeService(this._trackingCreator);

  bool checkDisabled([bool max = false]) {
    if (max) return (_zoomValue == 4);
    return (_zoomValue == 1);
  }

  void increase() {
    _oldZoomValue = _zoomValue;
    if (size < 26) {
      size += 4;
      _zoomValue++;
      onTextSizeChange.emit(size);
      _addTracking();
    }
  }

  void decrease() {
    _oldZoomValue = _zoomValue;
    if (size > 14.0) {
      size -= 4;
      _zoomValue--;
      onTextSizeChange.emit(size);
      _addTracking();
    }
  }

  void _addTracking() {
    if (uuid != "") {
      _trackingCreator.resizeText(uuid, _oldZoomValue, _zoomValue);
    }
  }
}
