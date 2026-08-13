/// Registration screen with name, email, phone, password fields with premium animations.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  UserRole _selectedRole = UserRole.merchant;

  @override
  void initState() {
    super.initState();
    _nameFocusNode.addListener(() => setState(() {}));
    _emailFocusNode.addListener(() => setState(() {}));
    _phoneFocusNode.addListener(() => setState(() {}));
    _passwordFocusNode.addListener(() => setState(() {}));
    _confirmPasswordFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (_formKey.currentState?.validate() ?? false) {
      await ref
          .read(authProvider.notifier)
          .register(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            password: _passwordController.text,
            role: _selectedRole,
          );
      if (mounted) {
        final state = ref.read(authProvider);
        if (state.status == AuthStatus.authenticated) {
          if (state.requiresVerification) {
            context.go('/otp', extra: _emailController.text.trim());
          } else {
            // Navigate directly to the correct dashboard based on selected role
            context.go(
              _selectedRole == UserRole.merchant
                  ? '/merchant-dashboard'
                  : '/customer-dashboard',
            );
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

    var animDelay = 0.ms;
    Widget animateWidget(Widget child, {Duration? customDelay}) {
      final currentDelay = customDelay ?? animDelay;
      if (customDelay == null) {
        animDelay += 50.ms;
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
                const SizedBox(height: 40),

                // ── Brand Section (Elastic Logo Popup) ────────────
                Center(
                  child: const SidadLogo(size: 76)
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .scale(
                            duration: 700.ms,
                            curve: Curves.elasticOut,
                            begin: const Offset(0.5, 0.5),
                          ),
                ),
                const SizedBox(height: 16),

                animateWidget(
                  Center(
                    child: Text(
                      AppStrings.appName,
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // ── Title ────────────────────────────────────────
                animateWidget(
                  Text(
                    AppStrings.registerTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                animateWidget(
                  Text(
                    AppStrings.registerSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),

                const SizedBox(height: 28),

                // ── Account Type ─────────────────────────────────
                animateWidget(
                  Text(
                    'نوع الحساب',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                animateWidget(
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedRole = UserRole.merchant),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedRole == UserRole.merchant
                                  ? AppColors.primaryFixed.withValues(
                                      alpha: 0.3,
                                    )
                                  : AppColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedRole == UserRole.merchant
                                    ? AppColors.primary
                                    : AppColors.outlineVariant.withValues(
                                        alpha: 0.3,
                                      ),
                                width: _selectedRole == UserRole.merchant
                                    ? 1.5
                                    : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                AppStrings.merchant,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: _selectedRole == UserRole.merchant
                                          ? AppColors.primary
                                          : AppColors.onSurfaceVariant,
                                      fontWeight:
                                          _selectedRole == UserRole.merchant
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedRole = UserRole.customer),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedRole == UserRole.customer
                                  ? AppColors.primaryFixed.withValues(
                                      alpha: 0.3,
                                    )
                                  : AppColors.surfaceContainerLowest,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedRole == UserRole.customer
                                    ? AppColors.primary
                                    : AppColors.outlineVariant.withValues(
                                        alpha: 0.3,
                                      ),
                                width: _selectedRole == UserRole.customer
                                    ? 1.5
                                    : 1,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                AppStrings.customer,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: _selectedRole == UserRole.customer
                                          ? AppColors.primary
                                          : AppColors.onSurfaceVariant,
                                      fontWeight:
                                          _selectedRole == UserRole.customer
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Name Input ───────────────────────────────────
                animateWidget(
                  Text(
                    AppStrings.fullName,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                animateWidget(
                  TextFormField(
                    controller: _nameController,
                    focusNode: _nameFocusNode,
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: AppStrings.fullNameHint,
                      prefixIcon: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: AnimatedScale(
                          scale: _nameFocusNode.hasFocus ? 1.15 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.person_outline_rounded,
                            color: _nameFocusNode.hasFocus
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
                      if (value == null || value.trim().isEmpty) {
                        return AppStrings.nameRequired;
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 18),

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

                const SizedBox(height: 18),

                // ── Phone Input ──────────────────────────────────
                animateWidget(
                  Text(
                    AppStrings.phoneNumber,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                animateWidget(
                  TextFormField(
                    controller: _phoneController,
                    focusNode: _phoneFocusNode,
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                    maxLength: 12,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: '7XXXXXXXX',
                      hintTextDirection: TextDirection.ltr,
                      counterText: '',
                      prefixIcon: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '🇾🇪',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '+967',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: _phoneFocusNode.hasFocus
                                        ? AppColors.primary
                                        : AppColors.onSurfaceVariant,
                                    fontWeight: _phoneFocusNode.hasFocus
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 1,
                              height: 24,
                              color: AppColors.outlineVariant.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppStrings.phoneRequired;
                      }
                      if (value.length < 9) {
                        return AppStrings.phoneInvalid;
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 18),

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

                const SizedBox(height: 18),

                // ── Confirm Password ─────────────────────────────
                animateWidget(
                  Text(
                    AppStrings.confirmPassword,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                animateWidget(
                  TextFormField(
                    controller: _confirmPasswordController,
                    focusNode: _confirmPasswordFocusNode,
                    obscureText: _obscureConfirm,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                    decoration: InputDecoration(
                      hintText: AppStrings.confirmPasswordHint,
                      hintTextDirection: TextDirection.ltr,
                      prefixIcon: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: AnimatedScale(
                          scale: _confirmPasswordFocusNode.hasFocus
                              ? 1.15
                              : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.lock_outline_rounded,
                            color: _confirmPasswordFocusNode.hasFocus
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
                          _obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                          size: 22,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirm = !_obscureConfirm;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppStrings.confirmPasswordRequired;
                      }
                      if (value != _passwordController.text) {
                        return AppStrings.passwordMismatch;
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: 32),

                // ── Register Button ──────────────────────────────
                animateWidget(
                  SidadButton(
                    text: AppStrings.registerBtn,
                    isLoading: authState.status == AuthStatus.loading,
                    onPressed: _handleRegister,
                  ),
                ),

                const SizedBox(height: 24),

                // ── Terms ────────────────────────────────────────
                animateWidget(
                  Center(
                    child: Text.rich(
                      TextSpan(
                        text: 'بالتسجيل، أنت توافق على ',
                        style: Theme.of(context).textTheme.bodySmall,
                        children: [
                          TextSpan(
                            text: 'الشروط والأحكام',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

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
                const SizedBox(height: 24),

                // ── Login Link ───────────────────────────────────
                animateWidget(
                  Center(
                    child: Text.rich(
                      TextSpan(
                        text: AppStrings.haveAccount,
                        style: Theme.of(context).textTheme.bodyMedium,
                        children: [
                          const TextSpan(text: ' '),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.baseline,
                            baseline: TextBaseline.alphabetic,
                            child: GestureDetector(
                              onTap: () => context.go('/login'),
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Text(
                                  AppStrings.loginNow,
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
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
