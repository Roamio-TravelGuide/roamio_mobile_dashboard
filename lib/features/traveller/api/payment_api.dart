// lib/features/traveller/api/payment_api.dart
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

class PaymentApi {
  final Dio _dio = ApiClient.client;

  Future<Map<String, dynamic>> createPaymentIntent(double amount, String currency, Map<String, dynamic> metadata) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.createPaymentIntent,
        data: {
          'amount': amount,
          'currency': currency,
          'metadata': metadata,
        },
      );
      
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Failed to create payment intent: ${e.response?.data?['error'] ?? e.message}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }
  }
}