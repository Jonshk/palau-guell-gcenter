part of '/resources/config/services.dart';

class ApplicationService extends GetxService {
  late final VentourApplicationService ventour;
  late final AlertService alerts;
  late final CoreService core;
  late final TourService tours;
  late final MapService maps;
  late final AppMapService map;
  late final ContentService contents;
  late final LanguageService languages;
  late final CategoriesService categories;
  late final AccessibilityService accessibility;
  late final TrackingService tracking;
  late final DownloaderService downloader;
  late final TextSizeService textSize;
  late final NavigationService navigation;
  late final PipeService pipes;
  late final PurchaseService purchase;
  late final MastersyncService mastersync;
  late final AlertModalService alertModal;
  late final BleAlertService bleAlert;
  SettingService? settings;

  EventEmitter<bool> onEndVentourCharge =
      EventEmitter<bool>();

  List<CustomerPlaceContent> filteredContents = [];
  List<String> visitedContents = [];
  List<String> visitedTours = [];
  TextEditingController? textController;

  final DeviceUsageService deviceUsage =
      DeviceUsageService();

  ApplicationService();

  bool isContentHidden(
    CustomerPlaceContent content,
  ) =>
      isContentUuidHidden(content.uuid);

  bool isContentUuidHidden(String? uuid) {
    if (uuid == null ||
        !AppConstants.hiddenContentUuids
            .contains(uuid)) {
      return false;
    }

    final now = DateTime.now();

    return !now.isBefore(
          AppConstants.hiddenContentFrom,
        ) &&
        now.isBefore(
          AppConstants.hiddenContentTo,
        );
  }

  List<CustomerPlaceContent>
      get availableContents =>
          contents.tourContents
              .where(
                (content) =>
                    !isContentHidden(content),
              )
              .toList();

  void initialize(
    VentourApplicationService ventour,
  ) {
    this.ventour = ventour;
    core = ventour.core;
    alerts = ventour.domain.alerts;
    tours = ventour.domain.tours;
    maps = ventour.domain.maps;
    categories = ventour.domain.categories;
    contents = ventour.domain.contents;
    languages = ventour.domain.languages;
    downloader = ventour.domain.downloader;
    tracking = ventour.domain.tracking;
    accessibility =
        ventour.domain.accessibility;
    purchase = ventour.domain.purchase;
    pipes = ventour.domain.getPipes();
    settings = SettingService(ventour);

    onEndVentourCharge.emit(true);

    mastersync = MastersyncService();
    bleAlert = BleAlertService();

    textSize =
        Get.put(TextSizeService(tracking.creator));
    navigation =
        Get.put(NavigationService(tracking.creator));
    map = Get.put(AppMapService());
    alertModal = Get.put(AlertModalService());

    if (ventour.applicationType ==
        ApplicationType.loan) {
      bleAlert.initialize();
    }
  }

  Future<void> setupAppFlow() async {
    await markDeviceIdle();

    await _setMainLanguageAndNavigate();

    _checkTrackingToSend();
  }

  Future<void> markDeviceInUse() async {
    await deviceUsage.markInUse();
  }

  Future<void> markDeviceIdle() async {
    await deviceUsage.markIdle();
  }

  Future<void>
      _setMainLanguageAndNavigate() async {
    Get.updateLocale(
      Locale(languages.main.isoCode),
    );
    languages.setCurrent(languages.main);

    if (navigation._endSplashAnimation ||
        Get.currentRoute != AppRoutes.splash) {
      Get.offAllNamed(AppRoutes.languages);
    } else {
      services.navigation
          .onEndSplashAnimation.stream
          .listen((value) {
        if (value) {
          Get.offAllNamed(
            AppRoutes.languages,
          );
        }
      });
    }
  }

  void _checkTrackingToSend() {
    // Se mantiene el comportamiento original:
    // el envío automático POR CARGA solo funciona
    // en release. Así DEBUG no se reinicia por
    // enchufar el teléfono durante las pruebas.
    if (!kReleaseMode) {
      return;
    }

    if (ventour.applicationType ==
        ApplicationType.loan) {
      bool isProcessing = false;
      final battery = Battery();

      battery.onBatteryStateChanged.listen(
        (state) {
          if (state == BatteryState.charging &&
              !isProcessing) {
            isProcessing = true;

            Future.delayed(
              const Duration(milliseconds: 10),
            ).then((_) {
              tracking
                  .prepareAndSend()
                  .then((sent) {
                if (sent) {
                  ToastService.show(
                    "Atención",
                    "Estadisticas enviadas!",
                    Colors.green,
                  );

                  Future.delayed(
                    const Duration(seconds: 2),
                  ).then((_) async {
                    await TerminateRestart
                        .instance
                        .restartApp(
                      options:
                          const TerminateRestartOptions(
                        terminate: true,
                      ),
                    );
                  });
                } else {
                  isProcessing = false;
                }
              });
            });
          }
        },
      );
    } else {
      tracking.listenToSend();
    }
  }

  /// Cierra la visita y envía las estadísticas.
  ///
  /// IMPORTANTE:
  /// A diferencia del comportamiento anterior, este método
  /// funciona también en DEBUG para poder probar el circuito
  /// completo del disparador magnético.
  ///
  /// El envío automático por carga continúa limitado a RELEASE
  /// en _checkTrackingToSend(), evitando reinicios inesperados
  /// mientras desarrollamos.
  Future<bool> sendTrackingByKeyboard() async {
    if (ventour.applicationType !=
        ApplicationType.loan) {
      return false;
    }

    tracking.creator.endVisit();

    await markDeviceIdle();

    await Future.delayed(
      const Duration(milliseconds: 10),
    );

    final sent =
        await tracking.prepareAndSend();

    if (sent) {
      ToastService.show(
        "Atención",
        "Estadisticas enviadas!",
        Colors.green,
      );

      await Future.delayed(
        const Duration(seconds: 2),
      );

      await TerminateRestart.instance.restartApp(
        options:
            const TerminateRestartOptions(
          terminate: true,
        ),
      );
    }

    return sent;
  }
}
