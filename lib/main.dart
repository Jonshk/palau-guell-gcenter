import 'package:flutter_localizations/flutter_localizations.dart';

import '/start_error_modal.dart';
import 'config.dart';
import 'gvam_content_sync/charging_sync_listener.dart';
import 'gvam_content_sync/device_heartbeat_service.dart';
import 'gvam_content_sync/gcenter_runtime.dart';
import 'gvam_content_sync/gcenter_settings_bridge.dart';

final ChargingSyncListener _chargingListener =
    ChargingSyncListener();

final DeviceHeartbeatService _deviceHeartbeat =
    DeviceHeartbeatService();

bool _gcenterStarted = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // IMPORTANTE:
  // GCenter NO arranca aquí porque todavía no conocemos
  // el UUID real de Ventour.

  Get.put(ApplicationService());

  await Environment.initialize();
  await AppTranslations.initialize();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  TerminateRestart.instance.initialize();

  await _configureAudioExtension();

  if (!kIsWeb) {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [],
    );
  }

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MobileFrame(
      child: GetMaterialApp(
        builder: (context, child) {
          final mq = MediaQuery.of(context);

          return MediaQuery(
            data: mq.copyWith(
              textScaler:
                  const TextScaler.linear(1.0),
              padding:
                  mq.padding.copyWith(bottom: 0),
              viewPadding:
                  mq.viewPadding.copyWith(bottom: 0),
            ),
            child: child!,
          );
        },
        localeResolutionCallback: (_, _) =>
            Get.locale?.languageCode == "ja-JA"
                ? const Locale("ja", "JP")
                : null,
        localizationsDelegates:
            GlobalMaterialLocalizations.delegates,
        navigatorKey: navigatorKey,
        title: "Palau Güell",
        initialRoute: AppRoutes.splash,
        getPages: List.from(AppPages.pages),
        translations: AppTranslations(),
        fallbackLocale:
            const Locale('es-ES'),
        locale:
            const Locale('es-ES'),
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        initialBinding:
            BindingsBuilder(() => _initializeApp()),
      ),
    );
  }

  Future<void> _initializeApp() async {
    final ventour =
        VentourApplicationService(
      Environment.configuration,
    );

    audio.setNavigatorKey(navigatorKey);

    await ventour
        .initializeApp()
        .then((initialized) async {
      services.initialize(ventour);

      // UUID ÚNICO DE GCENTER:
      // utilizamos exactamente el UUID que muestra
      // el menú técnico de Ventour.
      GCenterRuntime.configure(
        deviceUuid:
            ventour.core.device.uuid,
        publicationId:
            ventour.publicationReleaseId,
      );

      // Hace funcionales los 3 botones que aparecen
      // arriba de SettingsPage:
      // - Actualizar contenido
      // - Actualizar APK
      // - Actualizar todo
      GCenterSettingsBridge.register();

      // Heartbeat y escucha de carga SOLO después
      // de conocer el UUID real.
      if (!_gcenterStarted) {
        _gcenterStarted = true;

        _deviceHeartbeat.start();
        _chargingListener.start();

        await _chargingListener
            .checkImmediatelyIfCharging();
      }

      if (initialized) {
        await services.setupAppFlow();

        audio.setStorage(
          services.core.storage,
          initModalCtrl: true,
        );
      } else {
        NavigatorExtension.show(
          Get.context!,
          const StartErrorModal(),
        );
      }
    });
  }
}

Future<void> _configureAudioExtension() async {
  await audio.initialize(
    AudioExtensionConfiguration(
      headsetModal: HeadsetModal(),
      videoModal: HeadsetModal(),
      useSensorAutoplayAudio: false,
      useBackgroundAudio: false,
      requestHeadsetPermission: false,
      showModalsWithFunction: true,
      showHeadsetModal:
          HeadsetModal.show,
    ),
  );
}
