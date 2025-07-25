import 'package:dio/dio.dart';
import '../../utils/storage_helper.dart';

class AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Auto-add token to requests
    final token = await StorageHelper.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Handle 401 errors globally
    if (err.response?.statusCode == 401) {
      // Trigger logout logic
    }
    handler.next(err);
  }
}