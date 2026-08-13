/// Dio-based HTTP client with interceptors, token management, and error handling.
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_endpoints.dart';
import '../services/secure_storage_service.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/timeout_interceptor.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));

  final secureStorage = ref.read(secureStorageProvider);

  dio.interceptors.addAll([
    TimeoutInterceptor(),
    AuthInterceptor(secureStorage),
    ErrorInterceptor(
      secureStorage,
      onUnauthenticated: () {
        // We will trigger a logout or state reset here if needed.
        // For now, the interceptor clears storage. The app state should react to the token missing.
        // If there's an auth controller listening to token state, it will handle redirection.
      },
    ),
    if (kDebugMode) LoggingInterceptor(),
  ]);

  return dio;
});

/// Development-only request/response logger.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // ignore: avoid_print
    print('→ ${options.method} ${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // ignore: avoid_print
    print('← ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // ignore: avoid_print
    print('✗ ${err.response?.statusCode} ${err.requestOptions.path}');
    handler.next(err);
  }
}
