import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stay_safe/core/services/firestore_service.dart';
import 'package:stay_safe/features/settings/providers/settings_provider.dart';

class AuthState {
  final bool isLoading;
  final bool isVerificationSent;
  final String? verificationId;
  final String? error;
  final String? userId;
  final bool isloggedIn;
  final int resendCooldown;

  AuthState({
    this.isLoading = false,
    this.isVerificationSent = false,
    this.verificationId,
    this.error,
    this.userId,
    this.isloggedIn = false,
    this.resendCooldown = 0,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isVerificationSent,
    String? verificationId,
    String? error,
    String? userId,
    bool? isloggedIn,
    int? resendCooldown,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isVerificationSent: isVerificationSent ?? this.isVerificationSent,
      verificationId: verificationId ?? this.verificationId,
      error: error,
      userId: userId ?? this.userId,
      isloggedIn: isloggedIn ?? this.isloggedIn,
      resendCooldown: resendCooldown ?? this.resendCooldown,
    );
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends Notifier<AuthState> {
  /// Demo code accepted when Firebase never hands us a verification id
  /// (phone auth disabled, no network, emulator, ...).
  static const String demoOtpCode = '123456';

  /// Resolved lazily so tests can subclass this notifier without a
  /// bootstrapped Firebase app.
  FirebaseAuth get _auth => FirebaseAuth.instance;

  Timer? _resendTimer;

  @override
  AuthState build() {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        return AuthState(userId: user.uid, isloggedIn: true);
      }
    } catch (_) {
      // Firebase is not bootstrapped (unit tests / early startup).
    }
    return AuthState();
  }

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required VoidCallback? onCodeSent,
  }) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      isVerificationSent: false,
    );

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          state = state.copyWith(isloggedIn: true, isLoading: false);
        },
        verificationFailed: (FirebaseAuthException e) {
          state = state.copyWith(
            isLoading: false,
            error: e.message ?? 'Verification failed. Please try again.',
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          state = state.copyWith(
            isLoading: false,
            isVerificationSent: true,
            verificationId: verificationId,
          );
          _startResendCooldown();
          onCodeSent?.call();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          state = state.copyWith(verificationId: verificationId);
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to send verification code. Please try again.',
      );
    }
  }

  Future<void> verifySmsCode({
    required String smsCode,
    required String name,
    required String phone,
    required String emergencyContactName,
    required String emergencyContactPhone,
  }) async {
    if (state.isLoading) {
      state = state.copyWith(
        error: 'Still sending the verification code. Please wait a moment.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    final verificationId = state.verificationId;

    if (verificationId == null) {
      // Firebase never issued a code (phone auth disabled / offline / demo).
      if (smsCode == demoOtpCode) {
        await _finishSignIn(userId: 'demo-user', name: name, phone: phone);
        return;
      }
      state = state.copyWith(
        isLoading: false,
        error:
            'We could not send an SMS to this number. Use the demo code $demoOtpCode to continue.',
      );
      return;
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final userId = userCredential.user?.uid;

      if (userId == null) {
        state = state.copyWith(isLoading: false, error: 'Failed to sign in');
        return;
      }

      await _finishSignIn(userId: userId, name: name, phone: phone);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message ?? 'Invalid verification code',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Verification failed. Please try again.',
      );
    }
  }

  Future<void> _finishSignIn({
    required String userId,
    required String name,
    required String phone,
  }) async {
    final settingsRepo = ref.read(settingsRepositoryProvider);

    var resolvedName = name.trim();
    var resolvedPhone = phone.trim();
    if (resolvedName.isEmpty || resolvedPhone.isEmpty) {
      final existing = await settingsRepo.getUser();
      if (resolvedName.isEmpty) resolvedName = existing?['name'] ?? '';
      if (resolvedPhone.isEmpty) resolvedPhone = existing?['phone'] ?? phone;
    }

    await settingsRepo.saveUser(userId, resolvedName, resolvedPhone);
    await settingsRepo.setFirstLaunch(false);

    try {
      final firestoreService = FirestoreService();
      final token = await firestoreService.getUserFcmToken(userId);
      await firestoreService.saveUser(
        userId: userId,
        name: resolvedName,
        phone: resolvedPhone,
        fcmToken: token ?? '',
      );
    } catch (_) {
      // Offline or demo user: the local profile is enough to use the app.
    }

    state = state.copyWith(
      isLoading: false,
      isloggedIn: true,
      userId: userId,
      error: null,
    );
  }

  void _startResendCooldown() {
    int cooldown = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      cooldown--;
      state = state.copyWith(resendCooldown: cooldown);
      if (cooldown <= 0) {
        timer.cancel();
      }
    });
  }

  Future<void> logout() async {
    await _auth.signOut();
    final settingsRepo = ref.read(settingsRepositoryProvider);
    await settingsRepo.clearUser();
    _resendTimer?.cancel();
    state = AuthState();
  }
}
