import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stay_safe/core/theme/app_colors.dart';
import 'package:stay_safe/features/scream_alarm/screens/scream_alarm_screen.dart';
import 'package:stay_safe/features/fake_call/screens/fake_call_setup_screen.dart';
import 'package:stay_safe/features/where_are_you/screens/where_are_you_screen.dart';
import 'package:stay_safe/features/track_me/screens/track_me_screen.dart';
import 'package:stay_safe/features/friends/screens/friends_screen.dart';
import 'package:stay_safe/features/settings/screens/settings_screen.dart';
import 'package:stay_safe/shared/widgets/feature_tile.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined, color: Colors.white),
            SizedBox(width: 8),
            Text('Stay Safe'),
          ],
        ),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.sosRed,
                      AppColors.sosRedDark,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.sosRed.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.emergency_outlined,
                        color: Colors.white,
                        size: 36,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'SOS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Tap the button below or shake your phone\nto trigger emergency SOS',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Features',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                FeatureTile(
                  icon: Icons.volume_up_outlined,
                  title: 'Scream\nAlarm',
                  color: AppColors.warning,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ScreamAlarmScreen()),
                    );
                  },
                ),
                FeatureTile(
                  icon: Icons.phone_outlined,
                  title: 'Fake\nCall',
                  color: AppColors.success,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const FakeCallSetupScreen()),
                    );
                  },
                ),
                FeatureTile(
                  icon: Icons.location_searching,
                  title: 'Where Are\nYou',
                  color: AppColors.secondary,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const WhereAreYouScreen()),
                    );
                  },
                ),
                FeatureTile(
                  icon: Icons.share_location,
                  title: 'Track\nMe',
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TrackMeScreen()),
                    );
                  },
                ),
                FeatureTile(
                  icon: Icons.people_outlined,
                  title: 'Friends\nList',
                  color: AppColors.primaryLight,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const FriendsScreen()),
                    );
                  },
                ),
                FeatureTile(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  color: AppColors.textSecondary,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
