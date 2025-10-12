import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/api/api_client.dart';
import '../../auth/api/auth_api.dart';


class TourPackageApi {
  final ApiClient apiClient;

  TourPackageApi({required this.apiClient});

  // Get tour packages for current guide (automatically gets guide ID from user ID)
  Future<Map<String, dynamic>> getTourPackagesByGuideId({
    String? status,
    String? search,
    int page = 1,
    int limit = 10000,
  }) async {
    try {
      // Get guide ID from current user
      final guideId = await _getGuideId();
      
      if (guideId == null) {
        return {
          'success': false,
          'message': 'Guide profile not found. Please complete your guide profile.',
          'data': null
        };
      }

      // Build query parameters
      final Map<String, String> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      // Make API call with guide ID
      final response = await apiClient.get(
        '/tour-package/guide/$guideId',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        return responseBody;
      } else {
        throw Exception('Failed to load tour packages: ${response.statusCode}');
      }
    } catch (error) {
      print('Error in getTourPackagesByGuideId: $error');
      return {
        'success': false, 
        'message': error.toString(),
        'data': null
      };
    }
  }

  // Helper method to get guide ID
  Future<int?> _getGuideId() async {
    try {

      final userId = await AuthApi.getUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Call backend to get guide ID from user ID
      // final response = await apiClient.get('/users/guide/$userId');
      
      // if (response.statusCode == 200) {
      //   final responseData = json.decode(response.body);
        
        // if (responseData['success'] == true) {
        //   final guideId = responseData['data']['guideId'];
        //   return guideId;
        // } else {
        //   throw Exception(responseData['message'] ?? 'Failed to get guide ID');
        // }
      // } else {
      //   throw Exception('API error: ${response.statusCode}');
      // }
      return userId;
    } catch (error) {
      print('Error getting guide ID: $error');
      rethrow;
    }
  }

  // Get tour package by ID
  Future<Map<String, dynamic>> getTourPackageById(int id) async {
    try {
      final response = await apiClient.get('/tour-package/$id');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load tour package: ${response.statusCode}');
      }
    } catch (error) {
      print('Error in getTourPackageById: $error');
      return {
        'success': false,
        'message': error.toString(),
        'data': null
      };
    }
  }

  // Update tour package status
  Future<Map<String, dynamic>> updateTourPackageStatus(
    int id, {
    required String status,
    String? rejectionReason,
  }) async {
    try {
      final data = {
        'status': status,
        if (rejectionReason != null) 'rejection_reason': rejectionReason,
      };

      final response = await apiClient.patch('/tour-packages/$id/status', data);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update status: ${response.statusCode}');
      }
    } catch (error) {
      print('Error in updateTourPackageStatus: $error');
      return {
        'success': false,
        'message': error.toString()
      };
    }
  }

}