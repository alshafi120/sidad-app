/// Handles dynamic timeout configs.
library;

import 'package:dio/dio.dart';

class TimeoutInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.connectTimeout = const Duration(seconds: 30);
    options.receiveTimeout = const Duration(seconds: 30);
    options.sendTimeout = const Duration(seconds: 30);
    handler.next(options);
  }
}
