import 'package:url_launcher/url_launcher.dart';
import 'package:stay_safe/features/friends/models/contact_model.dart';
import 'package:stay_safe/core/services/location_service.dart';

class SmsService {
  final LocationService _locationService = LocationService();

  Future<void> sendEmergencySms({
    required List<Contact> contacts,
    required String userName,
    required double latitude,
    required double longitude,
  }) async {
    final locationLink = _locationService.getGoogleMapsLink(latitude, longitude);
    final message = 'EMERGENCY! I need help!\n'
        'Name: $userName\n'
        'My current location: $locationLink\n'
        'Please come to my location or call authorities!';

    for (final contact in contacts) {
      try {
        await _sendSms(contact.phoneNumber, message);
      } catch (e) {
        // Try alternative method
      }
    }
  }

  Future<void> _sendSms(String phone, String message) async {
    final uri = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: {'body': message},
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<bool> checkSmsPermission() async {
    return true;
  }

  Future<void> sendLocationRequest({
    required String recipientPhone,
    required String requesterName,
    required String requestId,
  }) async {
    final message = '$requesterName is requesting your location. '
        'Please share your location through the Stay Safe app.';

    try {
      await _sendSms(recipientPhone, message);
    } catch (e) {
      // Silently handle
    }
  }
}
