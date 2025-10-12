import 'dart:convert';
import '../../../../core/api/api_client.dart';

class TravellerApi {
  final ApiClient apiClient;

  TravellerApi({required this.apiClient});

  Future<Map<String, dynamic>> getTours({
    String? status,
    String? search,
    String? location,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int limit = 100000000000,
    bool disablePagination = false,
  }) async {
    try {
      print(
        'Fetching tours with params: search=$search, location=$location, status=$status',
      );

      final Map<String, String> queryParams = {};
      if (status != null) queryParams['status'] = status;
      if (search != null) queryParams['search'] = search;
      if (location != null) queryParams['location'] = location;
      if (dateFrom != null) queryParams['dateFrom'] = dateFrom;
      if (dateTo != null) queryParams['dateTo'] = dateTo;
      queryParams['page'] = page.toString();
      queryParams['limit'] = limit.toString();
      queryParams['disablePagination'] = disablePagination.toString();

      final response = await apiClient.get(
        '/tour-package',
        queryParameters: queryParams,
      );

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody is Map<String, dynamic>) {
          return responseBody;
        } else {
          throw Exception(
            'Invalid response format: Expected Map<String, dynamic>',
          );
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else if (response.statusCode == 404) {
        throw Exception('Endpoint not found: /tour-package');
      } else {
        throw Exception(
          'Failed to load tours: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (error) {
      print('Error fetching tours: $error');
      rethrow; // Let the caller handle the error
    }
  }

  Future<Map<String, dynamic>> getProfile(String userId) async {
    try {
      print('Fetching profile for user: $userId');

      final response = await apiClient.get(
        '/users/travelerProfile/$userId',
        queryParameters: {
          'ts': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      print('Profile API Response Status: ${response.statusCode}');
      print('Profile API Response Body: ${response.body}');

      if (response.body.trim().startsWith('<!DOCTYPE') ||
          response.body.trim().startsWith('<html')) {
        throw Exception(
          'Server returned HTML instead of JSON. Check API endpoint.',
        );
      }

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody is Map<String, dynamic>) {
          return responseBody;
        } else {
          throw Exception(
            'Invalid response format: Expected Map<String, dynamic>',
          );
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else if (response.statusCode == 404) {
        throw Exception('Profile not found for user: $userId');
      } else {
        throw Exception(
          'Failed to load profile: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (error) {
      print('Error fetching profile: $error');
      rethrow; // Let the caller handle the error
    }
  }

  Future<Map<String, dynamic>> updateProfile(
    String userId,
    Map<String, dynamic> profileData,
  ) async {
    try {
      print("🔄 Starting profile update...");
      print("👤 User ID: $userId");
      print("📝 Profile Data (original):");
      profileData.forEach((key, value) => print("  - $key: $value"));
      
      // Prepare the request data
      final requestData = {
        'userId': int.parse(userId),  // Convert userId to integer
        'id': int.parse(userId),      // Add id field as some APIs expect this
        'type': 'traveller',
        ...profileData,
      };
      
      print("📤 Final request data:");
      requestData.forEach((key, value) => print("  - $key: $value ($runtimeType)"));
      
      final response = await apiClient.put(
        '/users/profile/$userId',
        requestData,
      );

      print('Update response status: ${response.statusCode}');
      print('Update response body: ${response.body}');

      // Check for HTML error response
      if (response.body.trim().toLowerCase().startsWith('<!doctype html>') ||
          response.body.trim().toLowerCase().startsWith('<html')) {
        throw Exception('Server returned HTML instead of JSON. Please check the API endpoint.');
      }

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody is Map<String, dynamic>) {
          print('Profile updated successfully');
          return responseBody;
        } else {
          throw Exception("Invalid response format: Expected JSON object");
        }
      } else {
        throw Exception("Update failed: ${response.statusCode} - ${response.body}");
      }
    } catch (error) {
      print("Error updating profile: $error");
      rethrow;
    }
  }
}
