/// Dashboard API implementation.
library;

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_error_parser.dart';
import '../../../../core/network/api_response.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../presentation/providers/dashboard_provider.dart';
import '../../../customer/data/models/customer_model.dart';
import '../../../customer/data/mappers/customer_mapper.dart';
import '../../../debts/data/models/debt_model.dart';
import '../../../debts/data/mappers/debt_mapper.dart';

class DashboardServiceImpl implements DashboardRepository {
  final Dio _dio;

  DashboardServiceImpl(this._dio);

  @override
  Future<Either<Failure, DashboardData>> getDashboardSummary() async {
    try {
      // In a real scenario, the backend should have a /dashboard endpoint that aggregates this.
      // If the backend doesn't have it yet, we fetch customers and debts and aggregate them here.
      // Assuming a /dashboard endpoint exists returning structured data:

      final response = await _dio.get(
        ApiEndpoints.merchantDashboard,
      );

      final apiResponse = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );

      if (apiResponse.success && apiResponse.data != null) {
        final data = apiResponse.data!;

        final topCustomersModels =
            (data['top_customers'] as List?)
                ?.map((e) => CustomerModel.fromJson(e))
                .toList() ??
            [];
        final recentDebtsModels =
            (data['recent_transactions'] as List?)
                ?.map((e) => DebtModel.fromJson(e))
                .toList() ??
            [];

        return Right(
          DashboardData(
            totalDebts: (data['total_debts'] as num?)?.toDouble() ?? 0.0,
            settledDebts: (data['settled_debts'] as num?)?.toDouble() ?? 0.0,
            pendingDebts: (data['pending_debts'] as num?)?.toDouble() ?? 0.0,
            activeCustomers: data['active_customers'] as int? ?? 0,
            recentTransactions: recentDebtsModels
                .map((m) => DebtMapper.toEntity(m))
                .toList(),
            topCustomers: topCustomersModels
                .map((m) => CustomerMapper.toEntity(m))
                .toList(),
          ),
        );
      } else {
        return Left(ServerFailure(apiResponse.message));
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Fallback: Aggregate manually if /dashboard endpoint doesn't exist yet
        return await _aggregateDashboardManually();
      }
      return Left(ApiErrorParser.parse(e));
    } catch (e) {
      return Left(ApiErrorParser.parse(e));
    }
  }

  Future<Either<Failure, DashboardData>> _aggregateDashboardManually() async {
    try {
      final customersRes = await _dio.get(ApiEndpoints.customers);
      final debtsRes = await _dio.get(ApiEndpoints.debts);

      final cResponse = ApiResponse<List<dynamic>>.fromJson(
        customersRes.data,
        (d) => (d is Map ? d['data'] : d) as List,
      );
      final dResponse = ApiResponse<List<dynamic>>.fromJson(
        debtsRes.data,
        (d) => (d is Map ? d['data'] : d) as List,
      );

      if (!cResponse.success || !dResponse.success) {
        return Left(ServerFailure('Failed to load dashboard data.'));
      }

      final customers = cResponse.data!
          .map((e) => CustomerMapper.toEntity(CustomerModel.fromJson(e)))
          .toList();
      final debts = dResponse.data!
          .map((e) => DebtMapper.toEntity(DebtModel.fromJson(e)))
          .toList();

      double total = 0;
      double settled = 0;
      double pending = 0;

      for (var debt in debts) {
        total += debt.amount;
        settled += debt.paidAmount;
        pending += (debt.amount - debt.paidAmount);
      }

      return Right(
        DashboardData(
          totalDebts: total,
          settledDebts: settled,
          pendingDebts: pending,
          activeCustomers: customers.length,
          recentTransactions: debts.take(5).toList(),
          topCustomers: customers.take(5).toList(),
        ),
      );
    } catch (e) {
      return Left(ApiErrorParser.parse(e));
    }
  }
}
