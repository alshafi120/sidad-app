/// State management for customers.
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/api_error_parser.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/entities/customer_dashboard_entity.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../data/repositories/customer_repository_impl.dart';
import '../../data/models/customer_dashboard_model.dart';

import '../../../../core/network/network_info.dart';
import '../../../../core/local_db/local_database_service.dart';

// ── Repository Provider ──────────────────────────────────────────────
final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepositoryImpl(
    ref.read(dioProvider),
    ref.read(networkInfoProvider),
    ref.read(localDatabaseProvider),
  );
});

// ── Read-Only Providers ──────────────────────────────────────────────
final customerListProvider = FutureProvider.autoDispose<List<Customer>>((
  ref,
) async {
  final repository = ref.watch(customerRepositoryProvider);
  final result = await repository.getCustomers();
  return result.fold(
    (failure) => throw failure.message,
    (customers) => customers,
  );
});

final customerDetailProvider = FutureProvider.family
    .autoDispose<Customer, String>((ref, id) async {
      final repository = ref.watch(customerRepositoryProvider);
      final result = await repository.getCustomerById(id);
      return result.fold(
        (failure) => throw failure.message,
        (customer) => customer,
      );
    });

final customerDashboardProvider =
    FutureProvider.autoDispose<CustomerDashboardData>((ref) async {
      final dio = ref.watch(dioProvider);
      try {
        final response = await dio.get(ApiEndpoints.customerDashboard);
        final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
          response.data,
          (data) => data as Map<String, dynamic>,
        );
        if (apiResponse.success && apiResponse.data != null) {
          return CustomerDashboardModel.fromJson(apiResponse.data!);
        } else {
          throw apiResponse.message;
        }
      } catch (e) {
        throw ApiErrorParser.parse(e).message;
      }
    });

// ── AsyncNotifier for CRUD ───────────────────────────────────────────
class CustomerController extends AutoDisposeAsyncNotifier<void> {
  late CustomerRepository _repository;

  @override
  FutureOr<void> build() {
    _repository = ref.watch(customerRepositoryProvider);
  }

  Future<void> createCustomer({
    required String name,
    required String phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    state = const AsyncLoading();
    final result = await _repository.createCustomer(
      name: name,
      phone: phone,
      email: email,
      address: address,
      notes: notes,
    );

    state = result.fold(
      (failure) => AsyncError(failure.message, StackTrace.current),
      (customer) {
        // Invalidate list to refresh
        ref.invalidate(customerListProvider);
        return const AsyncData(null);
      },
    );
  }

  Future<void> updateCustomer({
    required String id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    state = const AsyncLoading();
    final result = await _repository.updateCustomer(
      id: id,
      name: name,
      phone: phone,
      email: email,
      address: address,
      notes: notes,
    );

    state = result.fold(
      (failure) => AsyncError(failure.message, StackTrace.current),
      (customer) {
        // Invalidate list and specific details
        ref.invalidate(customerListProvider);
        ref.invalidate(customerDetailProvider(id));
        return const AsyncData(null);
      },
    );
  }

  Future<void> deleteCustomer(String id) async {
    state = const AsyncLoading();
    final result = await _repository.deleteCustomer(id);

    state = result.fold(
      (failure) => AsyncError(failure.message, StackTrace.current),
      (_) {
        ref.invalidate(customerListProvider);
        return const AsyncData(null);
      },
    );
  }

  Future<bool> linkCustomer(
    String id, {
    String? phone,
    String? linkCode,
  }) async {
    state = const AsyncLoading();
    final result = await _repository.linkCustomerAccount(
      id,
      phone: phone,
      linkCode: linkCode,
    );

    bool success = false;
    state = result.fold(
      (failure) => AsyncError(failure.message, StackTrace.current),
      (customer) {
        success = true;
        ref.invalidate(customerListProvider);
        ref.invalidate(customerDetailProvider(id));
        return const AsyncData(null);
      },
    );
    return success;
  }

  Future<bool> linkMerchant(String merchantCode) async {
    state = const AsyncLoading();
    final result = await _repository.linkMerchant(merchantCode);

    bool success = false;
    state = result.fold(
      (failure) => AsyncError(failure.message, StackTrace.current),
      (_) {
        success = true;
        ref.invalidate(customerDashboardProvider);
        return const AsyncData(null);
      },
    );
    return success;
  }
}

final customerControllerProvider =
    AsyncNotifierProvider.autoDispose<CustomerController, void>(() {
      return CustomerController();
    });
