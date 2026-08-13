/// Payment API implementation.
library;

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_error_parser.dart';
import '../../../../core/network/api_response.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/repositories/payment_repository.dart';
import '../mappers/payment_mapper.dart';
import '../models/payment_model.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final Dio _dio;

  PaymentRepositoryImpl(this._dio);

  @override
  Future<Either<Failure, List<Payment>>> getPaymentsByDebt(
    String debtId,
  ) async {
    try {
      final response = await _dio.get(ApiEndpoints.paymentsByDebt(debtId));

      final apiResponse = ApiResponse<List<PaymentModel>>.fromJson(
        response.data,
        (data) {
          final list = (data is Map && data['data'] is List)
              ? data['data'] as List
              : (data as List);
          return list.map((e) => PaymentModel.fromJson(e)).toList();
        },
      );

      if (apiResponse.success && apiResponse.data != null) {
        final payments = apiResponse.data!
            .map((m) => PaymentMapper.toEntity(m))
            .toList();
        return Right(payments);
      } else {
        return Left(ServerFailure(apiResponse.message));
      }
    } catch (e) {
      return Left(ApiErrorParser.parse(e));
    }
  }

  @override
  Future<Either<Failure, Payment>> recordPayment({
    required String debtId,
    required double amount,
    String? receiptNumber,
    String? notes,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.payments,
        data: {
          'debt_id': debtId,
          'amount': (amount * 100).round(),
          'payment_method': 'cash',
          if (receiptNumber != null) 'transaction_reference': receiptNumber,
          if (notes != null) 'notes': notes,
        },
      );

      final apiResponse = ApiResponse<PaymentModel>.fromJson(
        response.data,
        (data) => PaymentModel.fromJson(data),
      );

      if (apiResponse.success && apiResponse.data != null) {
        return Right(PaymentMapper.toEntity(apiResponse.data!));
      } else {
        return Left(ServerFailure(apiResponse.message));
      }
    } catch (e) {
      return Left(ApiErrorParser.parse(e));
    }
  }
}
