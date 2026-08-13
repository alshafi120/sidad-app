/// Login screen with email/password and link to registration with premium animations.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/sidad_button.dart';
import '../../../../shared/widgets/sidad_logo.dart';
import '../../domain/entities/user_entity.dart';
import '../providers/auth_provider.dart';
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() => setState(() {}));
    _passwordFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      await ref
          .read(authProvider.notifier)
          .login(_emailController.text.trim(), _passwordController.text);
      if (mounted) {
        final state = ref.read(authProvider);
        if (state.status == AuthStatus.authenticated) {
          final role = state.user?.role;
          if (role != null) {
            context.go(
              role == UserRole.merchant
                  ? '/merchant-dashboard'
                  : '/customer-dashboard',
            );
          } else {
            context.go('/role-selection');
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (prev, next) {
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

    // Helper to apply staggered fade-in and slide-up animations to the children
    var animDelay = 0.ms;
    Widget animateWidget(Widget child, {Duration? customDelay}) {
      final currentDelay = customDelay ?? animDelay;
      if (customDelay == null) {
        animDelay += 60.ms;
      }
      return child
          .animate(delay: currentDelay)
          .fadeIn(duration: 500.ms, curve: Curves.easeOut)
          .slideY(
            begin: 0.15,
            end: 0,
            duration: 500.ms,
            curve: Curves.easeOutQuad,
          );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.pageHorizontal,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),

                // ── Brand Section (Elastic Logo Popup) ────────────
                Center(
                  child:
                      const SidadLogo(size: 85)
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .scale(
                            duration: 700.ms,
                            curve: Curves.elasticOut,
                            begin: const Offset(0.5, 0.5),
                          ),
                ),
                const SizedBox(height: 20),

                animateWidget(
                  Center(
                    child: Text(
                      AppStrings.appName,
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                animateWidget(
                  Center(
                    child: Text(
                      AppStrings.tagline,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 44),

                // ── Welcome Headers ──────────────────────────────────
                animateWidget(
                  Text(
                    AppStrings.loginTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                animateWidget(
                  Text(
                    AppStrings.loginSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),

                const SizedBox(height: 28),

                // ── Email Input ──────────────────────────────────
                animateWidget(
                  Text(
                    AppStrings.email,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                animateWidget(
                  TextFormField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    keyboardType: TextInputType.emailAddress,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                    decoration: InputDecoration(
                      hintText: AppStrings.emailHint,
                      hintTextDirection: TextDirection.ltr,
                      prefixIcon: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: AnimatedScale(
                          scale: _emailFocusNode.hasFocus ? 1.15 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.email_outlined,
                            color: _emailFocusNode.hasFocus
                                ? AppColors.primary
                                : AppColors.onSurfaceVariant.withValues(
                                    alpha: 0.6,
                                  ),
                            size: 22,
                          ),
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 54,
                        minHeight: 0,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppStrings.emailRequired;
                      }
                      if (!RegExp(
                        r'^[\w\.-]+@[\w\.-]+\.\w+$',
                      ).hasMatch(value)) {
                        return AppStrings.emailInvalid;
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // ── Password Input ───────────────────────────────
                animateWidget(
                  Text(
                    AppStrings.password,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                animateWidget(
                  TextFormField(
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    obscureText: _obscurePassword,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                    decoration: InputDecoration(
                      hintText: AppStrings.passwordHint,
                      hintTextDirection: TextDirection.ltr,
                      prefixIcon: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: AnimatedScale(
                          scale: _passwordFocusNode.hasFocus ? 1.15 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.lock_outline_rounded,
                            color: _passwordFocusNode.hasFocus
                                ? AppColors.primary
                                : AppColors.onSurfaceVariant.withValues(
                                    alpha: 0.6,
                                  ),
                            size: 22,
                          ),
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 54,
                        minHeight: 0,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                          size: 22,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppStrings.passwordRequired;
                      }
                      if (value.length < 8) {
                        return AppStrings.passwordTooShort;
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // ── Forgot Password ──────────────────────────────
                animateWidget(
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton(
                      onPressed: () {
                        // TODO: Navigate to forgot password
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        AppStrings.forgotPassword,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // ── Login Button ─────────────────────────────────
                animateWidget(
                  SidadButton(
                    text: AppStrings.loginBtn,
                    isLoading: authState.status == AuthStatus.loading,
                    onPressed: _handleLogin,
                  ),
                ),

                const SizedBox(height: 32),

                // ── Divider ──────────────────────────────────────
                animateWidget(
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: AppColors.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          AppStrings.or,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.onSurfaceVariant.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: AppColors.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Register Link (Interactive Bounce) ────────────
                animateWidget(
                  Center(
                    child: Text.rich(
                      TextSpan(
                        text: AppStrings.noAccount,
                        style: Theme.of(context).textTheme.bodyMedium,
                        children: [
                          const TextSpan(text: ' '),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.baseline,
                            baseline: TextBaseline.alphabetic,
                            child: GestureDetector(
                              onTap: () => context.go('/register'),
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Text(
                                  AppStrings.registerNow,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
