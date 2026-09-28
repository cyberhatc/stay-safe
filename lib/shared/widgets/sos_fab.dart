import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stay_safe/core/theme/app_colors.dart';
import 'package:stay_safe/features/sos/screens/sos_countdown_screen.dart';

class SosFab extends ConsumerWidget {
  const SosFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SosCountdownScreen()),
        );
      },
      backgroundColor: AppColors.sosRed,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.emergency, size: 28),
      label: const Text(
        'SOS',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevation: 8,
    );
  }
}
