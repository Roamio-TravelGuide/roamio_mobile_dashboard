import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/api/api_client.dart';

class AuthApi {
  final ApiClient apiClient;

  AuthApi({required this.apiClient});

  // Login API call
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await apiClient.post(
        '/auth/login',
        {
          'email': email,
          'password': password,
        },
      );

      final responseData = json.decode(response.body);
      
      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': responseData,
        'message': responseData['message'] ?? (response.statusCode == 200 ? 'Login successful' : 'Login failed'),
      };
    } catch (error) {
      return {
        'success': false,
        'message': 'Network error: ${error.toString()}',
        'error': error,
      };
    }
  }

  // Save auth data to storage
  static Future<void> saveAuthData(String token, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', token);
    await prefs.setString('userEmail', email);
  }

  // Clear auth data (logout)
  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    await prefs.remove('userEmail');
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    return token != null && token.isNotEmpty;
  }

  // Get stored token
  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }
}