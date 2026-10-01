import '/config.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/img/home.png'),
            fit: BoxFit.fitWidth,
          ),
        ),
        child: Stack(
          alignment: AlignmentGeometry.center,
          children: [
            Positioned(
              top: mq.size.height / 3,
              bottom: 0,
              right: 0,
              left: 0,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black,
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 116,
              ),
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  SvgPicture.asset(
                    "assets/svg/logo.svg",
                    height: 156,
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await _startVisit();
                    },
                    label: Text(
                      "i18n.startVisit".tr,
                      style: const TextStyle(
                        color: AppTheme.light,
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    icon: Icon(
                      Symbols.arrow_forward,
                      size: 32,
                      color: AppTheme.light,
                    ),
                    iconAlignment:
                        IconAlignment.end,
                  ),
                ],
              ),
            ),
            if (services.settings != null)
              Align(
                alignment: Alignment.topLeft,
                child: SafeArea(
                  child: IconButton(
                    onPressed: () =>
                        services.settings!
                            .openSettings(
                      context,
                    ),
                    icon: const SizedBox(),
                    color: Colors.transparent,
                    highlightColor:
                        Colors.transparent,
                    enableFeedback: false,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _startVisit() async {
    if (kReleaseMode &&
        services.ventour.applicationType ==
            ApplicationType.loan) {
      services.tracking.prepareAndSend();
    }

    if (services.ventour.applicationType ==
        ApplicationType.loan) {
      services.alertModal.surveySend =
          false;
    }

    audio.modal.setNotShowAgain(
      AudioModalType.headset,
      false,
    );

    audio.modal.setNotShowAgain(
      AudioModalType.video,
      false,
    );

    // ================================================
    // INICIO REAL DE LA VISITA
    // ================================================

    services.tracking.creator.startVisit();

    // Desde aquí el dispositivo está EN USO.
    // GCenter recibirá este estado en el heartbeat.
    await services.markDeviceInUse();

    Get.toNamed(
      AppRoutes.tours,
    );
  }
}