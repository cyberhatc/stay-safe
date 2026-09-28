import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:stay_safe/core/constants/app_constants.dart';
import 'package:stay_safe/core/services/location_service.dart';
import 'package:stay_safe/core/services/sms_service.dart';
import 'package:stay_safe/core/services/notification_service.dart';
import 'package:stay_safe/features/friends/repositories/contact_repository.dart';

class BatteryService {
  final Battery _battery = Battery();
  Timer? _batteryCheckTimer;
  bool _hasAlerted = false;

  void startMonitoring({
    required bool isEnabled,
    required String userName,
  }) {
    _batteryCheckTimer?.cancel();
    if (!isEnabled) return;

    _batteryCheckTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _checkBattery(userName),
    );
  }

  void stopMonitoring() {
    _batteryCheckTimer?.cancel();
    _hasAlerted = false;
  }

  Future<void> _checkBattery(String userName) async {
    try {
      final level = await _battery.batteryLevel;
      if (level <= AppConstants.lowBatteryThreshold && !_hasAlerted) {
        _hasAlerted = true;
        await _sendLowBatteryAlert(userName);
      }
      if (level > AppConstants.lowBatteryThreshold) {
        _hasAlerted = false;
      }
    } catch (e) {
      // Silently handle battery check errors
    }
  }

  Future<void> _sendLowBatteryAlert(String userName) async {
    try {
      final locationService = LocationService();
      final position = await locationService.getCurrentLocation();

      if (position == null) return;

      final contactRepo = ContactRepository();
      final contacts = await contactRepo.getEmergencyContacts();

      if (contacts.isEmpty) return;

      final smsService = SmsService();
      await smsService.sendEmergencySms(
        contacts: contacts,
        userName: userName,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      await NotificationService.showNotification(
        title: 'Low Battery Alert',
        body: 'Your battery is low. Emergency contacts have been notified with your location.',
      );
    } catch (e) {
      // Silently handle alert errors
    }
  }
}
