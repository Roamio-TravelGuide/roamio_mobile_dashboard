import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/api/api_client.dart';

class AuthApi {
  final ApiClient apiClient;

  AuthApi({required this.apiClient});


  //signup API call
  Future<Map<String, dynamic>> signup({
    required String email,
    required String password,
    required String name,
    required String role,
    required String phoneNo,
  }) async {
    try {
      final response = await apiClient.post(
        '/auth/signup',
        {
          'email': email,
          'password': password,
          'name': name,
          'role': role,
          'phone_no': phoneNo,
        },
      );

      final responseData = json.decode(response.body);
      
      return {
        'success': response.statusCode == 201,
        'statusCode': response.statusCode,
        'data': responseData,
        'message': responseData['message'] ?? (response.statusCode == 201 ? 'Signup successful' : 'Signup failed'),
      };
    } catch (error) {
      return {
        'success': false,
        'message': 'Network error: ${error.toString()}',
        'error': error,
      };
    }
  }

  // Login API call
  // Login API call
Future<Map<String, dynamic>> login({
  required String email,
  required String password,
  required String role,
}) async {
  try {
    final response = await apiClient.post(
      '/auth/login',
      {
        'email': email,
        'password': password,
        'role': role,
      },
    );

    final responseData = json.decode(response.body);

    // ✅ Only allow traveler and travel_guide
    if (role == "traveler" || role == "travel_guide") {
      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': responseData,
        'message': responseData['message'] ??
            (response.statusCode == 200 ? 'Login successful' : 'Login failed'),
      };
    } else {
      // ❌ Block other roles
      return {
        'success': false,
        'statusCode': 403, // Forbidden
        'data': null,
        'message': 'Login not allowed for this role',
      };
    }
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