import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // ← For kDebugMode
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'api_endpoints.dart';

class ApiClient {
  static final Dio _dio = Dio();

  static Dio get client {
    _dio.options = BaseOptions(
      baseUrl: ApiEndpoints.baseUrl, // Ensure ApiEndpoints exists
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    _dio.interceptors.addAll([
      AuthInterceptor(), // Ensure this class exists
      if (kDebugMode) LoggingInterceptor(), // Now works with flutter/foundation
    ]);

    return _dio;
  }
}