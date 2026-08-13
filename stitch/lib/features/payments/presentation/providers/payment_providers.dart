/// State management for payments.
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/repositories/payment_repository.dart';
import '../../data/repositories/payment_repository_impl.dart';
import '../../../debts/presentation/providers/debt_providers.dart';
import '../../../customer/presentation/providers/customer_providers.dart';

// ── Repository Provider ──────────────────────────────────────────────
final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepositoryImpl(ref.read(dioProvider));
});

// ── Read-Only Providers ──────────────────────────────────────────────
final paymentListProvider = FutureProvider.family
    .autoDispose<List<Payment>, String>((ref, debtId) async {
      final repository = ref.watch(paymentRepositoryProvider);
      final result = await repository.getPaymentsByDebt(debtId);
      return result.fold(
        (failure) => throw failure.message,
        (payments) => payments,
      );
    });

// ── AsyncNotifier for Transactions ───────────────────────────────────
class PaymentController extends AutoDisposeAsyncNotifier<void> {
  late PaymentRepository _repository;

  @override
  FutureOr<void> build() {
    _repository = ref.watch(paymentRepositoryProvider);
  }

  Future<void> recordPayment({
    required String debtId,
    required double amount,
    String? receiptNumber,
    String? notes,
  }) async {
    state = const AsyncLoading();
    final result = await _repository.recordPayment(
      debtId: debtId,
      amount: amount,
      receiptNumber: receiptNumber,
      notes: notes,
    );

    state = result.fold(
      (failure) => AsyncError(failure.message, StackTrace.current),
      (payment) {
        // Sync / Refresh related data models after a successful payment
        ref.invalidate(paymentListProvider(debtId));
        ref.invalidate(debtDetailProvider(debtId));
        ref.invalidate(debtListProvider);
        // We could invalidate customer stats if needed, or entire dashboard.
        ref.invalidate(customerListProvider);

        return const AsyncData(null);
      },
    );
  }
}

final paymentControllerProvider =
    AsyncNotifierProvider.autoDispose<PaymentController, void>(() {
      return PaymentController();
    });
