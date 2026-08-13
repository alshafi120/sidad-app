/// Global error handling interceptor (e.g., 401 unauthenticated).
library;

import 'package:dio/dio.dart';
import '../../services/secure_storage_service.dart';

class ErrorInterceptor extends Interceptor {
  final SecureStorageService _storage;
  final void Function() onUnauthenticated;

  ErrorInterceptor(this._storage, {required this.onUnauthenticated});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Token expired or invalid — clear storage and notify app
      await _storage.clearAll();
      onUnauthenticated();
    }
    handler.next(err);
  }
}
