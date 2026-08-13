import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_error_parser.dart';
import '../../../../core/network/api_response.dart';
import '../models/notification_model.dart';

abstract interface class NotificationRepository {
  Future<Either<Failure, List<NotificationModel>>> getNotifications();
}

class NotificationRepositoryImpl implements NotificationRepository {
  final Dio _dio;

  NotificationRepositoryImpl(this._dio);

  @override
  Future<Either<Failure, List<NotificationModel>>> getNotifications() async {
    try {
      final response = await _dio.get(ApiEndpoints.notifications);

      final apiResponse = ApiResponse<List<NotificationModel>>.fromJson(
        response.data,
        (data) {
          final list = (data is Map && data['data'] is List)
              ? data['data'] as List
              : (data as List);
          return list.map((e) => NotificationModel.fromJson(e)).toList();
        },
      );

      if (apiResponse.success && apiResponse.data != null) {
        return Right(apiResponse.data!);
      } else {
        return Left(ServerFailure(apiResponse.message));
      }
    } catch (e) {
      return Left(ApiErrorParser.parse(e));
    }
  }
}
