import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:stay_safe/firebase_options.dart';
import 'package:stay_safe/core/theme/app_theme.dart';
import 'package:stay_safe/core/services/notification_service.dart';
import 'package:stay_safe/features/settings/providers/settings_provider.dart';
import 'package:stay_safe/features/auth/providers/auth_provider.dart';
import 'package:stay_safe/features/auth/screens/onboarding_screen.dart';
import 'package:stay_safe/features/auth/screens/login_screen.dart';
import 'package:stay_safe/shared/widgets/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService.initialize();
  runApp(const ProviderScope(child: StaySafeApp()));
}

class StaySafeApp extends ConsumerWidget {
  const StaySafeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Stay Safe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final settings = ref.watch(settingsProvider);

    if (settings.isFirstLaunch) {
      return const OnboardingScreen();
    }

    if (authState.isloggedIn) {
      return const AppShell();
    }

    return const LoginScreen();
  }
}
