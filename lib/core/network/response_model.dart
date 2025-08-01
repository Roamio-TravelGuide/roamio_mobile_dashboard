// lib/core/network/response_model.dart

class ApiResponse<T> {
  final T? data;
  final String? error;
  final int statusCode;
  final dynamic rawData; // Original response

  ApiResponse({
    this.data,
    this.error,
    required this.statusCode,
    this.rawData,
  });

  bool get isSuccess => error == null;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJson, // Data parser
  ) {
    try {
      return ApiResponse(
        statusCode: json['statusCode'] ?? 200,
        data: json['data'] != null ? fromJson(json['data']) : null,
        error: json['error'],
        rawData: json,
      );
    } catch (e) {
      return ApiResponse(
        statusCode: 500, 
        error: 'Failed to parse response: $e',
        rawData: json,
      );
    }
  }
}