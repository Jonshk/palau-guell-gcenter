import '/config.dart';

part 'bluetooth.dart';
part 'pwa.dart';

class MastersyncService {
  final PlayerController _controller = Get.isRegistered<PlayerController>()
      ? Get.find<PlayerController>()
      : Get.put(PlayerController(), permanent: true);
  late final PWAService pwa = PWAService(controller: _controller);
  late final BLEService bluetooth = BLEService(controller: _controller);
  bool _isNotLoan = false;

  GlobalKey<AudioPlayerWidgetState> get playerKey => _controller._playerKey;
  RxBool get isSync => _controller.isSync;
  RxBool get isScanning => _controller.isScanning;

  void initialize(String contentUuid) {
    if (contentUuid.isEmpty) {
      Logger.error("Content Uuid is empty, service probably not working.", "MastersyncService", "initialize");
    }
    _controller.renewPlayerKey();
    _isNotLoan = (services.ventour.applicationType != ApplicationType.loan);
    (_isNotLoan) ? pwa._initialize(contentUuid) : bluetooth._initialize(contentUuid);
  }

  void dispose() {
    _controller.renewPlayerKey();
    (!_isNotLoan) ? bluetooth.stop() : pwa.stop();
    _controller.isSync.value = false;
    _controller.isScanning.value = false;
    _isNotLoan = false;
  }

  Future<void> play() async {
    if (audio.handler.player.playing) {
      await playerKey.currentState?.controller.pause(true);
      (_isNotLoan) ? pwa.stop() : await bluetooth.stop();
    } else {
      (_isNotLoan) ? pwa.scan() : await bluetooth.scan();
    }
  }
}

class PlayerController extends GetxController {
  GlobalKey<AudioPlayerWidgetState> _playerKey = GlobalKey<AudioPlayerWidgetState>();
  final isScanning = RxBool(false);
  final isSync = RxBool(false);

  void renewPlayerKey() {
    _playerKey = GlobalKey<AudioPlayerWidgetState>();
  }

  Future<void> _playAudio(int miliseconds, {int adjustMs = 0}) async {
    final targetMs = miliseconds + adjustMs;
    final safeMs = targetMs < 0 ? 0 : targetMs;
    await audio.handler.seek(Duration(milliseconds: safeMs));
    await audio.handler.play();
  }
}
