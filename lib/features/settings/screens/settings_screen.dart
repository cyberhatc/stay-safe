import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stay_safe/core/theme/app_colors.dart';
import 'package:stay_safe/features/settings/providers/settings_provider.dart';
import 'package:stay_safe/features/settings/models/settings_model.dart';
import 'package:stay_safe/features/auth/providers/auth_provider.dart';
import 'package:stay_safe/features/auth/screens/onboarding_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emergency Services Section
            _SectionHeader(title: 'Emergency Services'),
            const SizedBox(height: 12),
            _SettingsCard(
              children: [
                _SettingsSwitch(
                  title: 'Emergency SOS',
                  subtitle: 'Send SMS and notifications when SOS is triggered',
                  value: settings.emergencyServices,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).toggleEmergencyServices();
                  },
                  icon: Icons.emergency_outlined,
                  iconColor: AppColors.sosRed,
                ),
                const Divider(height: 1),
                _SettingsSwitch(
                  title: 'Low Battery Alert',
                  subtitle: 'Auto-send location when battery is below 15%',
                  value: settings.lowBatteryAlert,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).toggleLowBatteryAlert();
                  },
                  icon: Icons.battery_alert_outlined,
                  iconColor: AppColors.warning,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Sound Section
            _SectionHeader(title: 'Sounds'),
            const SizedBox(height: 12),
            _SettingsCard(
              children: [
                _SettingsTile(
                  title: 'Scream Sound',
                  subtitle: settings.screamSound == 'police_siren.mp3'
                      ? 'Police Siren'
                      : 'Male Voice Scream',
                  icon: Icons.volume_up_outlined,
                  iconColor: AppColors.warning,
                  onTap: () => _showSoundPicker(context, ref, settings),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Fake Call Section
            _SectionHeader(title: 'Fake Call'),
            const SizedBox(height: 12),
            _SettingsCard(
              children: [
                _SettingsTile(
                  title: 'Default Timer',
                  subtitle: '${settings.fakeCallTimer} seconds',
                  icon: Icons.timer_outlined,
                  iconColor: AppColors.success,
                  onTap: () => _showTimerPicker(context, ref, settings),
                ),
                const Divider(height: 1),
                _SettingsTile(
                  title: 'Caller Name',
                  subtitle: settings.fakeCallCallerName,
                  icon: Icons.person_outline,
                  iconColor: AppColors.primary,
                  onTap: () => _showCallerNamePicker(context, ref, settings),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Account Section
            _SectionHeader(title: 'Account'),
            const SizedBox(height: 12),
            _SettingsCard(
              children: [
                _SettingsTile(
                  title: 'How it Works',
                  subtitle: 'View onboarding screens again',
                  icon: Icons.help_outline,
                  iconColor: AppColors.primaryLight,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const OnboardingScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                _SettingsTile(
                  title: 'Logout',
                  subtitle: 'Sign out of your account',
                  icon: Icons.logout,
                  iconColor: AppColors.sosRed,
                  onTap: () => _logout(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // App Info
            Center(
              child: Column(
                children: [
                  const Text(
                    'Stay Safe v1.0.0',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Your Safety, Our Priority',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showSoundPicker(BuildContext context, WidgetRef ref, AppSettings settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Scream Sound'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Male Voice Scream'),
              value: 'scream_male.mp3',
              groupValue: settings.screamSound,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setScreamSound(value);
                }
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('Police Siren'),
              value: 'police_siren.mp3',
              groupValue: settings.screamSound,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setScreamSound(value);
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTimerPicker(BuildContext context, WidgetRef ref, AppSettings settings) {
    final options = [3, 5, 10, 15, 30, 60];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fake Call Timer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((seconds) {
            return RadioListTile<int>(
              title: Text(seconds >= 60 ? '${seconds ~/ 60} minute' : '$seconds seconds'),
              value: seconds,
              groupValue: settings.fakeCallTimer,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setFakeCallTimer(value);
                }
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showCallerNamePicker(BuildContext context, WidgetRef ref, AppSettings settings) {
    final controller = TextEditingController(text: settings.fakeCallCallerName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Caller Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter caller name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).setFakeCallCallerName(
                    controller.text.trim(),
                  );
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _logout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: AppColors.sosRed),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData icon;
  final Color iconColor;

  const _SettingsSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.textSecondary,
      ),
      onTap: onTap,
    );
  }
}
