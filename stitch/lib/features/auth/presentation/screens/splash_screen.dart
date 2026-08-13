/// Splash screen — brand reveal animation matching Stitch design.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/user_entity.dart';
import '../providers/auth_provider.dart';
import '../../../../shared/widgets/sidad_logo.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleUp;
  late Animation<double> _taglineFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.4, curve: Curves.easeOut),
      ),
    );

    _scaleUp = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.4, curve: Curves.easeOutBack),
      ),
    );

    _taglineFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.7, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await _controller.forward();
    if (!mounted) return;

    await ref.read(authProvider.notifier).checkAuth();
    if (!mounted) return;

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
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.splashGradient,
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),
                // Logo / Icon
                FadeTransition(
                  opacity: _fadeIn,
                  child: ScaleTransition(
                    scale: _scaleUp,
                    child: const SidadLogo(size: 120),
                  ),
                ),
                const SizedBox(height: 24),
                // App Name
                FadeTransition(
                  opacity: _fadeIn,
                  child: Text(
                    AppStrings.appName,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Tagline
                FadeTransition(
                  opacity: _taglineFade,
                  child: Text(
                    AppStrings.tagline,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(flex: 3),
                // Loading indicator (dots)
                FadeTransition(
                  opacity: _taglineFade,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: index == 0
                              ? AppColors.primary
                              : Colors.white.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            );
          },
        ),
      ),
    );
  }
}
