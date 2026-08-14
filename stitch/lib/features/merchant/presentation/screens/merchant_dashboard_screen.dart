/// Merchant Dashboard matching Stitch "Merchant Dashboard - سداد" design with premium animations.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_shadows.dart';
import '../../../../shared/widgets/sidad_avatar.dart';
import '../../../../shared/widgets/sidad_card.dart';
import '../../../../shared/widgets/sidad_shimmer.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../debts/domain/entities/debt_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';

final _formatter = NumberFormat('#,###', 'ar');

class MerchantDashboardScreen extends ConsumerWidget {
  const MerchantDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardProvider);
    final merchantName = ref.watch(authProvider).user?.name ?? 'التاجر';

    final data = dashboard.valueOrNull;
    if (data != null) {
      return Scaffold(
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              // ── Header (Animated Slide Down) ──────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                  'مرحباً، $merchantName 👋',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                )
                                .animate()
                                .fadeIn(duration: 400.ms)
                                .slideY(begin: -0.2, end: 0),
                            const SizedBox(height: 4),
                            Text(
                                  AppStrings.dashboard,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                )
                                .animate()
                                .fadeIn(delay: 100.ms, duration: 400.ms)
                                .slideY(begin: -0.1, end: 0),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showMerchantQrBottomSheet(
                          context,
                          merchantName,
                          ref.read(authProvider).user?.phone ?? '',
                        ),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.qr_code_2_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ).animate().scale(
                        delay: 150.ms,
                        duration: 400.ms,
                        curve: Curves.elasticOut,
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => context.push('/notifications'),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child:
                                ref.watch(unreadNotificationsCountProvider) > 0
                                ? const Badge(
                                    smallSize: 8,
                                    child: Icon(
                                      Icons.notifications_none_rounded,
                                      color: AppColors.onSurface,
                                    ),
                                  )
                                : const Icon(
                                    Icons.notifications_none_rounded,
                                    color: AppColors.onSurface,
                                  ),
                          ),
                        ),
                      ).animate().scale(
                        delay: 200.ms,
                        duration: 400.ms,
                        curve: Curves.elasticOut,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Balance Card (Animated Scaling + Count Up) ───
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child:
                      Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  offset: const Offset(0, 12),
                                  blurRadius: 32,
                                  color: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppStrings.totalDebts,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Colors.white70),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    _AnimatedCountText(
                                      value: data.totalDebts.toDouble(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .displaySmall
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(width: 8),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Text(
                                        AppStrings.currency,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(color: Colors.white70),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    _BalanceStat(
                                      label: AppStrings.settledDebts,
                                      value: data.settledDebts,
                                      icon: Icons.check_circle_outline,
                                      color: const Color(0xFF6BFF8F),
                                    ),
                                    const SizedBox(width: 16),
                                    _BalanceStat(
                                      label: AppStrings.pendingDebts,
                                      value: data.pendingDebts,
                                      icon: Icons.schedule_rounded,
                                      color: Colors.white70,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 250.ms, duration: 600.ms)
                          .scale(
                            begin: const Offset(0.95, 0.95),
                            curve: Curves.easeOutBack,
                          ),
                ),
              ),

              // ── Quick Actions (Elastic Staggered Scale) ───────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child:
                            _QuickAction(
                                  icon: Icons.person_add_rounded,
                                  label: 'عميل جديد',
                                  onTap: () => context.push('/add-customer'),
                                )
                                .animate(delay: 350.ms)
                                .fadeIn(duration: 300.ms)
                                .scale(curve: Curves.elasticOut),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child:
                            _QuickAction(
                                  icon: Icons.receipt_long_rounded,
                                  label: 'مديونية جديدة',
                                  onTap: () => context.push('/add-debt'),
                                )
                                .animate(delay: 400.ms)
                                .fadeIn(duration: 300.ms)
                                .scale(curve: Curves.elasticOut),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child:
                            _QuickAction(
                                  icon: Icons.people_rounded,
                                  label: 'العملاء',
                                  onTap: () => context.push('/customers'),
                                )
                                .animate(delay: 450.ms)
                                .fadeIn(duration: 300.ms)
                                .scale(curve: Curves.elasticOut),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Stats Row (Slide-in from Left/Right) ─────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child:
                            _StatCard(
                                  icon: Icons.people_outline_rounded,
                                  value: '${data.activeCustomers}',
                                  label: AppStrings.activeCustomers,
                                  color: AppColors.primary,
                                )
                                .animate(delay: 500.ms)
                                .fadeIn()
                                .slideX(
                                  begin: -0.15,
                                  end: 0,
                                  curve: Curves.easeOutQuad,
                                ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child:
                            _StatCard(
                                  icon: Icons.check_circle_outline_rounded,
                                  value:
                                      '${data.recentTransactions.where((d) => d.isPaid).length}',
                                  label: AppStrings.settledDebts,
                                  color: AppColors.success,
                                )
                                .animate(delay: 550.ms)
                                .fadeIn()
                                .slideX(
                                  begin: 0.15,
                                  end: 0,
                                  curve: Curves.easeOutQuad,
                                ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Recent Transactions Header ──────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppStrings.recentTransactions,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      TextButton(
                        onPressed: () => context.push('/transactions'),
                        child: const Text(AppStrings.viewAll),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Transaction List (Staggered Slide up) ───────
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.separated(
                  itemCount: data.recentTransactions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final debt = data.recentTransactions[i];
                    return _TransactionItem(debt: debt)
                        .animate(delay: (600 + i * 80).ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.15, end: 0, curve: Curves.easeOutQuad);
                  },
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      );
    }
    if (dashboard.isLoading) {
      return const Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: SidadShimmerList(itemCount: 4, itemHeight: 100),
          ),
        ),
      );
    }
    return Scaffold(body: Center(child: Text('${dashboard.error}')));
  }

  void _showMerchantQrBottomSheet(
    BuildContext context,
    String name,
    String phone,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'رمز ربط المتجر (التاجر)',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'دع العميل يمسح رمز QR هذا في تطبيقه للربط المباشر بـ $name',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: phone,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'كود المتجر اليدوي (رقم الهاتف)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    phone,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                final link = 'https://sidad.app/join?code=$phone';
                Share.share(
                  'مرحباً! يمكنك ربط حسابك بمتجري ومتابعة ديونك وسدادها مباشرة عبر منصة سداد من خلال هذا الرابط:\n$link',
                  subject: 'دعوة ربط حساب سداد',
                );
              },
              icon: const Icon(Icons.share_rounded),
              label: const Text('مشاركة رابط الدعوة للعميل'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryContainer,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('موافق'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Custom Neobanking Count-Up Text Widget ─────────
class _AnimatedCountText extends StatefulWidget {
  final double value;
  final TextStyle? style;
  const _AnimatedCountText({required this.value, this.style});

  @override
  State<_AnimatedCountText> createState() => _AnimatedCountTextState();
}

class _AnimatedCountTextState extends State<_AnimatedCountText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.value,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));
    _controller.forward();
  }

  @override
  void didUpdateWidget(_AnimatedCountText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(begin: _animation.value, end: widget.value)
          .animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart),
          );
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          _formatter.format(_animation.value.round()),
          style: widget.style,
        );
      },
    );
  }
}

class _BalanceStat extends StatelessWidget {
  final String label;
  final num value;
  final IconData icon;
  final Color color;

  const _BalanceStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: Colors.white60),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                _AnimatedCountText(
                  value: value.toDouble(),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryFixed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SidadCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final Debt debt;
  const _TransactionItem({required this.debt});

  @override
  Widget build(BuildContext context) {
    final status = switch (debt.status) {
      DebtStatusEnum.paid => DebtStatus.paid,
      DebtStatusEnum.overdue => DebtStatus.overdue,
      _ => DebtStatus.pending,
    };
    return GestureDetector(
      onTap: () => context.push('/customer/${debt.customerId}'),
      child: SidadCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SidadAvatar(name: debt.customerName, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    debt.customerName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    debt.description ?? '',
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${_formatter.format(debt.amount)} ${AppStrings.currency}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                StatusChip(status: status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
