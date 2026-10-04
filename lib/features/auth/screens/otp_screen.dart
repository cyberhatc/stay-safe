import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stay_safe/core/theme/app_colors.dart';
import 'package:stay_safe/features/auth/providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  final String name;
  final String emergencyContactName;
  final String emergencyContactPhone;

  const OtpScreen({
    super.key,
    required this.phoneNumber,
    required this.name,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
  });

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  int _focusedIndex = 0;
  bool _isLoading = false;
  bool _focusRequested = false;

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < _focusNodes.length; i++) {
      _focusNodes[i].addListener(() {
        if (_focusNodes[i].hasFocus && _focusedIndex != i) {
          setState(() => _focusedIndex = i);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _focusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  bool get _isComplete => _otpCode.length == 6;

  Future<void> _verifyOtp() async {
    if (!_isComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the complete 6-digit code')),
      );
      return;
    }

    setState(() => _isLoading = true);

    await ref
        .read(authProvider.notifier)
        .verifySmsCode(
          smsCode: _otpCode,
          name: widget.name,
          phone: widget.phoneNumber,
          emergencyContactName: widget.emergencyContactName,
          emergencyContactPhone: widget.emergencyContactPhone,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    final authState = ref.read(authProvider);
    if (authState.isloggedIn) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (authState.error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(authState.error!)));
    }
  }

  Future<void> _resendCode() async {
    await ref
        .read(authProvider.notifier)
        .verifyPhoneNumber(
          phoneNumber: widget.phoneNumber,
          onCodeSent: () {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Verification code resent')),
            );
          },
        );
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
    if (_isComplete) {
      _verifyOtp();
    }
  }

  Future<void> _pasteCode() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final digits = (data?.text ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (!mounted) return;
    if (digits.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No 6-digit code found in clipboard')),
      );
      return;
    }
    for (var i = 0; i < 6; i++) {
      _controllers[i].text = digits[i];
    }
    setState(() {});
    _verifyOtp();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    final isSending = authState.isLoading && !authState.isVerificationSent;
    final isSent = authState.isVerificationSent;
    final codeReady = !isSending;

    ref.listen(authProvider, (previous, next) {
      if (!next.isloggedIn || previous?.isloggedIn == true) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).popUntil((route) => route.isFirst);
      });
    });

    if (codeReady && !_focusRequested) {
      _focusRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNodes[0].requestFocus();
      });
    }

    final busy = _isLoading || authState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHero(),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildStatusBanner(isSending, isSent),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) {
                        return _OtpBox(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          focused:
                              _focusedIndex == index &&
                              _focusNodes[index].hasFocus,
                          onChanged: (value) => _onChanged(value, index),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: busy ? null : _pasteCode,
                      icon: const Icon(Icons.content_paste_rounded, size: 18),
                      label: const Text('Paste code from clipboard'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: busy ? null : _verifyOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: busy
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.lock_open_outlined,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Verify',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: busy || authState.resendCooldown > 0
                          ? null
                          : _resendCode,
                      child: Text(
                        authState.resendCooldown > 0
                            ? 'Resend code in ${authState.resendCooldown}s'
                            : 'Didn\'t get the code? Resend',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: authState.resendCooldown > 0
                              ? AppColors.textSecondary
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner(bool isSending, bool isSent) {
    final IconData icon;
    final Color color;
    final String text;

    if (isSending) {
      icon = Icons.hourglass_top_rounded;
      color = AppColors.primary;
      text = 'Sending verification code to ${widget.phoneNumber}…';
    } else if (isSent) {
      icon = Icons.check_circle_rounded;
      color = AppColors.success;
      text = 'Code sent to ${widget.phoneNumber}';
    } else {
      icon = Icons.vpn_key_rounded;
      color = AppColors.warning;
      text = 'SMS unavailable - use the demo code ${AuthNotifier.demoOtpCode}';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 24, 34),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
            AppColors.primaryLight,
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const Expanded(
                child: Text(
                  'Verify Phone',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
            ),
            child: const Icon(
              Icons.sms_outlined,
              size: 42,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Verification Code',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Enter the 6-digit code sent to\n${widget.phoneNumber}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool focused;
  final ValueChanged<String> onChanged;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.focused,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 48,
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: focused ? AppColors.primary : AppColors.primaryLight,
          width: focused ? 2.2 : 1.4,
        ),
        boxShadow: focused
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : const [],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        decoration: const InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
        ),
        onChanged: onChanged,
      ),
    );
  }
}
