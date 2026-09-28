import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stay_safe/core/theme/app_colors.dart';
import 'package:stay_safe/core/services/location_service.dart';
import 'package:stay_safe/core/services/sms_service.dart';
import 'package:stay_safe/core/services/notification_service.dart';
import 'package:stay_safe/features/friends/providers/contacts_provider.dart';
import 'package:stay_safe/features/settings/providers/settings_provider.dart';

class SosCountdownScreen extends ConsumerStatefulWidget {
  const SosCountdownScreen({super.key});

  @override
  ConsumerState<SosCountdownScreen> createState() => _SosCountdownScreenState();
}

class _SosCountdownScreenState extends ConsumerState<SosCountdownScreen>
    with SingleTickerProviderStateMixin {
  int _countdown = 5;
  Timer? _timer;
  bool _isTriggered = false;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _countdown--;
      });

      if (_countdown <= 0) {
        timer.cancel();
        _triggerSos();
      }
    });
  }

  void _cancelSos() {
    _timer?.cancel();
    Navigator.of(context).pop();
  }

  Future<void> _triggerSos() async {
    if (_isTriggered) return;
    _isTriggered = true;

    final settings = ref.read(settingsProvider);
    if (!settings.emergencyServices) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency Services is OFF. Enable it in Settings.'),
            backgroundColor: AppColors.error,
          ),
        );
        Navigator.of(context).pop();
      }
      return;
    }

    final contactsAsync = ref.read(contactsProvider);
    final contacts = contactsAsync.value ?? [];

    if (contacts.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No emergency contacts. Add contacts in Friends List.'),
            backgroundColor: AppColors.error,
          ),
        );
        Navigator.of(context).pop();
      }
      return;
    }

    final locationService = LocationService();
    final position = await locationService.getCurrentLocation();

    if (position == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not get location. Please enable GPS.'),
            backgroundColor: AppColors.error,
          ),
        );
        Navigator.of(context).pop();
      }
      return;
    }

    final smsService = SmsService();
    final settingsRepo = ref.read(settingsRepositoryProvider);
    final user = await settingsRepo.getUser();
    final userName = user?['name'] ?? 'User';

    await smsService.sendEmergencySms(
      contacts: contacts,
      userName: userName,
      latitude: position.latitude,
      longitude: position.longitude,
    );

    final locationLink = locationService.getGoogleMapsLink(
      position.latitude,
      position.longitude,
    );

    await NotificationService.showSosNotification(
      userName: userName,
      locationLink: locationLink,
    );

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          icon: const Icon(
            Icons.check_circle_outline,
            color: AppColors.success,
            size: 64,
          ),
          title: const Text(
            'SOS Sent!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Emergency messages have been sent to ${contacts.length} contact(s) with your location.',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sosRedDark,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: child,
                );
              },
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 4,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$_countdown',
                    style: const TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'EMERGENCY SOS',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Sending emergency alert in $_countdown seconds...',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(32),
              child: SizedBox(
                width: double.infinity,
                height: 72,
                child: ElevatedButton(
                  onPressed: _cancelSos,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.sosRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 8,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.close, size: 32),
                      SizedBox(width: 12),
                      Text(
                        'CANCEL SOS',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
