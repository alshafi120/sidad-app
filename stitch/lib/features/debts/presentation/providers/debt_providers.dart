/// State management for debts.
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/debt_entity.dart';
import '../../domain/repositories/debt_repository.dart';
import '../../data/repositories/debt_repository_impl.dart';

// ── Repository Provider ──────────────────────────────────────────────
final debtRepositoryProvider = Provider<DebtRepository>((ref) {
  return DebtRepositoryImpl(ref.read(dioProvider));
});

// ── Read-Only Providers ──────────────────────────────────────────────
final debtListProvider = FutureProvider.autoDispose<List<Debt>>((ref) async {
  final repository = ref.watch(debtRepositoryProvider);
  final result = await repository.getDebts();
  return result.fold((failure) => throw failure.message, (debts) => debts);
});

final debtDetailProvider = FutureProvider.family.autoDispose<Debt, String>((
  ref,
  id,
) async {
  final repository = ref.watch(debtRepositoryProvider);
  final result = await repository.getDebtById(id);
  return result.fold((failure) => throw failure.message, (debt) => debt);
});

final customerDebtsProvider = FutureProvider.family
    .autoDispose<List<Debt>, String>((ref, customerId) async {
      final repository = ref.watch(debtRepositoryProvider);
      final result = await repository.getDebts(customerId: customerId);
      return result.fold((failure) => throw failure.message, (debts) => debts);
    });

// ── AsyncNotifier for CRUD ───────────────────────────────────────────
class DebtController extends AutoDisposeAsyncNotifier<void> {
  late DebtRepository _repository;

  @override
  FutureOr<void> build() {
    _repository = ref.watch(debtRepositoryProvider);
  }

  Future<void> createDebt({
    required String customerId,
    required double amount,
    String? description,
    String? dueDate,
  }) async {
    state = const AsyncLoading();
    final result = await _repository.createDebt(
      customerId: customerId,
      amount: amount,
      description: description,
      dueDate: dueDate,
    );

    state = result.fold(
      (failure) => AsyncError(failure.message, StackTrace.current),
      (debt) {
        ref.invalidate(debtListProvider);
        return const AsyncData(null);
      },
    );
  }
}

final debtControllerProvider =
    AsyncNotifierProvider.autoDispose<DebtController, void>(() {
      return DebtController();
    });
