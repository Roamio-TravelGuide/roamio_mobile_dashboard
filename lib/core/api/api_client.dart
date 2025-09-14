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
    : baseUrl = customBaseUrl ?? const String.fromEnvironment('VITE_API_URL');

  // Helper method to get token from storage
  Future<String?> _getTokenFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('authToken') ?? prefs.getString('authToken');
    } catch (e) {
      return null;
    }
  }

  // Request interceptor equivalent
  Future<Map<String, String>> _getHeaders() async {
    final headers = {
      'Content-Type': _contentType,
      'Accept': _accept,
    };

    // Get token from parameter, storage, or use existing
    final authToken = token ?? await _getTokenFromStorage();
    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    return headers;
  }

  // Response interceptor equivalent
  void _handleResponse(http.Response response) {
    if (response.statusCode == 401) {
      print('Unauthorized access - possibly expired token');
    }
  }

  Future<http.Response> get(String endpoint, {Map<String, String>? queryParameters}) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl$endpoint').replace(
      queryParameters: queryParameters,
    );

    try {
      final response = await http.get(uri, headers: headers)
        .timeout(const Duration(seconds: _timeoutSeconds));
      
      _handleResponse(response);
      return response;
    } catch (error) {
      rethrow;
    }
  }

  Future<http.Response> post(String endpoint, dynamic data) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode(data),
      ).timeout(const Duration(seconds: _timeoutSeconds));
      
      _handleResponse(response);
      return response;
    } catch (error) {
      rethrow;
    }
  }

  Future<http.Response> put(String endpoint, dynamic data) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await http.put(
        uri,
        headers: headers,
        body: json.encode(data),
      ).timeout(const Duration(seconds: _timeoutSeconds));
      
      _handleResponse(response);
      return response;
    } catch (error) {
      rethrow;
    }
  }

  Future<http.Response> patch(String endpoint, dynamic data) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await http.patch(
        uri,
        headers: headers,
        body: json.encode(data),
      ).timeout(const Duration(seconds: _timeoutSeconds));
      
      _handleResponse(response);
      return response;
    } catch (error) {
      rethrow;
    }
  }

  Future<http.Response> delete(String endpoint, {dynamic data}) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl$endpoint');

    try {
      final request = http.Request('DELETE', uri);
      request.headers.addAll(headers);
      
      if (data != null) {
        request.body = json.encode(data);
      }

      final response = await http.Response.fromStream(
        await request.send()
      ).timeout(const Duration(seconds: _timeoutSeconds));
      
      _handleResponse(response);
      return response;
    } catch (error) {
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