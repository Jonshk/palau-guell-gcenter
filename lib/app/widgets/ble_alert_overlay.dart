import '/config.dart';

class BLEAlertOverlay extends StatefulWidget {
  final Function()? close;
  const BLEAlertOverlay({super.key, this.close});

  @override
  State<BLEAlertOverlay> createState() => _BLEAlertOverlayState();
}

class _BLEAlertOverlayState extends State<BLEAlertOverlay> {
  String code = "";
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    _playAlertAndVibrate();
    super.initState();
  }

  Future<void> _playAlertAndVibrate() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(pattern: [0, 500, 200, 500], repeat: 0);
    }
    _startFlashlight();
    audio.session.configureAudioSession(earpieceEnabled: false);
    await _audioPlayer.setAsset('assets/alert_sound.mp3');
    await _audioPlayer.setVolume(1.0);
    await _audioPlayer.setLoopMode(LoopMode.one);
    await _audioPlayer.play();
  }

  Future<void> _startFlashlight() async {
    try {
      while (mounted) {
        await TorchLight.enableTorch();
        await Future.delayed(Duration(milliseconds: 500));
        await TorchLight.disableTorch();
        await Future.delayed(Duration(milliseconds: 500));
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    audio.session.configureAudioSession(earpieceEnabled: true);
    Vibration.cancel();
    TorchLight.disableTorch();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        color: Colors.black,
        width: context.width,
        height: context.height,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 48,
          children: [
            Icon(Icons.warning, color: AppTheme.terciary500, size: 164),
            Text(
              "Alerta!!! Torneu el dispositiu al taulell",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.terciary500, fontSize: 32, fontWeight: FontWeight.w800),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: TextField(
                onChanged: (val) => code = val,
                keyboardType: TextInputType.number,
                style: TextStyle(color: AppTheme.terciary500, fontSize: 20),
                cursorColor: AppTheme.terciary500,
                decoration: InputDecoration(
                  hintText: 'Introdueix el codi',
                  hintStyle: TextStyle(color: AppTheme.terciary500.withValues(alpha: 0.5)),
                  labelText: 'Codi',
                  labelStyle: TextStyle(color: AppTheme.terciary500),
                  prefixIcon: Icon(Icons.lock_outline, color: AppTheme.terciary500),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.terciary500.withValues(alpha: 0.5), width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.terciary500, width: 2),
                  ),
                  filled: true,
                  fillColor: AppTheme.terciary500.withValues(alpha: 0.08),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: code == AppConstants.alertCode ? widget.close : () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.terciary500,
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Acceptar'),
            ),
          ],
        ),
      ),
    );
  }
}
