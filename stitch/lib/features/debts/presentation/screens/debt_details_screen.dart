/// Debt Details screen matching Stitch "تفاصيل الدين - سداد" design with premium animations.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/sidad_button.dart';
import '../../../../shared/widgets/sidad_card.dart';
import '../../../../shared/widgets/status_chip.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/debt_providers.dart';
import '../../domain/entities/debt_entity.dart';

final _fmt = NumberFormat('#,###', 'ar');
final _dateFmt = DateFormat('dd MMMM yyyy', 'ar');

class DebtDetailsScreen extends ConsumerWidget {
  final String debtId;
  const DebtDetailsScreen({super.key, required this.debtId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debtAsync = ref.watch(debtDetailProvider(debtId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الدين'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AppColors.primary),
            onPressed: () {
              final debt = debtAsync.valueOrNull;
              if (debt == null) return;
              final dueStr = debt.dueDate != null
                  ? _dateFmt.format(debt.dueDate!)
                  : 'غير محدد';
              final statusStr = debt.isPaid
                  ? '✅ مسدد'
                  : (debt.isOverdue ? '⚠️ متأخر' : '⏳ معلق');
              final lines = [
                '📊 تفاصيل المديونية | سداد',
                'العميل: ${debt.customerName}',
                'المبلغ: ${_fmt.format(debt.amount)} ${AppStrings.currency}',
                'المتبقي: ${_fmt.format(debt.remaining)} ${AppStrings.currency}',
                'الحالة: $statusStr',
                'تاريخ الاستحقاق: $dueStr',
              ];
              Share.share(lines.join('\n'));
            },
          ),
        ],
      ),
      body: debtAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text('خطأ: $err', style: const TextStyle(color: AppColors.error)),
            ],
          ),
        ),
        data: (debt) => _buildContent(context, debt),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Debt debt) {
    final status = switch (debt.status) {
      DebtStatusEnum.paid => DebtStatus.paid,
      DebtStatusEnum.overdue => DebtStatus.overdue,
      DebtStatusEnum.partiallyPaid => DebtStatus.pending,
      _ => DebtStatus.pending,
    };

    return SafeArea(
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: AppDimens.pageHorizontal,
              right: AppDimens.pageHorizontal,
              top: 24,
              bottom: 120, // Space for bottom button
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top prominent amount
                Text(
                  'المبلغ المتبقي',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.onSurfaceVariant),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
                const SizedBox(height: 8),
                Text(
                  '${_fmt.format(debt.remaining)} ${AppStrings.currency}',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: debt.remaining > 0 ? AppColors.error : AppColors.success,
                      ),
                ).animate(delay: 100.ms).fadeIn(duration: 500.ms).scale(curve: Curves.easeOutBack),
                const SizedBox(height: 16),
                StatusChip(status: status).animate(delay: 200.ms).fadeIn(duration: 400.ms),
                const SizedBox(height: 32),
                
                // Debt details card
                SidadCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _buildDetailRow(context, 'العميل', debt.customerName, Icons.person_outline_rounded),
                      _Divider(),
                      _buildDetailRow(context, 'المبلغ الإجمالي', '${_fmt.format(debt.amount)} ${AppStrings.currency}', Icons.account_balance_wallet_outlined),
                      _Divider(),
                      _buildDetailRow(context, 'المبلغ المسدد', '${_fmt.format(debt.paidAmount)} ${AppStrings.currency}', Icons.check_circle_outline_rounded, valueColor: AppColors.success),
                      _Divider(),
                      _buildDetailRow(context, 'تاريخ الدين', _dateFmt.format(debt.createdAt), Icons.calendar_today_rounded),
                      if (debt.dueDate != null) ...[
                        _Divider(),
                        _buildDetailRow(context, 'تاريخ الاستحقاق', _dateFmt.format(debt.dueDate!), Icons.event_available_rounded, valueColor: debt.isOverdue ? AppColors.error : null),
                      ],
                      if (debt.description != null && debt.description!.isNotEmpty) ...[
                        _Divider(),
                        _buildDetailRow(context, 'الوصف', debt.description!, Icons.description_outlined),
                      ]
                    ],
                  ),
                ).animate(delay: 300.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1),
              ],
            ),
          ),
          
          // Bottom fixed button
          if (!debt.isPaid)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.onSurface.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SidadButton(
                    text: 'تسديد الدين',
                    icon: Icons.payment_rounded,
                    onPressed: () {
                      context.push('/register-payment', extra: debt.customerId);
                    },
                  ),
                ),
              ).animate(delay: 400.ms).fadeIn(duration: 400.ms).slideY(begin: 1.0),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.onSurfaceVariant.withValues(alpha: 0.7)),
          const SizedBox(width: 12),
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: valueColor ?? AppColors.onSurface,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 0.5,
      color: AppColors.outlineVariant.withValues(alpha: 0.2),
      indent: 16,
      endIndent: 16,
    );
  }
}
