import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stay_safe/features/settings/models/settings_model.dart';
import 'package:stay_safe/features/settings/repositories/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    _loadSettings();
    return AppSettings.defaults();
  }

  SettingsRepository get _repo => ref.read(settingsRepositoryProvider);

  Future<void> _loadSettings() async {
    state = await _repo.getSettings();
  }

  Future<void> updateSetting<T>(SettingsKey key, T value) async {
    await _repo.updateSetting(key, value);
    state = await _repo.getSettings();
  }

  Future<void> toggleEmergencyServices() async {
    await updateSetting(SettingsKey.emergencyServices, !state.emergencyServices);
  }

  Future<void> toggleLowBatteryAlert() async {
    await updateSetting(SettingsKey.lowBatteryAlert, !state.lowBatteryAlert);
  }

  Future<void> setScreamSound(String sound) async {
    await updateSetting(SettingsKey.screamSound, sound);
  }

  Future<void> setFakeCallTimer(int seconds) async {
    await updateSetting(SettingsKey.fakeCallTimer, seconds);
  }

  Future<void> setFakeCallCallerName(String name) async {
    await updateSetting(SettingsKey.fakeCallCallerName, name);
  }

  Future<void> completeOnboarding() async {
    await updateSetting(SettingsKey.isFirstLaunch, false);
  }
}
