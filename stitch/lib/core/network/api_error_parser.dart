/// Centralized parser for network errors and exceptions.
library;

import 'package:dio/dio.dart';
import '../errors/failures.dart';

class ApiErrorParser {
  static Failure parse(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return const NetworkFailure(
            'انتهت مهلة الاتصال. تحقق من اتصالك بالإنترنت.',
          );
        case DioExceptionType.connectionError:
          return const NetworkFailure('لا يوجد اتصال بالإنترنت.');
        case DioExceptionType.badResponse:
          return _parseBadResponse(error.response);
        case DioExceptionType.cancel:
          return const ServerFailure('تم إلغاء الطلب.');
        default:
          return const UnknownFailure('حدث خطأ غير متوقع في الشبكة.');
      }
    }
    return const UnknownFailure('حدث خطأ غير متوقع.');
  }

  static Failure _parseBadResponse(Response? response) {
    final statusCode = response?.statusCode;
    final data = response?.data;

    final message = (data is Map<String, dynamic> && data['message'] != null)
        ? data['message'] as String
        : 'حدث خطأ في الخادم.';

    if (statusCode == 401) {
      return const AuthFailure(
        'انتهت صلاحية الجلسة. الرجاء تسجيل الدخول مرة أخرى.',
      );
    }

    if (statusCode == 422 && data is Map<String, dynamic>) {
      final errors = (data['errors'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, List<String>.from(v as List)),
      );
      return ValidationFailure(message: message, errors: errors);
    }

    if (statusCode == 404) {
      return ServerFailure('العنصر غير موجود. ($message)');
    }

    if (statusCode != null && statusCode >= 500) {
      return ServerFailure('خطأ داخلي في الخادم. ($message)');
    }

    return ServerFailure(message);
  }
}
