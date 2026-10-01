import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

class MagneticReturnListener {
  final Future<void> Function() onReturnDetected;

  MagneticReturnListener({
    required this.onReturnDetected,
  });

  StreamSubscription<MagnetometerEvent>? _subscription;

  // ==========================================================
  // CONFIGURACIÓN
  // ==========================================================

  // Valores medidos en el Realme Note 50:
  //
  // Normal:      ~49-51 µT
  // Alfombrilla: ~238-324 µT
  //
  // 150 µT deja bastante margen y evita falsos positivos.
  static const double triggerThreshold = 150.0;

  // Para permitir una nueva lectura, el campo debe volver
  // claramente a una zona normal.
  static const double resetThreshold = 100.0;

  bool _armed = true;
  bool _processing = false;

  double _lastMagnitude = 0;

  double get lastMagnitude => _lastMagnitude;

  bool get isArmed => _armed;

  bool get isProcessing => _processing;

  // ==========================================================
  // INICIO
  // ==========================================================

  void start() {
    _subscription?.cancel();

    _subscription = magnetometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen(
      _onSensor,
      onError: (Object error) {
        debugPrint(
          'GCenter: error en magnetómetro: $error',
        );
      },
    );

    debugPrint(
      'GCenter: detector magnético iniciado '
      '(trigger=$triggerThreshold µT, '
      'reset=$resetThreshold µT).',
    );
  }

  // ==========================================================
  // SENSOR
  // ==========================================================

  Future<void> _onSensor(
    MagnetometerEvent event,
  ) async {
    final magnitude = sqrt(
      (event.x * event.x) +
          (event.y * event.y) +
          (event.z * event.z),
    );

    _lastMagnitude = magnitude;

    // ========================================================
    // REARMADO
    // ========================================================
    //
    // Una vez detectado el imán, no permitimos otro disparo
    // mientras el teléfono siga cerca de la alfombrilla.
    //
    // Solo vuelve a quedar preparado cuando el campo baja
    // por debajo de 100 µT.
    // ========================================================

    if (!_armed) {
      if (magnitude <= resetThreshold) {
        _armed = true;

        debugPrint(
          'GCenter: detector magnético rearmado '
          '(${magnitude.toStringAsFixed(1)} µT).',
        );
      }

      return;
    }

    // ========================================================
    // YA ESTAMOS PROCESANDO UNA DEVOLUCIÓN
    // ========================================================

    if (_processing) {
      return;
    }

    // ========================================================
    // CAMPO NORMAL
    // ========================================================

    if (magnitude < triggerThreshold) {
      return;
    }

    // ========================================================
    // DISPARO INMEDIATO
    // ========================================================
    //
    // Ya NO esperamos 600 ms ni 150 ms.
    //
    // En cuanto el magnetómetro supera los 150 µT,
    // consideramos que el dispositivo ha pasado por
    // la alfombrilla.
    // ========================================================

    _armed = false;
    _processing = true;

    debugPrint(
      'GCenter: DEVOLUCIÓN MAGNÉTICA DETECTADA '
      '(${magnitude.toStringAsFixed(1)} µT).',
    );

    try {
      // Confirmación física inmediata.
      await HapticFeedback.heavyImpact();

      // Pequeña confirmación sonora del sistema.
      await SystemSound.play(
        SystemSoundType.click,
      );

      // Ejecuta el proceso real:
      //
      // - marcar LIBRE
      // - heartbeat inmediato
      // - cerrar visita
      // - enviar estadísticas
      // - reiniciar APK
      //
      await onReturnDetected();

      debugPrint(
        'GCenter: proceso de devolución '
        'magnética completado.',
      );
    } catch (e, stack) {
      debugPrint(
        'GCenter: error procesando devolución '
        'magnética: $e',
      );

      debugPrintStack(
        stackTrace: stack,
      );
    } finally {
      _processing = false;
    }
  }

  // ==========================================================
  // PARADA
  // ==========================================================

  Future<void> stop() async {
    await _subscription?.cancel();

    _subscription = null;

    debugPrint(
      'GCenter: detector magnético detenido.',
    );
  }

  Future<void> dispose() async {
    await stop();
  }
}