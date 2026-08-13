/// Network error types for clean error handling.
library;

abstract class Failure {
  final String message;
  final int? statusCode;
  const Failure(this.message, [this.statusCode]);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'حدث خطأ في الخادم']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'لا يوجد اتصال بالإنترنت']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'خطأ في المصادقة']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'خطأ في البيانات المحفوظة']);
}

class ValidationFailure extends Failure {
  final Map<String, List<String>>? errors;
  const ValidationFailure({
    String message = 'خطأ في البيانات المدخلة',
    this.errors,
  }) : super(message);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'حدث خطأ غير متوقع']);
}

/// Server exception thrown from the data layer.
class ServerException implements Exception {
  final String message;
  final int? statusCode;
  const ServerException([this.message = 'Server error', this.statusCode]);
}

class NetworkException implements Exception {
  const NetworkException([this.message = 'No connection']);
  final String message;
}

class CacheException implements Exception {
  const CacheException([this.message = 'Cache error']);
  final String message;
}
