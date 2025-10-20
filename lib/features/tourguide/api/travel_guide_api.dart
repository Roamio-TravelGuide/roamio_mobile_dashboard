import 'dart:convert';
import '../../../../core/api/api_client.dart';

class TravelGuideApi {
  final ApiClient apiClient;

  TravelGuideApi({required this.apiClient});

  // Get user profile
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final response = await apiClient.get('/users/$userId');

      print(response.body);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load user profile: ${response.statusCode}');
      }
    } catch (error) {
      print('Error in getUserProfile: $error');
      return {
        'success': false,
        'message': error.toString(),
        'data': null
      };
    }
  }

  Future<Map<String,dynamic>>getRevenueById(String id) async {
    try {
      final response = await apiClient.get('/payment/revenue/$id');
      print(response.body);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load revenue data: ${response.statusCode}');
      }
    } catch (error) {
      print('Error in getRevenueById: $error'); 
      return {
        'success': false,
        'message': error.toString(),
        'data': null
      };
    }
  }

  Future<Map<String,dynamic>>getPaidPackagesById(String id) async {
    try {
      final response = await apiClient.get('/payment/showPaidPackages/$id');
      print(response.body);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load paid packages data: ${response.statusCode}');
      }
    } catch (error) {
      print('Error in getPaidPackagesById: $error'); 
      return {
        'success': false,
        'message': error.toString(),
        'data': null
      };
    }
  }


  // Future<Map<String, dynamic>> updateProfile(String userId, Map<String, dynamic> data) async {
  //   return await apiClient.put('/users/$userId', data);
  // }
}