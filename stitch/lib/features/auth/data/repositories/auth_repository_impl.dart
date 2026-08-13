/// API auth repository implementation.
library;

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_error_parser.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../mappers/user_mapper.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final Dio _dio;
  final SecureStorageService _storage;

  AuthRepositoryImpl(this._dio, this._storage);

  @override
  Future<Either<Failure, User>> login(String email, String password) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: {
          'email': email,
          'password': password,
          'device_name': 'sidad_flutter_app',
        },
      );

      final apiResponse = ApiResponse<String>.fromJson(
        response.data,
        (data) => data['token'] as String, // Assuming token is in data.token
      );

      if (apiResponse.success && apiResponse.data != null) {
        await _storage.saveAccessToken(apiResponse.data!);

        final userJson = response.data['data']?['user'];
        if (userJson is Map<String, dynamic>) {
          final userEntity = UserMapper.toEntity(UserModel.fromJson(userJson));
          await _persistUser(userEntity);
          return Right(userEntity);
        }

        return await getCurrentUser();
      } else {
        return Left(AuthFailure(apiResponse.message));
      }
    } catch (e) {
      if (e is DioException &&
          (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.unknown)) {
        return const Left(
          AuthFailure(
            'No internet connection. Please connect to the internet to login.',
          ),
        );
      }
      return Left(ApiErrorParser.parse(e));
    }
  }

  @override
  Future<Either<Failure, User>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.register,
        data: {
          'full_name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'password_confirmation': password,
          'role': role == UserRole.merchant
              ? 'merchant'
              : (role == UserRole.admin ? 'admin' : 'customer'),
        },
      );

      final apiResponse = ApiResponse<String>.fromJson(
        response.data,
        (data) => data['token'] as String,
      );

      if (apiResponse.success && apiResponse.data != null) {
        await _storage.saveAccessToken(apiResponse.data!);
        final userJson = response.data['data']?['user'];
        if (userJson is Map<String, dynamic>) {
          final userEntity = UserMapper.toEntity(UserModel.fromJson(userJson));
          await _persistUser(userEntity);
          return Right(userEntity);
        }

        return await getCurrentUser();
      } else {
        return Left(AuthFailure(apiResponse.message));
      }
    } catch (e) {
      return Left(ApiErrorParser.parse(e));
    }
  }

  @override
  Future<Either<Failure, String>> sendOtp(String identifier) async {
    try {
      await _dio.post(ApiEndpoints.resendOtp);
      return const Right('تم إرسال رمز التحقق بنجاح');
    } catch (e) {
      return Left(ApiErrorParser.parse(e));
    }
  }

  @override
  Future<Either<Failure, User>> verifyOtp(String identifier, String otp) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.verifyOtp,
        data: {'code': otp},
      );

      final userJson = response.data['data']?['user'];
      if (userJson is Map<String, dynamic>) {
        final userEntity = UserMapper.toEntity(UserModel.fromJson(userJson));
        await _persistUser(userEntity);
        return Right(userEntity);
      }

      return await getCurrentUser();
    } catch (e) {
      return Left(ApiErrorParser.parse(e));
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      final response = await _dio.get(ApiEndpoints.profile);

      final apiResponse = ApiResponse<UserModel>.fromJson(
        response.data,
        (data) => UserModel.fromJson(data),
      );

      if (apiResponse.success && apiResponse.data != null) {
        final userEntity = UserMapper.toEntity(apiResponse.data!);
        await _persistUser(userEntity);
        return Right(userEntity);
      } else {
        return Left(ServerFailure(apiResponse.message));
      }
    } catch (e) {
      return Left(ApiErrorParser.parse(e));
    }
  }

  @override
  Future<Either<Failure, void>> setUserRole(UserRole role) async {
    await _storage.saveUserRole(
      role == UserRole.merchant
          ? 'merchant'
          : (role == UserRole.admin ? 'admin' : 'customer'),
    );
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _dio.post(ApiEndpoints.logout);
    } catch (e) {
      // Ignore errors on logout (e.g. token already expired)
    } finally {
      await _storage.clearAll();
    }
    return const Right(null);
  }

  @override
  Future<bool> isLoggedIn() async {
    return await _storage.hasToken();
  }

  Future<void> _persistUser(User user) async {
    await _storage.saveUserId(user.id);
    await _storage.saveUserRole(
      user.role == UserRole.merchant
          ? 'merchant'
          : (user.role == UserRole.admin ? 'admin' : 'customer'),
    );

    final userMap = {
      'id': user.id,
      'name': user.name,
      'phone': user.phone,
      'role': user.role.name,
      'avatarUrl': user.avatarUrl,
      'createdAt': user.createdAt.toIso8601String(),
    };
    await _storage.saveOfflineUser(jsonEncode(userMap));
  }
  @override
  Future<Either<Failure, User>> getCachedUser() async {
    try {
      final userJson = await _storage.getOfflineUser();
      if (userJson == null) {
        return const Left(AuthFailure('لا توجد بيانات مستخدم محفوظة.'));
      }
      final map = jsonDecode(userJson) as Map<String, dynamic>;
      final roleStr = map['role'] as String? ?? 'customer';
      final role = roleStr == 'merchant'
          ? UserRole.merchant
          : (roleStr == 'admin' ? UserRole.admin : UserRole.customer);
      final user = User(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        phone: map['phone'] as String? ?? '',
        role: role,
        avatarUrl: map['avatarUrl'] as String?,
        createdAt: map['createdAt'] != null
            ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
      return Right(user);
    } catch (e) {
      return const Left(AuthFailure('فشل في قراءة بيانات المستخدم المحفوظة.'));
    }
  }
}
