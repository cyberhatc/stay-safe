import 'package:stay_safe/core/constants/app_constants.dart';

enum SettingsKey {
  emergencyServices,
  lowBatteryAlert,
  screamSound,
  fakeCallTimer,
  fakeCallCallerName,
  isFirstLaunch,
  userId,
  userName,
  userPhone,
  fcmToken,
}

extension SettingsKeyExtension on SettingsKey {
  String get value {
    switch (this) {
      case SettingsKey.emergencyServices:
        return 'emergency_services';
      case SettingsKey.lowBatteryAlert:
        return 'low_battery_alert';
      case SettingsKey.screamSound:
        return 'scream_sound';
      case SettingsKey.fakeCallTimer:
        return 'fake_call_timer';
      case SettingsKey.fakeCallCallerName:
        return 'fake_call_caller_name';
      case SettingsKey.isFirstLaunch:
        return 'is_first_launch';
      case SettingsKey.userId:
        return 'user_id';
      case SettingsKey.userName:
        return 'user_name';
      case SettingsKey.userPhone:
        return 'user_phone';
      case SettingsKey.fcmToken:
        return 'fcm_token';
    }
  }
}

class AppSettings {
  bool emergencyServices;
  bool lowBatteryAlert;
  String screamSound;
  int fakeCallTimer;
  String fakeCallCallerName;
  bool isFirstLaunch;

  AppSettings({
    this.emergencyServices = true,
    this.lowBatteryAlert = true,
    this.screamSound = AppConstants.defaultScreamSound,
    this.fakeCallTimer = AppConstants.defaultFakeCallTimerSeconds,
    this.fakeCallCallerName = AppConstants.defaultCallerName,
    this.isFirstLaunch = true,
  });

  factory AppSettings.defaults() => AppSettings();

  Map<String, dynamic> toMap() => {
        SettingsKey.emergencyServices.value: emergencyServices,
        SettingsKey.lowBatteryAlert.value: lowBatteryAlert,
        SettingsKey.screamSound.value: screamSound,
        SettingsKey.fakeCallTimer.value: fakeCallTimer,
        SettingsKey.fakeCallCallerName.value: fakeCallCallerName,
        SettingsKey.isFirstLaunch.value: isFirstLaunch,
      };

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      emergencyServices: map[SettingsKey.emergencyServices.value] ?? true,
      lowBatteryAlert: map[SettingsKey.lowBatteryAlert.value] ?? true,
      screamSound: map[SettingsKey.screamSound.value] ?? AppConstants.defaultScreamSound,
      fakeCallTimer: map[SettingsKey.fakeCallTimer.value] ?? AppConstants.defaultFakeCallTimerSeconds,
      fakeCallCallerName: map[SettingsKey.fakeCallCallerName.value] ?? AppConstants.defaultCallerName,
      isFirstLaunch: map[SettingsKey.isFirstLaunch.value] ?? true,
    );
  }
}
