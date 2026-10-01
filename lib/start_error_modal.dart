import 'config.dart';

class StartErrorModal extends StatelessWidget {
  const StartErrorModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 5),
      child: IntrinsicHeight(
        child: Container(
          padding: const EdgeInsets.all(28),
          alignment: AlignmentGeometry.center,
          decoration: BoxDecoration(color: AppTheme.light, borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 24,
            children: [
              Icon(Symbols.warning, size: 40, color: Colors.redAccent),
              Text(
                "Ups… algo no salió bien.\nPara garantizar su correcto funcionamiento, es necesario reiniciarla.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent, fontSize: 16, height: 1),
              ),
              Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: context.width,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async => await TerminateRestart.instance.restartApp(
                      options: const TerminateRestartOptions(terminate: true),
                    ),
                    style: ButtonStyle(
                      splashFactory: InkRipple.splashFactory,
                      overlayColor: WidgetStatePropertyAll(Colors.grey.withValues(alpha: 0.25)),
                      minimumSize: WidgetStatePropertyAll(Size(100, 42)),
                      alignment: Alignment.center,
                      elevation: const WidgetStatePropertyAll(0),
                      padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                      backgroundColor: const WidgetStatePropertyAll(AppTheme.primary800),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(0))),
                      ),
                    ),
                    child: Text(
                      "Aceptar",
                      style: const TextStyle(color: AppTheme.light, fontSize: 20, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
