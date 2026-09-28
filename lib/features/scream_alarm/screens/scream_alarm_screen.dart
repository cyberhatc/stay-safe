import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:stay_safe/core/theme/app_colors.dart';
import 'package:stay_safe/features/settings/providers/settings_provider.dart';
import 'package:stay_safe/features/scream_alarm/providers/alarm_provider.dart';

class AlarmService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playAlarm(String soundFile) async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(1.0);
      await _player.play(AssetSource('sounds/$soundFile'));
    } catch (e) {
      // Silently handle if asset not found
    }
  }

  Future<void> stopAlarm() async {
    await _player.stop();
  }

  void dispose() {
    _player.dispose();
  }
}

final alarmServiceProvider = Provider<AlarmService>((ref) {
  return AlarmService();
});

class ScreamAlarmScreen extends ConsumerStatefulWidget {
  const ScreamAlarmScreen({super.key});

  @override
  ConsumerState<ScreamAlarmScreen> createState() => _ScreamAlarmScreenState();
}

class _ScreamAlarmScreenState extends ConsumerState<ScreamAlarmScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _toggleAlarm() async {
    final alarmService = ref.read(alarmServiceProvider);
    final settings = ref.read(settingsProvider);
    final isPlaying = ref.read(alarmStateProvider).isPlaying;

    if (isPlaying) {
      await alarmService.stopAlarm();
      ref.read(alarmStateProvider.notifier).setPlaying(false);
    } else {
      await alarmService.playAlarm(settings.screamSound);
      ref.read(alarmStateProvider.notifier).setPlaying(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = ref.watch(alarmStateProvider).isPlaying;

    return Scaffold(
      backgroundColor: isPlaying ? AppColors.sosRedDark : AppColors.background,
      appBar: AppBar(
        title: const Text('Scream Alarm'),
        backgroundColor: isPlaying ? AppColors.sosRedDark : AppColors.primary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: isPlaying ? _pulseAnimation.value : 1.0,
                  child: child,
                );
              },
              child: GestureDetector(
                onTap: _toggleAlarm,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isPlaying
                          ? [AppColors.sosRed, AppColors.sosRedDark]
                          : [AppColors.warning, const Color(0xFFE65100)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isPlaying ? AppColors.sosRed : AppColors.warning)
                            .withValues(alpha: 0.5),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isPlaying ? Icons.stop : Icons.volume_up,
                        color: Colors.white,
                        size: 64,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isPlaying ? 'STOP' : 'PLAY',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              isPlaying ? 'Alarm is playing!' : 'Tap to start alarm',
              style: TextStyle(
                fontSize: 18,
                color: isPlaying ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isPlaying
                  ? 'Press the button to stop'
                  : 'Plays at maximum volume in a loop',
              style: TextStyle(
                fontSize: 14,
                color: isPlaying ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
