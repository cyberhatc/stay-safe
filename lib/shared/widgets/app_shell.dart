import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stay_safe/core/services/battery_service.dart';
import 'package:stay_safe/features/home/screens/home_screen.dart';
import 'package:stay_safe/features/friends/screens/friends_screen.dart';
import 'package:stay_safe/features/sos/screens/sos_countdown_screen.dart';
import 'package:stay_safe/features/sos/services/shake_detection_service.dart';
import 'package:stay_safe/features/track_me/screens/tracking_screen.dart';
import 'package:stay_safe/features/settings/providers/settings_provider.dart';
import 'package:stay_safe/features/settings/screens/settings_screen.dart';
import 'package:stay_safe/shared/widgets/sos_fab.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 0;
  bool _sosOpen = false;
  final BatteryService _batteryService = BatteryService();

  final List<Widget> _screens = [
    const HomeScreen(),
    const FriendsScreen(),
    const TrackingScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ShakeDetectionService().startListening(onShake: _openSos);
      _syncBatteryMonitor();
    });
  }

  @override
  void dispose() {
    ShakeDetectionService().stopListening();
    _batteryService.stopMonitoring();
    super.dispose();
  }

  void _openSos() {
    if (_sosOpen || !mounted) return;
    _sosOpen = true;
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (_) => const SosCountdownScreen()),
        )
        .whenComplete(() => _sosOpen = false);
  }

  Future<void> _syncBatteryMonitor() async {
    final settings = ref.read(settingsProvider);
    final user = await ref.read(settingsRepositoryProvider).getUser();
    if (!mounted) return;
    _batteryService.startMonitoring(
      isEnabled: settings.lowBatteryAlert,
      userName: user?['name'] ?? 'User',
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(settingsProvider, (previous, next) {
      if (previous?.lowBatteryAlert != next.lowBatteryAlert) {
        _syncBatteryMonitor();
      }
    });

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: _currentIndex == 0 ? const SosFab() : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Friends',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            activeIcon: Icon(Icons.location_on),
            label: 'Tracking',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
