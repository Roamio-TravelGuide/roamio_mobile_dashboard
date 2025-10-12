import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/api/api_client.dart';

class AuthApi {
  final ApiClient apiClient;

  AuthApi({required this.apiClient});

  // Signup API call
  Future<Map<String, dynamic>> signup({
    required String email,
    required String password,
    required String name,
    required String role,
    required String phoneNo,
  }) async {
    try {
      final response = await apiClient.post('/auth/signup', {
        'email': email,
        'password': password,
        'name': name,
        'role': role,
        'phone_no': phoneNo,
      });

      final responseData = json.decode(response.body);

      return {
        'success': response.statusCode == 201,
        'statusCode': response.statusCode,
        'data': responseData,
        'message': responseData['message'] ??
            (response.statusCode == 201
                ? 'Signup successful'
                : 'Signup failed'),
      };
    } catch (error) {
      return {
        'success': false,
        'message': 'Network error: ${error.toString()}',
        'error': error,
      };
    }
  }

  // Login API call (only traveler & travel_guide allowed)
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      // ❌ Reject immediately if role is not allowed
      if (role != "traveler" && role != "travel_guide") {
        return {
          'success': false,
          'statusCode': 403,
          'data': null,
          'message': 'Login not allowed for this role',
        };
      }

      final response = await apiClient.post('/auth/login', {
        'email': email,
        'password': password,
        'role': role,
      });

      final responseData = json.decode(response.body);

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': responseData,
        'message': responseData['message'] ??
            (response.statusCode == 200
                ? 'Login successful'
                : 'Login failed'),
      };
    } catch (error) {
      return {
        'success': false,
        'message': 'Network error: ${error.toString()}',
        'error': error,
      };
    }
  }

  static Future<void> saveAuthData(
    String token, 
    String email, 
    Map<String, dynamic> userData
  ) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Basic auth info
    await prefs.setString('authToken', token);
    await prefs.setString('userEmail', email);
    
    // User profile data with null safety
    await prefs.setInt('userId', userData['id'] ?? 0);
    await prefs.setString('userName', userData['name'] ?? '');
    await prefs.setString('userRole', userData['role'] ?? '');
    await prefs.setString('userStatus', userData['status'] ?? '');
    
    // Optional fields
    if (userData['profile_picture_url'] != null) {
      await prefs.setString('profilePictureUrl', userData['profile_picture_url']);
    }
  }

  // COMPLETE logout - clear ALL auth data
  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Remove all stored auth data
    await prefs.remove('authToken');
    await prefs.remove('userEmail');
    await prefs.remove('userId');
    await prefs.remove('userName');
    await prefs.remove('userRole');
    await prefs.remove('userStatus');
    await prefs.remove('profilePictureUrl');
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

  // Utility methods for easy access to user data
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }

  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userRole');
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userName');
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userEmail');
  }

  static Future<bool> isUserActive() async {
    final prefs = await SharedPreferences.getInstance();
    final status = prefs.getString('userStatus');
    return status == 'active';
  }

  // Role check helpers
  static Future<bool> isTraveler() async {
    final role = await getUserRole();
    return role == 'traveler';
  }

  static Future<bool> isTravelGuide() async {
    final role = await getUserRole();
    return role == 'travel_guide';
  }

  /// Send OTP for password reset
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await apiClient.post('/auth/forgot-password', {
        'email': email,
      });

      final responseData = json.decode(response.body);

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': responseData,
        'message': responseData['message'] ??
            (response.statusCode == 200
                ? 'OTP sent successfully'
                : 'Failed to send OTP'),
      };
    } catch (error) {
      return {
        'success': false,
        'message': 'Failed to send OTP: ${error.toString()}',
        'error': error,
      };
    }
  }

  /// Verify OTP
  Future<Map<String, dynamic>> verifyOTP(String email, String otp) async {
    try {
      final response = await apiClient.post('/auth/verify-otp', {
        'email': email,
        'otp': otp,
      });

      final responseData = json.decode(response.body);

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': responseData,
        'message': responseData['message'] ??
            (response.statusCode == 200
                ? 'OTP verified successfully'
                : 'OTP verification failed'),
      };
    } catch (error) {
      return {
        'success': false,
        'message': 'OTP verification failed: ${error.toString()}',
        'error': error,
      };
    }
  }

  /// Reset password using OTP
  Future<Map<String, dynamic>> resetPasswordWithOTP(
    String email,
    String otp,
    String newPassword,
  ) async {
    try {
      final response = await apiClient.post('/auth/reset-password-otp', {
        'email': email,
        'otp': otp,
        'newPassword': newPassword,
      });

      final responseData = json.decode(response.body);

      return {
        'success': response.statusCode == 200,
        'statusCode': response.statusCode,
        'data': responseData,
        'message': responseData['message'] ??
            (response.statusCode == 200
                ? 'Password reset successful'
                : 'Password reset failed'),
      };
    } catch (error) {
      // If the endpoint wasn't found, try alternate endpoint
      if (error.toString().contains('404')) {
        try {
          final altResponse = await apiClient.post('/auth/reset-password', {
            'email': email,
            'otp': otp,
            'newPassword': newPassword,
          });

          final altResponseData = json.decode(altResponse.body);

          return {
            'success': altResponse.statusCode == 200,
            'statusCode': altResponse.statusCode,
            'data': altResponseData,
            'message': altResponseData['message'] ??
                (altResponse.statusCode == 200
                    ? 'Password reset successful (alternate endpoint)'
                    : 'Password reset failed (alternate endpoint)'),
          };
        } catch (altError) {
          return {
            'success': false,
            'message': 'Password reset failed (alternate endpoint): ${altError.toString()}',
            'error': altError,
          };
        }
      }

      return {
        'success': false,
        'message': 'Password reset failed: ${error.toString()}',
        'error': error,
      };
    }
  }

  /// Logout user - Handles both local and backend logout
  Future<Map<String, dynamic>> logout() async {
    print('🔄 AuthApi.logout() called');
    
    try {
      // Clear local storage first to ensure user can always logout
      await AuthApi.clearAuthData();
      
      // Clear the token in the API client
      apiClient.clearToken();

      try {
        // Try to call backend logout endpoint
        final response = await apiClient.get('/auth/logout');
        
        
        // Try to parse JSON response if available
        Map<String, dynamic>? responseData;
        if (response.body.trim().isNotEmpty) {
          try {
            responseData = json.decode(response.body);
          } catch (e) {
            // Ignore JSON parsing errors since we've already logged out locally
          }
        }

        return {
          'success': true,
          'statusCode': response.statusCode,
          'message': responseData?['message'] ?? 'Logged out successfully',
          'data': responseData,
        };
      } catch (backendError) {
        // If backend call fails, still return success since we've cleared local storage
        return {
          'success': true,
          'statusCode': 200,
          'message': 'Logged out successfully (local only)',
          'warning': 'Backend logout unavailable',
        };
      }
    } catch (error) {
      
      // Try one last time to clear tokens even if previous attempts failed
      try {
        await AuthApi.clearAuthData();
        apiClient.clearToken();
      } catch (_) {}
      
      return {
        'success': false,
        'message': 'Logout failed completely: ${error.toString()}',
        'error': error,
      };
    }
  }
}