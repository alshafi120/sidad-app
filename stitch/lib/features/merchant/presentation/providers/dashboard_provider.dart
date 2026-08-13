/// Dashboard state management for merchants.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../customer/domain/entities/customer_entity.dart';
import '../../../debts/domain/entities/debt_entity.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../data/services/dashboard_service.dart';

/// Dashboard summary data.
class DashboardData {
  final double totalDebts;
  final double settledDebts;
  final double pendingDebts;
  final int activeCustomers;
  final List<Debt> recentTransactions;
  final List<Customer> topCustomers;

  const DashboardData({
    required this.totalDebts,
    required this.settledDebts,
    required this.pendingDebts,
    required this.activeCustomers,
    required this.recentTransactions,
    required this.topCustomers,
  });
}

// ── Repository Provider ──────────────────────────────────────────────
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardServiceImpl(ref.read(dioProvider));
});

// ── Dashboard Provider ───────────────────────────────────────────────
final dashboardProvider = FutureProvider.autoDispose<DashboardData>((
  ref,
) async {
  final repository = ref.watch(dashboardRepositoryProvider);
  final result = await repository.getDashboardSummary();
  return result.fold((failure) => throw failure.message, (data) => data);
});
