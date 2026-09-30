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

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Timer? _resendTimer;

  @override
  AuthState build() {
    final user = _auth.currentUser;
    if (user != null) {
      return AuthState(userId: user.uid, isloggedIn: true);
    }
    return AuthState();
  }

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required VoidCallback? onCodeSent,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

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
    if (state.verificationId == null) {
      state = state.copyWith(error: 'No verification ID found');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: state.verificationId!,
        smsCode: smsCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final userId = userCredential.user?.uid;

      if (userId == null) {
        state = state.copyWith(isLoading: false, error: 'Failed to sign in');
        return;
      }

      final settingsRepo = ref.read(settingsRepositoryProvider);
      await settingsRepo.saveUser(userId, name, phone);
      await settingsRepo.setFirstLaunch(false);

      final firestoreService = FirestoreService();
      final token = await firestoreService.getUserFcmToken(userId);
      await firestoreService.saveUser(
        userId: userId,
        name: name,
        phone: phone,
        fcmToken: token ?? '',
      );

      state = state.copyWith(
        isLoading: false,
        isloggedIn: true,
        userId: userId,
      );
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
