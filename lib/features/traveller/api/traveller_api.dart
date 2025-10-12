import 'dart:convert';
import '../../../../core/api/api_client.dart';
import 'dart:io';
import 'package:http/http.dart' as http; 
import 'package:image_picker/image_picker.dart'; // Add this import
import '../../auth/api/auth_api.dart';

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
      // print('Fetching tours with params: search=$search, location=$location, status=$status');

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

      // print('API Response Status: ${response.statusCode}');
      // print('API Response Body: ${response.body}');

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
Future<Map<String, dynamic>> getMyTrips() async {
try {
  final response = await apiClient.get('/traveller/my-trips');
    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      if (responseBody is Map<String, dynamic>) {
        return responseBody;
      } else {
        throw Exception('Invalid response format');
      }
    } else {
      throw Exception('Failed to load my trips: ${response.statusCode}');
    }
  } catch (error) {
    print('Error fetching my trips: $error');
    return {'success': false, 'data': null, 'message': error.toString()};
  }
}

Future<Map<String, dynamic>> createPaymentIntent(double amount, {String? packageId, String currency = 'usd'}) async {
  try {
    final data = {
      'amount': amount,
      'currency': currency,
      'metadata': packageId != null ? {'packageId': packageId} : {}
    };
    final response = await apiClient.post('/payment/create-payment-intent', data);
    if (response.statusCode == 201) {
      final responseBody = json.decode(response.body);
      return responseBody;
    } else {
      throw Exception('Failed to create payment intent: ${response.statusCode}');
    }
  } catch (error) {
    print('Error creating payment intent: $error');
    return {'success': false, 'message': error.toString()};
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
Future<Map<String, dynamic>> createStripPayment(Map<String, dynamic> paymentIntentData) async {
  try {
    final response = await apiClient.post('/payment/create-strip-payment', paymentIntentData);
    if (response.statusCode == 201) {
      final responseBody = json.decode(response.body);
      return responseBody;
    } else {
      throw Exception('Failed to create strip payment: ${response.statusCode}');
    }
  } catch (error) {
    print('Error creating strip payment: $error');
    return {'success': false, 'message': error.toString()};
  }
}

Future<Map<String, dynamic>> getNearbyPois(double latitude, double longitude, {double radius = 500, String? category}) async {
  try {
    final response = await apiClient.get('/traveller/nearby-pois');
    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      if (responseBody is Map<String, dynamic>) {
        return responseBody;
      } else {
        throw Exception('Invalid response format');
      }
    } else {
      throw Exception('Failed to load nearby POIs: ${response.statusCode}');
    }
  } catch (error) {
    print('Error fetching nearby POIs: $error');
    return {'success': false, 'data': [], 'message': error.toString()};
  }
}
  // Fallback sample response for debugging
  Map<String, dynamic> _getSampleResponse() {
    return {
      'success': true,
      'data': {
        'packages': [
          {
            'id': '1',
            'title': 'Raja Ampat Islands',
            'imageUrl': 'https://images.unsplash.com/photo-1501785888041-af3ef285b470?q=80&w=1600&auto=format&fit=crop',
            'location': 'West Papua',
            'rating': 4.9,
            'price': 235.00,
            'description': 'Beautiful islands with rich marine biodiversity',
          },
          {
            'id': '2',
            'title': 'Tanah Lot Temple',
            'imageUrl': 'https://images.unsplash.com/photo-1596436889106-be35e8435c76?q=80&w=1600&auto=format&fit=crop',
            'location': 'Tabanan, Bali',
            'rating': 4.7,
            'price': 15.00,
            'description': 'Famous sea temple in Bali',
          },
        ],
        'total': 2,
        'page': 1,
        'limit': 10
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


  Future<List<Map<String, dynamic>>> getNearbyRestaurants({
    required double lat,
    required double lng,
    double radius = 500,
  }) async {
    try {
      final response = await apiClient.get(
        '/pois/nearby',
        queryParameters: {
          'lat': lat.toString(), // Convert double to string
          'lng': lng.toString(), // Convert double to string
          'radius': radius.toString(),
          'category': 'restaurant',
        },
      );

      // Parse the response body
      final responseBody = json.decode(response.body);
      
      // Access the data using proper Map syntax
      if (responseBody['success'] == true && responseBody['data'] != null) {
        final pois = responseBody['data'] as List;
        return pois.map((poi) {
          return {
            'name': poi['name'] ?? 'Unknown Restaurant',
            'description': poi['description'] ?? 'No description available',
            'image': poi['image'] ?? 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=300&h=200&fit=crop',
            'rating': (poi['rating'] as num?)?.toDouble() ?? 4.5,
          };
        }).toList();
      }
    } catch (e) {
      // Silent fail - return empty list
    }
    return [];
  }

  Future<Map<String, dynamic>> createHiddenPlace({
  required String name,
  required String description,
  required double latitude,
  required double longitude,
  required String address,
  required List<XFile> images,
}) async {
  try {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${apiClient.baseUrl}/hiddenGem/create'),
    );

    // Add only place data (NO user_id)
    request.fields['name'] = name;
    request.fields['description'] = description;
    request.fields['latitude'] = latitude.toString();
    request.fields['longitude'] = longitude.toString();
    request.fields['address'] = address;

    // Add image files - CROSS-PLATFORM SOLUTION
    for (int i = 0; i < images.length; i++) {
      final image = images[i];
      
      // Read bytes from XFile (works on both web and mobile)
      final bytes = await image.readAsBytes();
      
      // Create multipart file from bytes
      final file = http.MultipartFile.fromBytes(
        'images',
        bytes,
        filename: 'image_${i}_{DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      request.files.add(file);
    }

    // Add auth headers (JWT token)
    final token = await AuthApi.getAuthToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final response = await request.send().timeout(const Duration(seconds: 30));
    final responseString = await response.stream.bytesToString();


    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(responseString);
    } else {
      throw Exception('Failed to create hidden place: ${response.statusCode} - $responseString');
    }
  } catch (e) {
    throw Exception('Error creating hidden place: $e');
  }
}
}

