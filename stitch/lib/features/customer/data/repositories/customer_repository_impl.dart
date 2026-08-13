/// Customer API implementation.
library;

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_error_parser.dart';
import '../../../../core/network/api_response.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/local_db/local_database_service.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/repositories/customer_repository.dart';
import '../mappers/customer_mapper.dart';
import '../models/customer_model.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final Dio _dio;
  final NetworkInfo _networkInfo;
  final LocalDatabaseService _localDb;

  CustomerRepositoryImpl(this._dio, this._networkInfo, this._localDb);

  @override
  Future<Either<Failure, List<Customer>>> getCustomers({
    int page = 1,
    String? search,
  }) async {
    try {
      final isConnected = await _networkInfo.isConnected;

      if (!isConnected) {
        final localData = await _localDb.getCustomers();
        final models = localData.map((e) => CustomerModel.fromJson(e)).toList();
        final customers = models
            .map((m) => CustomerMapper.toEntity(m))
            .toList();
        return Right(customers);
      }

      final response = await _dio.get(
        ApiEndpoints.customers,
        queryParameters: {
          'page': page,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );

      final apiResponse = ApiResponse<List<CustomerModel>>.fromJson(
        response.data,
        (data) {
          final list = (data is Map && data['data'] is List)
              ? data['data'] as List
              : (data as List);
          return list.map((e) => CustomerModel.fromJson(e)).toList();
        },
      );

      if (apiResponse.success && apiResponse.data != null) {
        // Sync local DB with fresh data
        for (var model in apiResponse.data!) {
          await _localDb.saveCustomer(model.toJson());
        }

        final customers = apiResponse.data!
            .map((m) => CustomerMapper.toEntity(m))
            .toList();
        return Right(customers);
      } else {
        return Left(ServerFailure(apiResponse.message));
      }
    } catch (e) {
      return Left(ApiErrorParser.parse(e));
    }
  }

  @override
  Future<Either<Failure, Customer>> getCustomerById(String id) async {
    try {
      final response = await _dio.get(ApiEndpoints.customerById(id));

      final apiResponse = ApiResponse<CustomerModel>.fromJson(
        response.data,
        (data) => CustomerModel.fromJson(data),
      );

      if (apiResponse.success && apiResponse.data != null) {
        return Right(CustomerMapper.toEntity(apiResponse.data!));
      } else {
        return Left(ServerFailure(apiResponse.message));
      }
    } catch (e) {
      return Left(ApiErrorParser.parse(e));
    }
  }

  @override
  Future<Either<Failure, Customer>> createCustomer({
    required String name,
    required String phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    try {
      final payload = {
        'full_name': name,
        'phone': phone,
        if (email != null) 'email': email,
        if (address != null) 'address': address,
        if (notes != null) 'notes': notes,
      };

      final isConnected = await _networkInfo.isConnected;

      if (!isConnected) {
        // Offline creation
        final offlineId = const Uuid().v4();
        final now = DateTime.now().toIso8601String();

        final offlinePayload = Map<String, dynamic>.from(payload);
        offlinePayload['offline_id'] = offlineId;

        final localCustomer = CustomerModel(
          id: offlineId, // temporary id
          name: name,
          phone: phone,
          email: email,
          address: address,
          notes: notes,
          createdAt: now,
          isSynced: false,
          offlineId: offlineId,
        );

        await _localDb.saveCustomer(localCustomer.toJson());
        await _localDb.addSyncJob('CREATE', 'customer', offlinePayload);

        return Right(CustomerMapper.toEntity(localCustomer));
      }

      final response = await _dio.post(ApiEndpoints.customers, data: payload);

      final apiResponse = ApiResponse<CustomerModel>.fromJson(
        response.data,
        (data) => CustomerModel.fromJson(data),
      );

      if (apiResponse.success && apiResponse.data != null) {
        await _localDb.saveCustomer(apiResponse.data!.toJson());
        return Right(CustomerMapper.toEntity(apiResponse.data!));
      } else {
        return Left(ServerFailure(apiResponse.message));
      }
    } catch (e) {
      return Left(ApiErrorParser.parse(e));
    }
  }

  @override
  Future<Either<Failure, Customer>> updateCustomer({
    required String id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.customerById(id),
        data: {
          if (name != null) 'full_name': name,
          if (phone != null) 'phone': phone,
          if (email != null) 'email': email,
          if (address != null) 'address': address,
          if (notes != null) 'notes': notes,
        },
      );

      final apiResponse = ApiResponse<CustomerModel>.fromJson(
        response.data,
        (data) => CustomerModel.fromJson(data),
      );

      if (apiResponse.success && apiResponse.data != null) {
        return Right(CustomerMapper.toEntity(apiResponse.data!));
      } else {
        return Left(ServerFailure(apiResponse.message));
      }
    } catch (e) {
      return Left(ApiErrorParser.parse(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCustomer(String id) async {
    try {
      final response = await _dio.delete(ApiEndpoints.customerById(id));
      final apiResponse = ApiResponse.fromJson(response.data, null);

      if (apiResponse.success) {
        return const Right(null);
      } else {
        return Left(ServerFailure(apiResponse.message));
      }
    } catch (e) {
      return Left(ApiErrorParser.parse(e));
    }
  }

  @override
  Future<Either<Failure, Customer>> linkCustomerAccount(
    String id, {
    String? phone,
    String? linkCode,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.linkCustomer(id),
        data: {
          if (phone != null) 'phone': phone,
          if (linkCode != null) 'link_code': linkCode,
        },
      );

      final apiResponse = ApiResponse<CustomerModel>.fromJson(
        response.data,
        (data) => CustomerModel.fromJson(data),
      );

      if (apiResponse.success && apiResponse.data != null) {
        return Right(CustomerMapper.toEntity(apiResponse.data!));
      } else {
        return Left(ServerFailure(apiResponse.message));
      }
    } catch (e) {
      return Left(ApiErrorParser.parse(e));
    }
  }

  @override
  Future<Either<Failure, void>> linkMerchant(String merchantCode) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.linkMerchant,
        data: {'merchant_code': merchantCode},
      );

      final apiResponse = ApiResponse.fromJson(response.data, null);

      if (apiResponse.success) {
        return const Right(null);
      } else {
        return Left(ServerFailure(apiResponse.message));
      }
    } catch (e) {
      return Left(ApiErrorParser.parse(e));
    }
  }
}
