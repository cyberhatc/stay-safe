import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._();
  factory PermissionService() => _instance;
  PermissionService._();

  Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    final permissions = [
      Permission.location,
      Permission.locationAlways,
      Permission.contacts,
      Permission.sms,
      Permission.notification,
      Permission.phone,
    ];

    final statuses = await permissions.request();
    return statuses;
  }

  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    return status.isGranted;
  }

  Future<bool> requestBackgroundLocationPermission() async {
    final status = await Permission.locationAlways.request();
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    return status.isGranted;
  }

  Future<bool> requestContactsPermission() async {
    final status = await Permission.contacts.request();
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    return status.isGranted;
  }

  Future<bool> requestSmsPermission() async {
    final status = await Permission.sms.request();
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    return status.isGranted;
  }

  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    return status.isGranted;
  }

  Future<bool> requestPhonePermission() async {
    final status = await Permission.phone.request();
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    return status.isGranted;
  }

  Future<bool> isLocationGranted() async => await Permission.location.isGranted;
  Future<bool> isContactsGranted() async => await Permission.contacts.isGranted;
  Future<bool> isSmsGranted() async => await Permission.sms.isGranted;
  Future<bool> isNotificationGranted() async => await Permission.notification.isGranted;

  Future<void> openAppSettingsPage() async {
    await openAppSettings();
  }
}
