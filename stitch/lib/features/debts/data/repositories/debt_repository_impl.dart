/// Debt API implementation.
library;

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_error_parser.dart';
import '../../../../core/network/api_response.dart';
import '../../domain/entities/debt_entity.dart';
import '../../domain/repositories/debt_repository.dart';
import '../mappers/debt_mapper.dart';
import '../models/debt_model.dart';

class DebtRepositoryImpl implements DebtRepository {
  final Dio _dio;

  DebtRepositoryImpl(this._dio);

  @override
  Future<Either<Failure, List<Debt>>> getDebts({
    int page = 1,
    String? status,
    String? customerId,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.debts,
        queryParameters: {
          'page': page,
          if (status != null && status.isNotEmpty) 'status': status,
          if (customerId != null && customerId.isNotEmpty)
            'customer_id': customerId,
        },
      );

      final apiResponse = ApiResponse<List<DebtModel>>.fromJson(response.data, (
        data,
      ) {
        final list = (data is Map && data['data'] is List)
            ? data['data'] as List
            : (data as List);
        return list.map((e) => DebtModel.fromJson(e)).toList();
      });

      if (apiResponse.success && apiResponse.data != null) {
        final debts = apiResponse.data!
            .map((m) => DebtMapper.toEntity(m))
            .toList();
        return Right(debts);
      } else {
        return Left(ServerFailure(apiResponse.message));
      }
    } catch (e) {
      return Left(ApiErrorParser.parse(e));
    }
  }

  @override
  Future<Either<Failure, Debt>> getDebtById(String id) async {
    try {
      final response = await _dio.get(ApiEndpoints.debtById(id));

      final apiResponse = ApiResponse<DebtModel>.fromJson(
        response.data,
        (data) => DebtModel.fromJson(data),
      );

      if (apiResponse.success && apiResponse.data != null) {
        return Right(DebtMapper.toEntity(apiResponse.data!));
      } else {
        return Left(ServerFailure(apiResponse.message));
      }
    } catch (e) {
      return Left(ApiErrorParser.parse(e));
    }
  }

  @override
  Future<Either<Failure, Debt>> createDebt({
    required String customerId,
    required double amount,
    String? description,
    String? dueDate,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.debts,
        data: {
          'customer_id': customerId,
          'amount': amount,
          if (description != null) 'description': description,
          if (dueDate != null) 'due_date': dueDate,
        },
      );

      final apiResponse = ApiResponse<DebtModel>.fromJson(
        response.data,
        (data) => DebtModel.fromJson(data),
      );

      if (apiResponse.success && apiResponse.data != null) {
        return Right(DebtMapper.toEntity(apiResponse.data!));
      } else {
        return Left(ServerFailure(apiResponse.message));
      }
    } catch (e) {
      return Left(ApiErrorParser.parse(e));
    }
  }
}
