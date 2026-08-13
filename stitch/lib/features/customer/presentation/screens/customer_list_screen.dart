/// Customer List screen matching Stitch "Customer List - سداد" design with premium animations.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/sidad_avatar.dart';
import '../../../../shared/widgets/sidad_card.dart';
import '../../../../shared/widgets/sidad_empty_state.dart';
import '../../../../shared/widgets/sidad_shimmer.dart';
import '../providers/customer_providers.dart';
import '../../domain/entities/customer_entity.dart';

final _fmt = NumberFormat('#,###', 'ar');

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});
  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customerListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.customers),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            onPressed: () => context.push('/add-customer'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: AppStrings.searchCustomers,
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.onSurfaceVariant,
                      ),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _search.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.filter_list_rounded, color: AppColors.primary),
                    onPressed: () {},
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2),
          ),
          Expanded(child: _buildBody(customers)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-customer'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('عميل جديد', style: TextStyle(fontWeight: FontWeight.bold)),
      ).animate().scale(delay: 400.ms, duration: 400.ms, curve: Curves.elasticOut),
    );
  }

  Widget _buildBody(AsyncValue<List<Customer>> customersState) {
    final list = customersState.valueOrNull;
    if (list != null) {
      final filtered = _query.isEmpty
          ? list
          : list
                .where(
                  (c) => c.name.contains(_query) || c.phone.contains(_query),
                )
                .toList();
      if (filtered.isEmpty) {
        return SidadEmptyState(
          icon: Icons.people_outline_rounded,
          title: AppStrings.noCustomers,
          description: AppStrings.noCustomersDesc,
          actionText: AppStrings.addCustomer,
          onAction: () => context.push('/add-customer'),
        ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.9, 0.9));
      }
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final c = filtered[i];
          return SidadCard(
            onTap: () => context.push('/customer/${c.id}'),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SidadAvatar(name: c.name, size: 48),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c.phone,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(fontFamily: 'Roboto'),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppStrings.remaining,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_fmt.format(c.remainingDebt)} ${AppStrings.currency}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: c.remainingDebt > 0
                            ? AppColors.error
                            : AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                const Icon(Icons.more_vert_rounded, color: AppColors.onSurfaceVariant, size: 20),
              ],
            ),
          ).animate(delay: (i * 60).ms).fadeIn(duration: 400.ms).slideY(begin: 0.15, curve: Curves.easeOutQuad);
        },
      );
    }
    if (customersState.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: SidadShimmerList(),
      );
    }
    return Center(child: Text('${customersState.error}'));
  }
}
