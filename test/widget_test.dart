import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stay_safe/features/settings/models/settings_model.dart';
import 'package:stay_safe/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App launches into onboarding for first-time users', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: StaySafeApp()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Stay Safe'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('App launches into login once onboarding is completed', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'app_settings': jsonEncode(AppSettings(isFirstLaunch: false).toMap()),
    });

    await tester.pumpWidget(const ProviderScope(child: StaySafeApp()));
    await tester.pumpAndSettle();

    expect(find.text('Stay Safe'), findsOneWidget);
    expect(find.text('Send OTP'), findsOneWidget);
    expect(find.text('Phone Number'), findsOneWidget);
  });
}
