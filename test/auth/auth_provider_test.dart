import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stay_safe/features/auth/providers/auth_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  AuthNotifier notifier() => container.read(authProvider.notifier);
  AuthState state() => container.read(authProvider);

  test('builds an anonymous state when Firebase is unavailable', () {
    expect(state().isloggedIn, isFalse);
    expect(state().verificationId, isNull);
  });

  test('demo code signs the user in when no verification id exists', () async {
    await notifier().verifySmsCode(
      smsCode: AuthNotifier.demoOtpCode,
      name: 'Priya',
      phone: '+918971845909',
      emergencyContactName: 'Mom',
      emergencyContactPhone: '+919999999999',
    );

    expect(state().isloggedIn, isTrue);
    expect(state().userId, 'demo-user');
    expect(state().error, isNull);
    expect(state().isLoading, isFalse);
  });

  test(
    'a wrong code without a verification id returns a helpful error',
    () async {
      await notifier().verifySmsCode(
        smsCode: '999999',
        name: 'Priya',
        phone: '+918971845909',
        emergencyContactName: 'Mom',
        emergencyContactPhone: '+919999999999',
      );

      expect(state().isloggedIn, isFalse);
      expect(state().error, contains(AuthNotifier.demoOtpCode));
    },
  );

  test('verifyPhoneNumber fails gracefully without Firebase', () async {
    await notifier().verifyPhoneNumber(
      phoneNumber: '+918971845909',
      onCodeSent: null,
    );

    expect(state().isLoading, isFalse);
    expect(state().isVerificationSent, isFalse);
    expect(state().error, isNotNull);
  });

  test('verifySmsCode refuses while the code is still being sent', () async {
    final gate = Completer<void>();
    final slow = ProviderContainer(
      overrides: [authProvider.overrideWith(() => _SlowAuthNotifier(gate))],
    );
    addTearDown(slow.dispose);

    final slowNotifier = slow.read(authProvider.notifier);
    final sending = slowNotifier.verifyPhoneNumber(
      phoneNumber: '+918971845909',
      onCodeSent: null,
    );
    expect(slow.read(authProvider).isLoading, isTrue);

    await slowNotifier.verifySmsCode(
      smsCode: AuthNotifier.demoOtpCode,
      name: 'Priya',
      phone: '+918971845909',
      emergencyContactName: '',
      emergencyContactPhone: '',
    );

    expect(slow.read(authProvider).error, contains('Still sending'));
    expect(slow.read(authProvider).isloggedIn, isFalse);

    gate.complete();
    await sending;
  });
}

class _SlowAuthNotifier extends AuthNotifier {
  _SlowAuthNotifier(this._gate);

  final Completer<void> _gate;

  @override
  AuthState build() => AuthState();

  @override
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required VoidCallback? onCodeSent,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    await _gate.future;
    state = state.copyWith(isLoading: false, error: 'Timed out');
  }
}
