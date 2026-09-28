import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:stay_safe/core/theme/app_colors.dart';
import 'package:stay_safe/core/services/location_service.dart';
import 'package:stay_safe/core/services/firestore_service.dart';
import 'package:stay_safe/features/friends/providers/contacts_provider.dart';
import 'package:stay_safe/features/settings/providers/settings_provider.dart';
import 'package:stay_safe/features/friends/models/contact_model.dart';

class TrackMeScreen extends ConsumerStatefulWidget {
  const TrackMeScreen({super.key});

  @override
  ConsumerState<TrackMeScreen> createState() => _TrackMeScreenState();
}

class _TrackMeScreenState extends ConsumerState<TrackMeScreen> {
  bool _isTracking = false;
  String? _activeSessionId;
  StreamSubscription<Position>? _locationSubscription;

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(contactsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Track Me'),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isTracking
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _isTracking ? Icons.location_on : Icons.info_outline,
                    color: _isTracking ? AppColors.success : AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isTracking
                          ? 'Your location is being shared. Tap below to stop.'
                          : 'Share your real-time location with trusted contacts. They can see your movement on a map.',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (!_isTracking) ...[
              const Text(
                'Select who to share with',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: contactsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text('Error: $e')),
                  data: (contacts) {
                    if (contacts.isEmpty) {
                      return const Center(
                        child: Text(
                          'No contacts available.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: contacts.length,
                      itemBuilder: (context, index) {
                        final contact = contacts[index];
                        return _ContactTrackingCard(
                          contact: contact,
                          onTrack: () => _startTracking(contact),
                        );
                      },
                    );
                  },
                ),
              ),
            ] else ...[
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.success.withValues(alpha: 0.1),
                        border: Border.all(
                          color: AppColors.success,
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: AppColors.success,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Location Sharing Active',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your contacts can see your real-time location',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _stopTracking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sosRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Stop Sharing',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _startTracking(Contact contact) async {
    final locationService = LocationService();
    final hasPermission = await locationService.checkAndRequestPermission();

    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission is required for tracking'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    setState(() => _isTracking = true);

    final settingsRepo = ref.read(settingsRepositoryProvider);
    final user = await settingsRepo.getUser();
    final userId = user?['id'] ?? '';

    final firestoreService = FirestoreService();
    final sessionId = await firestoreService.startTrackingSession(
      requesterId: userId,
      targetUserId: contact.phoneNumber,
      targetUserName: contact.name,
    );

    setState(() => _activeSessionId = sessionId);

    _locationSubscription = locationService.getLocationStream().listen(
      (position) async {
        await firestoreService.updateTrackingLocation(
          sessionId: sessionId,
          latitude: position.latitude,
          longitude: position.longitude,
        );
      },
    );
  }

  void _stopTracking() async {
    _locationSubscription?.cancel();

    if (_activeSessionId != null) {
      final firestoreService = FirestoreService();
      await firestoreService.stopTrackingSession(_activeSessionId!);
    }

    setState(() {
      _isTracking = false;
      _activeSessionId = null;
    });
  }
}

class _ContactTrackingCard extends StatelessWidget {
  final Contact contact;
  final VoidCallback onTrack;

  const _ContactTrackingCard({
    required this.contact,
    required this.onTrack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  contact.displayPhone,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onTrack,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text(
              'Track',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
