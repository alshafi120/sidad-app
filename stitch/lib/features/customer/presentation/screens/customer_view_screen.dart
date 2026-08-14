/// Customer View screen matching Stitch "Customer View - سداد" design.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import 'dart:ui' as ui;
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/sidad_empty_state.dart';
import '../providers/customer_providers.dart';
import '../../domain/entities/customer_entity.dart';
import '../../../debts/presentation/providers/debt_providers.dart';
import '../../../debts/domain/entities/debt_entity.dart';

final _fmt = NumberFormat('#,###.00', 'ar');
final _dateFmt = DateFormat('yyyy/MM/dd hh:mm a', 'ar');

class CustomerViewScreen extends ConsumerWidget {
  final String customerId;
  const CustomerViewScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerDetailProvider(customerId));
    final debtsAsync = ref.watch(customerDebtsProvider(customerId));

    return customerAsync.when(
      data: (customer) => _buildScreen(context, ref, customer, debtsAsync),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: 12),
              Text('$err', style: const TextStyle(color: AppColors.error)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScreen(
    BuildContext context,
    WidgetRef ref,
    Customer customer,
    AsyncValue<List<Debt>> debtsAsync,
  ) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'تفاصيل العميل',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Customer Header & Info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.outlineVariant,
                        width: 2,
                      ),
                    ),
                    child: const CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.surfaceContainerHigh,
                      child: Icon(
                        Icons.person_rounded,
                        size: 40,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ).animate().fadeIn().scale(),
                  const SizedBox(height: 12),
                  // Name
                  Text(
                    customer.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ).animate().fadeIn(delay: 50.ms),
                  const SizedBox(height: 4),
                  // Phone
                  Text(
                    customer.phone,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                    textDirection: ui.TextDirection.ltr,
                  ).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 24),

                  // Summary stats
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'إجمالي المسدد',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_fmt.format(customer.paidAmount)} ${AppStrings.currency}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: AppColors.outlineVariant.withValues(alpha: 0.5),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'إجمالي الدين',
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_fmt.format(customer.totalDebt)} ${AppStrings.currency}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),

                  const SizedBox(height: 32),

                  // Action Buttons Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildActionItem(
                          context,
                          'المعاملات',
                          Icons.receipt_long_outlined,
                          () => context.push(
                            '/transactions',
                            extra: {
                              'customerId': customer.id,
                              'customerName': customer.name,
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: _buildActionItem(
                          context,
                          'تسجيل دفعة',
                          Icons.request_quote_outlined,
                          () => context.push('/register-payment', extra: customer.id),
                        ),
                      ),
                      Expanded(
                        child: _buildActionItem(
                          context,
                          'إضافة دين',
                          Icons.post_add_outlined,
                          () => context.push('/add-debt', extra: customer.id),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Debt list header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'آخر العمليات',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),

          // Live debts list
          _buildDebtsList(debtsAsync),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      bottomNavigationBar: Container(
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
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/add-debt', extra: customer.id),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    'مديونية جديدة',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.push(
                    '/transactions',
                    extra: {
                      'customerId': customer.id,
                      'customerName': customer.name,
                    },
                  ),
                  icon: const Icon(Icons.receipt_long_rounded),
                  label: const Text(
                    'عرض كل العمليات',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.outlineVariant,
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: AppColors.onSurface,
              size: 22,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDebtsList(AsyncValue<List<Debt>> debtsAsync) {
    final debts = debtsAsync.valueOrNull;
    if (debts != null) {
      if (debts.isEmpty) {
        return const SliverFillRemaining(
          child: SidadEmptyState(
            icon: Icons.receipt_long_rounded,
            title: AppStrings.noDebts,
            description: AppStrings.noDebtsDesc,
          ),
        );
      }
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList.separated(
          itemCount: debts.length > 5 ? 5 : debts.length, // Show only recent
          separatorBuilder: (_, __) => Divider(
            color: AppColors.outlineVariant.withValues(alpha: 0.5),
            height: 1,
          ),
          itemBuilder: (context, i) {
            final debt = debts[i];
            
            // Note: Since we don't have a direct 'type' in Debt (payment vs add debt),
            // we use a placeholder logic. Typically payment would have debt.amount < 0 
            // or debt.status == paid or an explicit type field.
            // Adjust this condition based on your actual data model.
            final isPayment = debt.amount < 0 || debt.status == DebtStatusEnum.paid;
            
            final amountValue = debt.amount.abs();
            final amountText = '${isPayment ? '+' : '-'} ${_fmt.format(amountValue)}';
            final amountColor = isPayment ? AppColors.success : AppColors.error;
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPayment ? Icons.download_done_rounded : Icons.receipt_rounded,
                      color: isPayment ? AppColors.success : AppColors.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          debt.description ?? (isPayment ? 'استلمت دفعة' : 'أضفت دين'),
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _dateFmt.format(debt.createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    amountText,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: amountColor,
                          fontWeight: FontWeight.bold,
                        ),
                    textDirection: ui.TextDirection.ltr,
                  ),
                ],
              ),
            );
          },
        ),
      );
    }
    if (debtsAsync.isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return SliverFillRemaining(
      child: Center(child: Text('خطأ: ${debtsAsync.error}')),
    );
  }
}
