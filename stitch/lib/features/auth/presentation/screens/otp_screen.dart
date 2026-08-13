/// OTP verification screen — supports email verification after registration.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/sidad_button.dart';
import '../providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String contact; // email or phone
  const OtpScreen({super.key, required this.contact});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _ctrls = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _nodes = List.generate(4, (_) => FocusNode());
  Timer? _timer;
  int _cd = 60;
  bool _canResend = false;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _cd = 60;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_cd > 0) {
        setState(() => _cd--);
      } else {
        setState(() => _canResend = true);
        t.cancel();
      }
    });
  }

  String get _otp => _ctrls.map((c) => c.text).join();

  void _verify() async {
    if (_otp.length == 4 && !_isVerifying) {
      _isVerifying = true;
      await ref.read(authProvider.notifier).verifyOtp(widget.contact, _otp);
      if (mounted) {
        final state = ref.read(authProvider);
        if (state.status == AuthStatus.authenticated &&
            !state.requiresVerification) {
          context.go('/role-selection');
        } else {
          // Reset on error
          _isVerifying = false;
        }
      }
    }
  }

  void _resend() {
    ref.read(authProvider.notifier).sendOtp(widget.contact);
    _startTimer();
    // Clear OTP fields
    for (final c in _ctrls) {
      c.clear();
    }
    _nodes[0].requestFocus();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final f in _nodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
          ),
        );
        ref.read(authProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.pageHorizontal,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // ── Icon ──────────────────────────────────────────
              Center(
                child:
                    Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: AppColors.primaryFixed.withValues(
                              alpha: 0.3,
                            ),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Icon(
                            Icons.mark_email_read_rounded,
                            size: 36,
                            color: AppColors.primary,
                          ),
                        )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .scale(
                          duration: 700.ms,
                          curve: Curves.elasticOut,
                          begin: const Offset(0.5, 0.5),
                        ),
              ),
              const SizedBox(height: 24),

              // ── Title ─────────────────────────────────────────
              Center(
                child: Text(
                  AppStrings.otpTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),
              const SizedBox(height: 8),

              Center(
                    child: Text(
                      'أدخل الرمز المرسل إلى بريدك الإلكتروني',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  )
                  .animate(delay: 100.ms)
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.1),
              const SizedBox(height: 4),

              Center(
                child: Text(
                  widget.contact,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Roboto',
                  ),
                  textDirection: TextDirection.ltr,
                ),
              ).animate(delay: 150.ms).fadeIn(duration: 500.ms),
              const SizedBox(height: 40),

              // ── OTP Inputs ────────────────────────────────────
              Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (i) {
                        final hasValue = _ctrls[i].text.isNotEmpty;
                        return Container(
                          width: 68,
                          height: 68,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: hasValue
                                ? AppColors.primaryFixed.withValues(alpha: 0.2)
                                : AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: _nodes[i].hasFocus
                                  ? AppColors.primary
                                  : hasValue
                                  ? AppColors.primary.withValues(alpha: 0.3)
                                  : AppColors.outlineVariant.withValues(
                                      alpha: 0.2,
                                    ),
                              width: _nodes[i].hasFocus ? 2 : 1,
                            ),
                          ),
                          child: TextField(
                            controller: _ctrls[i],
                            focusNode: _nodes[i],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                            decoration: const InputDecoration(
                              counterText: '',
                              border: InputBorder.none,
                              filled: false,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (v) {
                              if (v.isNotEmpty && i < 3) {
                                _nodes[i + 1].requestFocus();
                              }
                              if (v.isEmpty && i > 0) {
                                _nodes[i - 1].requestFocus();
                              }
                              if (_otp.length == 4) _verify();
                              setState(() {});
                            },
                          ),
                        );
                      }),
                    ),
                  )
                  .animate(delay: 200.ms)
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.15),

              const SizedBox(height: 40),

              // ── Verify Button ─────────────────────────────────
              SidadButton(
                    text: AppStrings.verify,
                    isLoading: state.status == AuthStatus.loading,
                    onPressed: _otp.length == 4 ? _verify : null,
                  )
                  .animate(delay: 300.ms)
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.1),

              const SizedBox(height: 24),

              // ── Resend ────────────────────────────────────────
              Center(
                child: _canResend
                    ? TextButton.icon(
                        onPressed: _resend,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text(AppStrings.resendOtp),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${AppStrings.resendIn} ',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$_cd',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    fontFamily: 'Roboto',
                                  ),
                            ),
                          ),
                          Text(
                            ' ثانية',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
              ).animate(delay: 350.ms).fadeIn(duration: 500.ms),
            ],
          ),
        ),
      ),
    );
  }
}
