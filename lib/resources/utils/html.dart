//clase dummie para que no de error html

Window get window => Window();

class Window {
  History history = History();
  dynamic onMessage;
  dynamic removeEventListener;
  void addEventListener(dynamic a, dynamic b) {}
}

class History {
  void replaceState(String? a, String b, String c) {
    return;
  }
}

class IFrameElement {
  String src = "";
  dynamic style;
  dynamic onLoad;
  dynamic contentWindow;
}

PlatformViewRegistry get platformViewRegistry => PlatformViewRegistry();

class PlatformViewRegistry {
  dynamic registerViewFactory;
}

class Event {}

class DeviceOrientationEvent {
  double? alpha;
  dynamic absolute;
  void getProperty(dynamic a) {}
}

class EventListener {}

class JSNumber {
  double get toDartDouble => 0.0;
}

extension DummyToJS on Object {
  dynamic get toJS => JSFunction();
}

class JSFunction {
  void callAsFunction() {}
}
