import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:stay_safe/core/theme/app_colors.dart';
import 'package:stay_safe/core/services/firestore_service.dart';
import 'package:stay_safe/core/services/location_service.dart';
import 'package:stay_safe/features/friends/providers/contacts_provider.dart';
import 'package:stay_safe/features/settings/providers/settings_provider.dart';

class WhereAreYouScreen extends ConsumerStatefulWidget {
  const WhereAreYouScreen({super.key});

  @override
  ConsumerState<WhereAreYouScreen> createState() => _WhereAreYouScreenState();
}

class _WhereAreYouScreenState extends ConsumerState<WhereAreYouScreen> {
  bool _isLoading = false;
  String? _selectedContactName;
  String? _myPhone;
  StreamSubscription<DocumentSnapshot>? _requestSub;

  @override
  void dispose() {
    _requestSub?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMyPhone());
  }

  Future<void> _loadMyPhone() async {
    final user = await ref.read(settingsRepositoryProvider).getUser();
    if (mounted && user != null) {
      setState(() => _myPhone = user['phone']);
    }
  }

  Widget _buildIncomingRequests() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService().listenToPendingRequests(_myPhone!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.sosRed.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.sosRed.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.notifications_active_outlined,
                      color: AppColors.sosRed, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${docs.length} incoming request${docs.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final from =
                    (data['requesterName'] as String?) ?? 'Someone';
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$from is asking for your location',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _respond(doc.id, status: 'declined'),
                        child: const Text(
                          'Decline',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 4),
                      ElevatedButton(
                        onPressed: () => _shareLocation(doc.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                        child: const Text(
                          'Share',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _shareLocation(String requestId) async {
    final position = await LocationService().getCurrentLocation();
    if (!mounted) return;

    if (position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not get your location'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    await _respond(
      requestId,
      status: 'accepted',
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  Future<void> _respond(
    String requestId, {
    required String status,
    double? latitude,
    double? longitude,
  }) async {
    try {
      await FirestoreService().respondToLocationRequest(
        requestId: requestId,
        status: status,
        latitude: latitude,
        longitude: longitude,
      );
      if (mounted && status == 'accepted') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your location was shared'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not respond: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(contactsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Where Are You'),
        backgroundColor: AppColors.secondary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.secondary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Select a friend to send a location request. They will receive a notification and can share their location with you.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_myPhone != null && _myPhone!.isNotEmpty) ...[
              _buildIncomingRequests(),
              const SizedBox(height: 24),
            ],
            const Text(
              'Select a Friend',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...contactsAsync.when(
              loading: () => const <Widget>[
                Center(child: CircularProgressIndicator()),
              ],
              error: (e, st) => <Widget>[
                Center(child: Text('Error: $e')),
              ],
              data: (contacts) {
                if (contacts.isEmpty) {
                  return <Widget>[
                    const Center(
                      child: Text(
                        'No contacts available.\nAdd friends in the Friends tab.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ];
                }

                return <Widget>[
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: contacts.length,
                    itemBuilder: (context, index) {
                      final contact = contacts[index];
                      final isSelected = _selectedContactName == contact.name;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedContactName = contact.name;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.secondary.withValues(alpha: 0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.secondary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.secondary
                                      : AppColors.secondary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.person,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.secondary,
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
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? AppColors.secondary
                                            : AppColors.textPrimary,
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
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: AppColors.secondary,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ];
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_isLoading || _selectedContactName == null)
                    ? null
                    : _sendLocationRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  disabledBackgroundColor: AppColors.textSecondary.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Send Location Request',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
    );
  }

  Future<void> _sendLocationRequest() async {
    if (_selectedContactName == null) return;

    setState(() => _isLoading = true);

    try {
      final settingsRepo = ref.read(settingsRepositoryProvider);
      final user = await settingsRepo.getUser();
      final userId = user?['id'] ?? '';
      final userName = user?['name'] ?? 'User';

      final contacts = ref.read(contactsProvider).value ?? [];
      final selectedContact = contacts.firstWhere(
        (c) => c.name == _selectedContactName,
      );

      final firestoreService = FirestoreService();
      final requestId = await firestoreService.createLocationRequest(
        requesterId: userId,
        requesterName: userName,
        targetUserId: selectedContact.phoneNumber,
        type: 'where_are_you',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location request sent to ${selectedContact.name}'),
            backgroundColor: AppColors.success,
          ),
        );
      }

      await _requestSub?.cancel();
      _requestSub = firestoreService
          .listenToLocationRequest(requestId)
          .listen((snapshot) {
        final data = snapshot.data() as Map<String, dynamic>?;
        if (data == null) return;

        final status = data['status'];
        if (status == 'accepted') {
          final lat = data['latitude'] as double?;
          final lng = data['longitude'] as double?;
          if (lat != null && lng != null && mounted) {
            _requestSub?.cancel();
            _requestSub = null;
            _showLocationResult(selectedContact.name, lat, lng);
          }
        } else if (status == 'declined') {
          _requestSub?.cancel();
          _requestSub = null;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${selectedContact.name} declined your request'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  void _showLocationResult(String name, double lat, double lng) {
    final locationService = LocationService();
    final mapsLink = locationService.getGoogleMapsLink(lat, lng);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$name\'s Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(mapsLink);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.map),
                label: const Text('Open in Google Maps'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
