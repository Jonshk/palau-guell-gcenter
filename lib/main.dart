import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import '/start_error_modal.dart';
import 'config.dart';

import 'gvam_content_sync/charging_sync_listener.dart';
import 'gvam_content_sync/device_heartbeat_service.dart';
import 'gvam_content_sync/gcenter_runtime.dart';
import 'gvam_content_sync/gcenter_settings_bridge.dart';
import 'gvam_content_sync/magnetic_return_listener.dart';

final ChargingSyncListener _chargingListener =
    ChargingSyncListener();

final DeviceHeartbeatService _deviceHeartbeat =
    DeviceHeartbeatService();

MagneticReturnListener? _magneticReturnListener;

bool _gcenterStarted = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Get.put(ApplicationService());

  await Environment.initialize();
  await AppTranslations.initialize();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  TerminateRestart.instance.initialize();

  await _configureAudioExtension();

  if (!kIsWeb) {
    await SystemChrome.setEnabledSystemUIMode(
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
              textScaler: const TextScaler.linear(1.0),
              padding: mq.padding.copyWith(bottom: 0),
              viewPadding: mq.viewPadding.copyWith(bottom: 0),
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
        fallbackLocale: const Locale('es-ES'),
        locale: const Locale('es-ES'),
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

      // ==================================================
      // GCENTER
      // ==================================================

      GCenterRuntime.configure(
        deviceUuid:
            ventour.core.device.uuid,
        publicationId:
            ventour.publicationReleaseId,
      );

      GCenterSettingsBridge.register();

      // ==================================================
      // DEVOLUCIÓN FÍSICA POR IMÁN
      // ==================================================

      _magneticReturnListener ??=
          MagneticReturnListener(
        onReturnDetected: () async {
          try {
            final wasInUse =
                !(await services
                    .deviceUsage
                    .isIdle());

            if (!wasInUse) {
              debugPrint(
                'GCenter: imán detectado, '
                'pero el dispositivo ya estaba LIBRE.',
              );
              return;
            }

            debugPrint(
              'GCenter: devolución magnética confirmada.',
            );

            // 1) Cambiar inmediatamente a LIBRE.
            await services.markDeviceIdle();

            // 2) Informarlo inmediatamente a GCenter.
            // No pedimos órdenes todavía: primero cerramos
            // y enviamos la visita.
            await _deviceHeartbeat.sendNow(
              pollCommands: false,
            );

            // 3) Cerrar visita + enviar estadísticas.
            // En esta versión está permitido también en DEBUG.
            final sent =
                await services
                    .sendTrackingByKeyboard();

            debugPrint(
              'GCenter: estadísticas finalizadas. '
              'sent=$sent',
            );
          } catch (e, stack) {
            debugPrint(
              'GCenter: error procesando '
              'devolución magnética: $e',
            );
            debugPrintStack(
              stackTrace: stack,
            );
          }
        },
      );

      // ==================================================
      // SERVICIOS GCENTER
      // ==================================================

      if (!_gcenterStarted) {
        _gcenterStarted = true;

        _deviceHeartbeat.start();
        _chargingListener.start();
        _magneticReturnListener!.start();

        await _chargingListener
            .checkImmediatelyIfCharging();
      }

      // ==================================================
      // VENTOUR
      // ==================================================

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
