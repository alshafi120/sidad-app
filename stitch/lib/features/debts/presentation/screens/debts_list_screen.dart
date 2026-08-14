/// All Transactions / Debts list screen with search, status filters, and rich animations.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/sidad_card.dart';
import '../../../../shared/widgets/sidad_empty_state.dart';
import '../../../../shared/widgets/sidad_shimmer.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../providers/debt_providers.dart';
import '../../domain/entities/debt_entity.dart';

final _fmt = NumberFormat('#,###', 'ar');
final _dateFmt = DateFormat('yyyy/MM/dd', 'ar');

class DebtsListScreen extends ConsumerStatefulWidget {
  final String? customerId;
  final String? customerName;

  const DebtsListScreen({
    super.key,
    this.customerId,
    this.customerName,
  });

  @override
  ConsumerState<DebtsListScreen> createState() => _DebtsListScreenState();
}

class _DebtsListScreenState extends ConsumerState<DebtsListScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _selectedFilter = 'all'; // 'all', 'active', 'paid', 'overdue'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final debtsAsync = widget.customerId != null
        ? ref.watch(customerDebtsProvider(widget.customerId!))
        : ref.watch(debtListProvider);

    final title = widget.customerName != null
        ? 'عمليات ${widget.customerName}'
        : 'سجل العمليات والديون';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'إضافة مديونية',
            onPressed: () => context.push(
              '/add-debt',
              extra: widget.customerId,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filters Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'ابحث عن عملية أو عميل...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.onSurfaceVariant,
                ),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
            ),
          ).animate().fadeIn(duration: 300.ms),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('الكل', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('النشطة والمعلقة', 'active'),
                const SizedBox(width: 8),
                _buildFilterChip('المسددة', 'paid'),
                const SizedBox(width: 8),
                _buildFilterChip('المتأخرة', 'overdue'),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

          // List Body
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                if (widget.customerId != null) {
                  ref.invalidate(customerDebtsProvider(widget.customerId!));
                } else {
                  ref.invalidate(debtListProvider);
                }
              },
              child: _buildListContent(debtsAsync),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-debt', extra: widget.customerId),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('مديونية جديدة', style: TextStyle(fontWeight: FontWeight.bold)),
      ).animate().scale(delay: 300.ms, duration: 400.ms, curve: Curves.elasticOut),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = value),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      showCheckmark: false,
    );
  }

  Widget _buildListContent(AsyncValue<List<Debt>> debtsAsync) {
    return debtsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(20),
        child: SidadShimmerList(itemCount: 5, itemHeight: 90),
      ),
      error: (err, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text('خطأ: $err', style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                if (widget.customerId != null) {
                  ref.invalidate(customerDebtsProvider(widget.customerId!));
                } else {
                  ref.invalidate(debtListProvider);
                }
              },
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
      data: (debts) {
        // Filter by search query
        var list = debts;
        if (_query.isNotEmpty) {
          list = list.where((d) {
            final name = d.customerName.toLowerCase();
            final title = d.description?.toLowerCase() ?? '';
            final q = _query.toLowerCase();
            return name.contains(q) || title.contains(q);
          }).toList();
        }

        // Filter by status chip
        if (_selectedFilter == 'active') {
          list = list.where((d) => !d.isPaid && !d.isOverdue).toList();
        } else if (_selectedFilter == 'paid') {
          list = list.where((d) => d.isPaid).toList();
        } else if (_selectedFilter == 'overdue') {
          list = list.where((d) => d.isOverdue).toList();
        }

        if (list.isEmpty) {
          return SidadEmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'لا توجد عمليات',
            description: 'لم يتم العثور على أي عمليات مطابقة لخيارات البحث أو الفلترة.',
            actionText: 'إضافة مديونية',
            onAction: () => context.push('/add-debt', extra: widget.customerId),
          ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95));
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final debt = list[i];
            final status = switch (debt.status) {
              DebtStatusEnum.paid => DebtStatus.paid,
              DebtStatusEnum.overdue => DebtStatus.overdue,
              _ => DebtStatus.pending,
            };

            return SidadCard(
              onTap: () => context.push('/debt/${debt.id}'),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.receipt_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          debt.customerName.isNotEmpty
                              ? debt.customerName
                              : (debt.description ?? 'مديونية'),
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              _dateFmt.format(debt.createdAt),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                            ),
                            if (debt.description != null && debt.customerName.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '• ${debt.description}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_fmt.format(debt.amount)} ${AppStrings.currency}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      StatusChip(status: status),
                    ],
                  ),
                ],
              ),
            ).animate(delay: (i * 40).ms).fadeIn(duration: 350.ms).slideY(begin: 0.1);
          },
        );
      },
    );
  }
}
