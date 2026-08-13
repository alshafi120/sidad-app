/// Customer Dashboard — dynamic, animated screen for the customer role.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/sidad_card.dart';
import '../../../../shared/widgets/sidad_shimmer.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/customer_providers.dart';
import '../../domain/entities/customer_dashboard_entity.dart';

final _fmt = NumberFormat('#,###', 'ar');

class CustomerDashboardScreen extends ConsumerStatefulWidget {
  final String? prefilledMerchantCode;
  const CustomerDashboardScreen({super.key, this.prefilledMerchantCode});

  @override
  ConsumerState<CustomerDashboardScreen> createState() =>
      _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState
    extends ConsumerState<CustomerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.prefilledMerchantCode != null &&
        widget.prefilledMerchantCode!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showLinkConfirmationDialog(context, widget.prefilledMerchantCode!);
      });
    }
  }

  void _showLinkConfirmationDialog(BuildContext context, String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          'طلب ربط الحساب بالتاجر',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل ترغب في ربط حسابك بالتاجر صاحب الرمز ($code) ومزامنة ديونك معه؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('جاري ربط التاجر ومزامنة الديون...'),
                ),
              );

              final success = await ref
                  .read(customerControllerProvider.notifier)
                  .linkMerchant(code);

              if (!context.mounted) return;

              if (success) {
                ref.invalidate(customerDashboardProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم الربط ومزامنة الديون بنجاح!'),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'فشل الربط. تأكد من إدخال كود التاجر الصحيح ومن قيامه بتسجيل رقمك.',
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('ربط الآن'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(customerDashboardProvider);
    final user = ref.watch(authProvider).user;
    final customerName = user?.name ?? 'العميل';

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.refresh(customerDashboardProvider),
          child: dashboardAsync.when(
            data: (data) =>
                _buildContent(context, customerName, user?.phone ?? '', data),
            loading: () => const Padding(
              padding: EdgeInsets.all(20),
              child: SidadShimmerList(itemCount: 4, itemHeight: 100),
            ),
            error: (err, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'حدث خطأ: $err',
                    style: const TextStyle(color: AppColors.error),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(customerDashboardProvider),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    String name,
    String phone,
    CustomerDashboardData data,
  ) {
    return CustomScrollView(
      slivers: [
        // ── Header (Animated greeting) ──────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مرحباً، $name 👋',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'مديونياتي',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => _showLinkMerchantDialogOrScanner(context),
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 24),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer.withValues(
                      alpha: 0.2,
                    ),
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.all(12),
                  ),
                ).animate().scale(
                  delay: 200.ms,
                  duration: 400.ms,
                  curve: Curves.elasticOut,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),
        ),

        // ── Balance Card (Animated total debts) ──────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child:
                Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: AppColors.secondaryGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            offset: const Offset(0, 12),
                            blurRadius: 32,
                            color: AppColors.secondary.withValues(alpha: 0.3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'إجمالي مديونياتي المتبقية',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _fmt.format(data.pendingDebts),
                                style: Theme.of(context).textTheme.displaySmall
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
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                size: 16,
                                color: Colors.greenAccent[100],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'تم تسديد: ${_fmt.format(data.settledDebts)} ${AppStrings.currency}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 150.ms, duration: 500.ms)
                    .scale(
                      begin: const Offset(0.97, 0.97),
                      curve: Curves.easeOutBack,
                    ),
          ),
        ),

        // ── QR Link Invitation Alert Card ─────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: GestureDetector(
              onTap: () => _showLinkMerchantDialogOrScanner(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.1),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.qr_code_scanner_rounded,
                      color: AppColors.primary,
                      size: 36,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ربط تاجر جديد',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'اضغط هنا لمسح رمز QR الخاص بالتاجر أو إدخال كوده يدوياً لربط حسابك ومزامنة ديونك.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_left_rounded, color: AppColors.primary),
                  ],
                ),
              ),
            ).animate(delay: 250.ms).fadeIn(),
          ),
        ),

        // ── Merchant Debts Section Header ────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
            child: Text(
              'المديونيات حسب التاجر',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),

        // ── Merchant Debts List ──────────────────────────
        if (data.merchants.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.storefront_rounded,
                      size: 48,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'لا توجد مديونيات مرتبطة حالياً',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'شارك كود الربط الخاص بك مع التاجر لتسجيل ديونك.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.separated(
              itemCount: data.merchants.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final merchantDebt = data.merchants[i];
                final status = switch (merchantDebt.status) {
                  'paid' => DebtStatus.paid,
                  'overdue' => DebtStatus.overdue,
                  _ => DebtStatus.pending,
                };
                return SidadCard(
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primaryFixed.withValues(
                                alpha: 0.3,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.storefront_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  merchantDebt.merchantName,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${merchantDebt.debtCount} مديونيات',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${_fmt.format(merchantDebt.remainingAmount)} ${AppStrings.currency}',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: merchantDebt.remainingAmount > 0
                                          ? AppColors.error
                                          : AppColors.success,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              StatusChip(status: status),
                            ],
                          ),
                        ],
                      ),
                    )
                    .animate(delay: (300 + i * 80).ms)
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.1, end: 0);
              },
            ),
          ),

        // ── Recent Transactions Header ──────────────────
        if (data.recentTransactions.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              child: Text(
                'العمليات الأخيرة',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.separated(
              itemCount: data.recentTransactions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final tx = data.recentTransactions[i];
                final status = switch (tx.status) {
                  'completed' => DebtStatus.paid,
                  'paid' => DebtStatus.paid,
                  'overdue' => DebtStatus.overdue,
                  _ => DebtStatus.pending,
                };
                return SidadCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          color: AppColors.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.title.isNotEmpty
                                  ? tx.title
                                  : (tx.description ?? 'مديونية'),
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              tx.merchantName,
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
                            '${_fmt.format(tx.remainingAmount)} ${AppStrings.currency}',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          StatusChip(status: status),
                        ],
                      ),
                    ],
                  ),
                ).animate(delay: (400 + i * 50).ms).fadeIn();
              },
            ),
          ),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  void _showLinkMerchantDialogOrScanner(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'ربط تاجر جديد',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('اربط حسابك بمتجر التاجر لمزامنة ديونك وعرضها مباشرة:'),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showMockQrScanner(context);
              },
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('مسح رمز QR للتاجر'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showManualLinkDialog(context);
              },
              icon: const Icon(Icons.keyboard_rounded),
              label: const Text('إدخال كود التاجر يدوياً'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showManualLinkDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'كود التاجر اليدوي',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'رقم هاتف التاجر أو الكود',
            hintText: '777XXXXXX',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = controller.text.trim();
              if (code.isEmpty) return;
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('جاري ربط التاجر ومزامنة الديون...'),
                ),
              );

              final success = await ref
                  .read(customerControllerProvider.notifier)
                  .linkMerchant(code);

              if (!context.mounted) return;

              if (success) {
                ref.invalidate(customerDashboardProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم الربط ومزامنة الديون بنجاح!'),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'فشل الربط. تأكد من إدخال كود التاجر الصحيح ومن قيامه بتسجيل رقمك.',
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('ربط الآن'),
          ),
        ],
      ),
    );
  }

  void _showMockQrScanner(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          top: 24,
          left: 24,
          right: 24,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ماسح رمز QR للتاجر',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const CloseButton(color: Colors.white),
                  ],
                ),
                const SizedBox(height: 32),
                // Animated scanner frame
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary, width: 4),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 80,
                        color: Colors.white54,
                      ),
                      Container(width: 240, height: 2, color: AppColors.primary)
                          .animate(onPlay: (controller) => controller.repeat())
                          .moveY(
                            begin: -110,
                            end: 110,
                            duration: 1500.ms,
                            curve: Curves.easeInOut,
                          ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'وجه الكاميرا إلى كود ربط المتجر المعروض لدى التاجر',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم مسح الرمز! جاري ربط التاجر...'),
                      ),
                    );

                    // Simulation uses the seeded demo merchant's phone number!
                    final success = await ref
                        .read(customerControllerProvider.notifier)
                        .linkMerchant('+966500000001');

                    if (!context.mounted) return;

                    if (success) {
                      ref.invalidate(customerDashboardProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم الربط ومزامنة الديون بنجاح!'),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'فشل الربط. تأكد من تسجيل رقمك لدى هذا التاجر.',
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.flash_on_rounded),
                  label: const Text('محاكاة مسح رمز QR التاجر ناجح'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
