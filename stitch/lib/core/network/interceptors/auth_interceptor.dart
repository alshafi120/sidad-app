/// Injects Authorization header and handles token refresh.
library;

import 'package:dio/dio.dart';
import '../../services/secure_storage_service.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService _storage;

  AuthInterceptor(this._storage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // Set default headers if not provided
    options.headers['Accept'] ??= 'application/json';
    options.headers['Content-Type'] ??= 'application/json';
    options.headers['Bypass-Tunnel-Reminder'] = 'true';

    handler.next(options);
  }
}
