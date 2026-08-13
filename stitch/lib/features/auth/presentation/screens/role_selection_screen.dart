/// Role selection screen matching Stitch design.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/sidad_button.dart';
import '../../domain/entities/user_entity.dart';
import '../providers/auth_provider.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});
  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  UserRole? _selected;

  void _continue() async {
    if (_selected == null) return;
    await ref.read(authProvider.notifier).setRole(_selected!);
    if (mounted) {
      context.go(
        _selected == UserRole.merchant
            ? '/merchant-dashboard'
            : '/customer-dashboard',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.pageHorizontal,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: Text(
                  AppStrings.selectRole,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'اختر نوع الحساب المناسب لك',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 48),
              _RoleCard(
                icon: Icons.storefront_rounded,
                title: AppStrings.merchant,
                description: AppStrings.merchantDesc,
                selected: _selected == UserRole.merchant,
                onTap: () => setState(() => _selected = UserRole.merchant),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                icon: Icons.person_rounded,
                title: AppStrings.customer,
                description: AppStrings.customerDesc,
                selected: _selected == UserRole.customer,
                onTap: () => setState(() => _selected = UserRole.customer),
              ),
              const Spacer(),
              SidadButton(
                text: AppStrings.continueBtn,
                onPressed: _selected != null ? _continue : null,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primaryFixed.withValues(alpha: 0.3)
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.outlineVariant.withValues(alpha: 0.15),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    offset: const Offset(0, 8),
                    blurRadius: 24,
                    color: AppColors.primary.withValues(alpha: 0.12),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary
                    : AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? AppColors.primary : AppColors.outlineVariant,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
