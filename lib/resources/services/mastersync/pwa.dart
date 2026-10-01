part of 'mastersync.dart';

class PWAService {
  final PlayerController _controller;
  final url = dotenv.env['HOST_MASTERSYNC'] ?? "";
  final int _maxAttemps = 3;
  String _contentUuid = "";
  int _timerCounter = 0;
  Timer? _timer;

  PWAService({required PlayerController controller}) : _controller = controller;

  void _initialize(String contentUuid) {
    _contentUuid = contentUuid;
  }

  void stop() {
    _timerCounter = 0;
    _timer?.cancel();
    _controller.isSync.value = false;
  }

  void scan() {
    _timerCounter = 0;
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      _timerCounter++;
      await _requestAndPlay();

      if (_timerCounter >= _maxAttemps) {
        audio.handler.player.setVolume(1);
        stop();
      }
    });
  }

  Future<void> _requestAndPlay() async {
    _controller.isSync.value = true;
    try {
      var response = await _request();
      int statusCode = response.statusCode ?? 0;
      if (statusCode >= 200 && statusCode <= 300) {
        final int seconds = response.data['time_elapsed'];
        audio.handler.player.setVolume(0);
        await _controller._playAudio(seconds);
      }
    } catch (e) {
      Logger.error(e, "MastersyncContent", "_playAudio");
      if (_timerCounter <= 1) {
        NavigatorExtension.show(Get.context!, ErrorModal());
      }
    }
  }

  Future<Response<dynamic>> _request() async {
    return Dio().get("$url/video/get/$_contentUuid", options: Options(receiveTimeout: const Duration(seconds: 1)));
  }
}
