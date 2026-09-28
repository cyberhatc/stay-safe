import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stay_safe/core/services/location_service.dart';
import 'package:stay_safe/core/services/sms_service.dart';
import 'package:stay_safe/core/services/notification_service.dart';
import 'package:stay_safe/core/services/permission_service.dart';
import 'package:stay_safe/core/services/firestore_service.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final smsServiceProvider = Provider<SmsService>((ref) {
  return SmsService();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService();
});

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});
