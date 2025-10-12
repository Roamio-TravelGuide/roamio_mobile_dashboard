import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const int _timeoutSeconds = 30;
  static const String _contentType = 'application/json';
  static const String _accept = 'application/json';

  final String baseUrl;
  String? token;

  ApiClient({String? customBaseUrl, this.token})
      : baseUrl = customBaseUrl ??
            const String.fromEnvironment(
              'VITE_API_URL',
              defaultValue: "http://localhost:3001/api/v1",
            );

  // Helper method to get token from storage
  Future<String?> _getTokenFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('authToken');
    } catch (e) {
      print("Error reading token from storage: $e");
      return null;
    }
  }

  // Build headers with token
  Future<Map<String, String>> _getHeaders() async {
    final headers = {
      'Content-Type': _contentType,
      'Accept': _accept,
    };

    final authToken = token ?? await _getTokenFromStorage();
    print('🔑 Auth Token: ${authToken?.substring(0, 10)}...');  // Only show first 10 chars for security
    
    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
      print('📨 Headers set with Authorization token');
    } else {
      print('⚠️ No auth token available for request');
    }

    return headers;
  }

  // Handle responses
  void _handleResponse(http.Response response) {
    if (response.statusCode == 401) {
      print('⚠️ Unauthorized access - possibly expired token');
    }
  }

  Future<http.Response> get(String endpoint,
      {Map<String, String>? queryParameters}) async {
    final headers = await _getHeaders();
    final uri =
        Uri.parse('$baseUrl$endpoint').replace(queryParameters: queryParameters);

    print("➡️ GET Request: $uri"); // ✅ Debug

    try {
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: _timeoutSeconds));

      _handleResponse(response);
      return response;
    } catch (error) {
      print("❌ GET Error: $error");
      rethrow;
    }
  }

  Future<http.Response> post(String endpoint, dynamic data) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl$endpoint');

    print("➡️ POST Request: $uri with data: $data"); // ✅ Debug

    try {
      final response = await http
          .post(uri, headers: headers, body: json.encode(data))
          .timeout(const Duration(seconds: _timeoutSeconds));

      _handleResponse(response);
      return response;
    } catch (error) {
      print("❌ POST Error: $error");
      rethrow;
    }
  }

  Future<http.Response> put(String endpoint, dynamic data) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl$endpoint');

    print("➡️ PUT Request URL: $uri");
    print("➡️ PUT Request Headers: $headers");
    final encodedData = json.encode(data);
    print("➡️ PUT Request Body: $encodedData");
    print("➡️ PUT Request Body Type: ${encodedData.runtimeType}");

    try {
      final response = await http
          .put(uri, headers: headers, body: encodedData)
          .timeout(const Duration(seconds: _timeoutSeconds));

      print("📥 Response Status: ${response.statusCode}");
      print("📥 Response Headers: ${response.headers}");
      print("📥 Response Body: ${response.body}");
      if (response.statusCode != 200) {
        print("❌ Error Details:");
        print("  - Status Code: ${response.statusCode}");
        print("  - Response Type: ${response.body.runtimeType}");
        print("  - Content-Type: ${response.headers['content-type']}");
      }

      _handleResponse(response);
      return response;
    } catch (error) {
      print("❌ PUT Error: $error");
      rethrow;
    }
  }

  Future<http.Response> patch(String endpoint, dynamic data) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl$endpoint');

    print("➡️ PATCH Request: $uri with data: $data");

    try {
      final response = await http
          .patch(uri, headers: headers, body: json.encode(data))
          .timeout(const Duration(seconds: _timeoutSeconds));

      _handleResponse(response);
      return response;
    } catch (error) {
      print("❌ PATCH Error: $error");
      rethrow;
    }
  }

  Future<http.Response> delete(String endpoint, {dynamic data}) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl$endpoint');

    print("➡️ DELETE Request: $uri with data: $data");

    try {
      final request = http.Request('DELETE', uri);
      request.headers.addAll(headers);

      if (data != null) {
        request.body = json.encode(data);
      }

      final response = await http.Response.fromStream(await request.send())
          .timeout(const Duration(seconds: _timeoutSeconds));

      _handleResponse(response);
      return response;
    } catch (error) {
      print("❌ DELETE Error: $error");
      rethrow;
    }
  }

  // Method to update token
  void updateToken(String newToken) {
    token = newToken;
  }

  // Method to clear token
  void clearToken() {
    token = null;
  }
}
