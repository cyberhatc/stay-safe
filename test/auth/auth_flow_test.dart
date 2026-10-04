import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stay_safe/features/auth/providers/auth_provider.dart';
import 'package:stay_safe/features/auth/screens/login_screen.dart';
import 'package:stay_safe/features/auth/screens/otp_screen.dart';
import 'package:stay_safe/features/auth/screens/register_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<ProviderContainer> pumpRoute(
    WidgetTester tester,
    Widget screen,
  ) async {
    await tester.pumpWidget(ProviderScope(child: MaterialApp(home: screen)));
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
  }

  Future<void> settleSnackbars(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
  }

  testWidgets('Send OTP always opens the OTP screen with the 6 code boxes, '
      'even when Firebase cannot deliver an SMS', (tester) async {
    await pumpRoute(tester, const LoginScreen());

    await tester.enterText(find.byType(TextFormField).first, '8971845909');
    await tester.tap(find.text('Send OTP'));
    await tester.pumpAndSettle();

    expect(find.byType(OtpScreen), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(6));
    expect(find.text('Verify'), findsOneWidget);
    expect(find.textContaining('demo code 123456'), findsOneWidget);

    await settleSnackbars(tester);
  });

  testWidgets('Register also opens the OTP screen with the code boxes', (
    tester,
  ) async {
    await pumpRoute(tester, const RegisterScreen());

    await tester.enterText(find.byType(TextFormField).at(0), 'Priya');
    await tester.enterText(find.byType(TextFormField).at(1), '8971845909');
    await tester.enterText(find.byType(TextFormField).at(2), 'Mom');
    await tester.enterText(find.byType(TextFormField).at(3), '9876543210');
    await tester.ensureVisible(find.text('Register & Verify'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Register & Verify'));
    await tester.pumpAndSettle();

    expect(find.byType(OtpScreen), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(6));
    expect(find.textContaining('+918971845909'), findsWidgets);

    await settleSnackbars(tester);
  });

  testWidgets(
    'OTP screen shows six boxes and the demo code signs the user in',
    (tester) async {
      await pumpRoute(
        tester,
        const OtpScreen(
          phoneNumber: '+918971845909',
          name: 'Priya',
          emergencyContactName: 'Mom',
          emergencyContactPhone: '+919999999999',
        ),
      );

      expect(find.byType(TextField), findsNWidgets(6));
      expect(find.text('Verification Code'), findsOneWidget);

      for (var i = 0; i < 6; i++) {
        await tester.enterText(find.byType(TextField).at(i), '123456'[i]);
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(OtpScreen)),
      );
      expect(container.read(authProvider).isloggedIn, isTrue);
      expect(container.read(authProvider).userId, 'demo-user');
    },
  );

  testWidgets('Verify with an incomplete code shows a prompt', (tester) async {
    await pumpRoute(
      tester,
      const OtpScreen(
        phoneNumber: '+918971845909',
        name: 'Priya',
        emergencyContactName: 'Mom',
        emergencyContactPhone: '+919999999999',
      ),
    );

    await tester.enterText(find.byType(TextField).at(0), '1');
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('Verify'));
    await tester.pump();

    expect(find.text('Please enter the complete 6-digit code'), findsOneWidget);

    await settleSnackbars(tester);
  });
}
