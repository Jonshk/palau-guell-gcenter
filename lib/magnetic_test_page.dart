import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class MagneticTestPage extends StatefulWidget {
  const MagneticTestPage({super.key});

  @override
  State<MagneticTestPage> createState() => _MagneticTestPageState();
}

class _MagneticTestPageState extends State<MagneticTestPage> {
  StreamSubscription<MagnetometerEvent>? _subscription;

  double _x = 0;
  double _y = 0;
  double _z = 0;
  double _magnitude = 0;

  double _threshold = 150.0;

  bool _magnetDetected = false;

  DateTime? _aboveThresholdSince;
  DateTime? _lastTrigger;

  static const Duration minimumDetectionTime =
      Duration(milliseconds: 600);

  static const Duration triggerCooldown =
      Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _startSensor();
  }

  void _startSensor() {
    _subscription = magnetometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen(
      _onMagnetometer,
      onError: (error) {
        debugPrint('Magnetometer error: $error');
      },
    );
  }

  void _onMagnetometer(MagnetometerEvent event) {
    final magnitude = sqrt(
      event.x * event.x +
          event.y * event.y +
          event.z * event.z,
    );

    final now = DateTime.now();

    bool detected = false;

    if (magnitude >= _threshold) {
      _aboveThresholdSince ??= now;

      final elapsed = now.difference(_aboveThresholdSince!);

      if (elapsed >= minimumDetectionTime) {
        detected = true;

        final canTrigger =
            _lastTrigger == null ||
            now.difference(_lastTrigger!) >= triggerCooldown;

        if (canTrigger && !_magnetDetected) {
          _lastTrigger = now;
          _onMagneticTrigger(magnitude);
        }
      }
    } else {
      _aboveThresholdSince = null;
    }

    if (!mounted) return;

    setState(() {
      _x = event.x;
      _y = event.y;
      _z = event.z;
      _magnitude = magnitude;
      _magnetDetected = detected;
    });
  }

  void _onMagneticTrigger(double value) {
    debugPrint(
      'MAGNETIC TRIGGER: ${value.toStringAsFixed(1)} µT',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '✓ Imán detectado: ${value.toStringAsFixed(1)} µT',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prueba magnética GCenter'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Magnetómetro',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            Text(
              'X: ${_x.toStringAsFixed(1)} µT',
              style: const TextStyle(fontSize: 20),
            ),

            Text(
              'Y: ${_y.toStringAsFixed(1)} µT',
              style: const TextStyle(fontSize: 20),
            ),

            Text(
              'Z: ${_z.toStringAsFixed(1)} µT',
              style: const TextStyle(fontSize: 20),
            ),

            const SizedBox(height: 30),

            Text(
              '${_magnitude.toStringAsFixed(1)} µT',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  width: 2,
                  color: _magnetDetected
                      ? Colors.green
                      : Colors.grey,
                ),
              ),
              child: Text(
                _magnetDetected
                    ? '🧲 IMÁN DETECTADO'
                    : 'SIN IMÁN',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: _magnetDetected
                      ? Colors.green
                      : Colors.grey,
                ),
              ),
            ),

            const SizedBox(height: 40),

            Text(
              'Umbral: ${_threshold.toStringAsFixed(0)} µT',
              textAlign: TextAlign.center,
            ),

            Slider(
              value: _threshold,
              min: 50,
              max: 1000,
              divisions: 95,
              label: '${_threshold.toStringAsFixed(0)} µT',
              onChanged: (value) {
                setState(() {
                  _threshold = value;
                });
              },
            ),

            const SizedBox(height: 20),

            const Text(
              'Prueba:\n'
              '1. Mira el valor lejos de la alfombrilla.\n'
              '2. Acerca la parte trasera del móvil.\n'
              '3. Pásalo por diferentes zonas.\n'
              '4. Anota el pico máximo que aparece.',
            ),
          ],
        ),
      ),
    );
  }
}