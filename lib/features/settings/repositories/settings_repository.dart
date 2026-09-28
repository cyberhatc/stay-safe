import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stay_safe/features/settings/models/settings_model.dart';

class SettingsRepository {
  static const String _settingsKey = 'app_settings';
  static const String _userKey = 'user_data';

  Future<AppSettings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_settingsKey);
    if (jsonString == null) return AppSettings.defaults();
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    return AppSettings.fromMap(map);
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(settings.toMap());
    await prefs.setString(_settingsKey, jsonString);
  }

  Future<void> updateSetting<T>(SettingsKey key, T value) async {
    final settings = await getSettings();
    final map = settings.toMap();
    map[key.value] = value;
    final updated = AppSettings.fromMap(map);
    await saveSettings(updated);
  }

  Future<void> saveUser(String userId, String name, String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode({
      'id': userId,
      'name': name,
      'phone': phone,
    }));
  }

  Future<Map<String, String>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_userKey);
    if (jsonString == null) return null;
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    return {
      'id': map['id'] as String,
      'name': map['name'] as String,
      'phone': map['phone'] as String,
    };
  }

  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  Future<bool> isLoggedIn() async {
    final user = await getUser();
    return user != null;
  }

  Future<void> setFirstLaunch(bool isFirst) async {
    final settings = await getSettings();
    settings.isFirstLaunch = isFirst;
    await saveSettings(settings);
  }
}
