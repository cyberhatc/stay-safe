import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:stay_safe/core/constants/app_constants.dart';

class ShakeDetectionService {
  static ShakeDetectionService? _instance;
  factory ShakeDetectionService() => _instance ??= ShakeDetectionService._();
  ShakeDetectionService._();

  StreamSubscription<AccelerometerEvent>? _subscription;
  DateTime? _lastShakeTime;
  bool _isListening = false;
  Function()? _onShake;

  bool get isListening => _isListening;

  void startListening({required Function() onShake}) {
    if (_isListening) return;

    _onShake = onShake;
    _isListening = true;

    _subscription = accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen((event) {
      final acceleration = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      if (acceleration > AppConstants.shakeThreshold) {
        final now = DateTime.now();
        if (_lastShakeTime == null ||
            now.difference(_lastShakeTime!).inMilliseconds >
                AppConstants.shakeCooldownMs) {
          _lastShakeTime = now;
          _onShake?.call();
        }
      }
    });
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _isListening = false;
    _onShake = null;
  }
}
