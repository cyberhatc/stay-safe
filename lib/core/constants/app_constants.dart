class AppConstants {
  static const String appName = 'Stay Safe';
  static const String appNameTagline = 'Your Safety, Our Priority';

  static const int sosCountdownSeconds = 5;
  static const double shakeThreshold = 25.0;
  static const int shakeCooldownMs = 10000;

  static const String defaultScreamSound = 'scream_male.mp3';
  static const String policeSirenSound = 'police_siren.mp3';
  static const String alarmSound = 'alarm_loop.mp3';

  static const int lowBatteryThreshold = 15;

  static const String defaultCallerName = 'Mom';
  static const int defaultFakeCallTimerSeconds = 10;

  static const String googleMapsBaseUrl = 'https://www.google.com/maps?q=';

  static const String dbName = 'stay_safe.db';
  static const int dbVersion = 1;

  static const String contactsTable = 'contacts';
  static const String settingsTable = 'settings';
  static const String locationRequestsTable = 'location_requests';
  static const String trackingSessionsTable = 'tracking_sessions';
}
