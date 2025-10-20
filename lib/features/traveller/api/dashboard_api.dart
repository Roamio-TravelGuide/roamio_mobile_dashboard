import 'package:Roamio/core/api/api_client.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DashboardApi {
  final ApiClient apiClient;

  DashboardApi({required this.apiClient});

  // Helper method to parse http.Response to Map
  Map<String, dynamic> _parseResponse(http.Response response) {
    try {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Parse JSON response
        final jsonResponse = json.decode(response.body);
        return jsonResponse is Map<String, dynamic> 
            ? jsonResponse 
            : {'success': true, 'data': jsonResponse};
      } else {
        return {
          'success': false,
          'message': 'Request failed with status: ${response.statusCode}',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to parse response: $e',
      };
    }
  }

  // Get nearby packages by location
  Future<Map<String, dynamic>> getPackagesByLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 50,
    int limit = 4,
  }) async {
    try {
      final response = await apiClient.get(
        '/packages/nearby',
        queryParameters: {
          'lat': latitude.toString(),
          'lng': longitude.toString(),
          'radius': radiusKm.toString(),
          'limit': limit.toString(),
        },
      );

      return _parseResponse(response);
    } catch (error) {
      print('Error fetching nearby packages: $error');
      return {'success': false, 'message': error.toString()};
    }
  }

  // Get recent tours
  Future<Map<String, dynamic>> getRecentTours({
    int limit = 3,
    int days = 30,
  }) async {
    try {
      final response = await apiClient.get(
        '/packages/recent',
        queryParameters: {
          'limit': limit.toString(),
          'days': days.toString(),
        },
      );
      
      return _parseResponse(response);
    } catch (error) {
      print('Error fetching recent tours: $error');
      return {'success': false, 'message': error.toString()};
    }
  }

  // Get trending tours
  Future<Map<String, dynamic>> getTrendingTours({
    int limit = 4,
    String period = 'week',
  }) async {
    try {
      final response = await apiClient.get(
        '/packages/trending',
        queryParameters: {
          'limit': limit.toString(),
          'period': period,
        },
      );
      
      return _parseResponse(response);
    } catch (error) {
      print('Error fetching trending tours: $error');
      return {'success': false, 'message': error.toString()};
    }
  }

  // Get recommended tours
  Future<Map<String, dynamic>> getRecommendedTours({
    int limit = 6,
    String? userId,
  }) async {
    try {
      final Map<String, String> queryParams = {
        'limit': limit.toString(),
      };
      
      if (userId != null && userId.isNotEmpty) {
        queryParams['userId'] = userId;
      }

      final response = await apiClient.get(
        '/packages/recommended',
        queryParameters: queryParams,
      );
      
      return _parseResponse(response);
    } catch (error) {
      print('Error fetching recommended tours: $error');
      return {'success': false, 'message': error.toString()};
    }
  }

  // Get all packages with search and filters
  Future<Map<String, dynamic>> getAllPackages({
    String? search,
    String? location,
    String? category,
    double? minPrice,
    double? maxPrice,
    String? status = 'published',
    int limit = 20,
    int page = 1,
  }) async {
    try {
      final Map<String, String> queryParams = {
        'limit': limit.toString(),
        'page': page.toString(),
        'status': status ?? 'published',
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (location != null && location.isNotEmpty) {
        queryParams['location'] = location;
      }
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      if (minPrice != null) {
        queryParams['minPrice'] = minPrice.toString();
      }
      if (maxPrice != null) {
        queryParams['maxPrice'] = maxPrice.toString();
      }

      final response = await apiClient.get(
        '/packages',
        queryParameters: queryParams,
      );
      
      return _parseResponse(response);
    } catch (error) {
      print('Error fetching all packages: $error');
      return {'success': false, 'message': error.toString()};
    }
  }

  // Get package by ID
  Future<Map<String, dynamic>> getPackageById(String packageId) async {
    try {
      final response = await apiClient.get(
        '/packages/$packageId',
      );
      
      return _parseResponse(response);
    } catch (error) {
      print('Error fetching package by ID: $error');
      return {'success': false, 'message': error.toString()};
    }
  }

  // Submit package review - CORRECTED
  Future<Map<String, dynamic>> submitReview({
    required String packageId,
    required String userId,
    required double rating,
    required String comment,
    String? title,
  }) async {
    try {
      final Map<String, dynamic> requestData = {
        'userId': userId,
        'rating': rating,
        'comment': comment,
      };
      
      if (title != null && title.isNotEmpty) {
        requestData['title'] = title;
      }

      final response = await apiClient.post(
        '/packages/$packageId/reviews',
        requestData, // Directly pass the data object
      );
      
      return _parseResponse(response);
    } catch (error) {
      print('Error submitting review: $error');
      return {'success': false, 'message': error.toString()};
    }
  }

  // Add package to favorites - CORRECTED
  Future<Map<String, dynamic>> addToFavorites({
    required String userId,
    required String packageId,
  }) async {
    try {
      final response = await apiClient.post(
        '/users/$userId/favorites',
        {'packageId': packageId}, // Directly pass the data object
      );
      
      return _parseResponse(response);
    } catch (error) {
      print('Error adding to favorites: $error');
      return {'success': false, 'message': error.toString()};
    }
  }

  // Remove package from favorites
  Future<Map<String, dynamic>> removeFromFavorites({
    required String userId,
    required String packageId,
  }) async {
    try {
      final response = await apiClient.delete(
        '/users/$userId/favorites/$packageId',
      );
      
      return _parseResponse(response);
    } catch (error) {
      print('Error removing from favorites: $error');
      return {'success': false, 'message': error.toString()};
    }
  }

  // Mark package as completed - CORRECTED
  Future<Map<String, dynamic>> markAsCompleted({
    required String userId,
    required String packageId,
  }) async {
    try {
      final response = await apiClient.post(
        '/users/$userId/completed',
        {'packageId': packageId}, // Directly pass the data object
      );
      
      return _parseResponse(response);
    } catch (error) {
      print('Error marking as completed: $error');
      return {'success': false, 'message': error.toString()};
    }
  }

  // Download package - CORRECTED
  Future<Map<String, dynamic>> downloadPackage({
    required String packageId,
    required String userId,
  }) async {
    try {
      final response = await apiClient.post(
        '/packages/$packageId/download',
        {'userId': userId}, // Directly pass the data object
      );
      
      return _parseResponse(response);
    } catch (error) {
      print('Error downloading package: $error');
      return {'success': false, 'message': error.toString()};
    }
  }

  // Get packages by category
  Future<Map<String, dynamic>> getPackagesByCategory({
    required String category,
    int limit = 10,
    int page = 1,
  }) async {
    try {
      final response = await apiClient.get(
        '/packages/category/$category',
        queryParameters: {
          'limit': limit.toString(),
          'page': page.toString(),
        },
      );
      return _parseResponse(response);
    } catch (error) {
      print('Error fetching packages by category: $error');
      return {'success': false, 'message': error.toString()};
    }
  }

  // Get user's favorite packages
  Future<Map<String, dynamic>> getFavoritePackages({
    required String userId,
    int limit = 10,
    int page = 1,
  }) async {
    try {
      final response = await apiClient.get(
        '/users/$userId/favorites',
        queryParameters: {
          'limit': limit.toString(),
          'page': page.toString(),
        },
      );
      return _parseResponse(response);
    } catch (error) {
      print('Error fetching favorite packages: $error');
      return {'success': false, 'message': error.toString()};
    }
  }

  // Get user's completed packages
  Future<Map<String, dynamic>> getCompletedPackages({
    required String userId,
    int limit = 10,
    int page = 1,
  }) async {
    try {
      final response = await apiClient.get(
        '/users/$userId/completed',
        queryParameters: {
          'limit': limit.toString(),
          'page': page.toString(),
        },
      );
      return _parseResponse(response);
    } catch (error) {
      print('Error fetching completed packages: $error');
      return {'success': false, 'message': error.toString()};
    }
  }

  // Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats({String? userId}) async {
    try {
      final Map<String, String> queryParams = {};
      
      if (userId != null && userId.isNotEmpty) {
        queryParams['userId'] = userId;
      }

      final response = await apiClient.get(
        '/dashboard/stats',
        queryParameters: queryParams,
      );
      return _parseResponse(response);
    } catch (error) {
      print('Error fetching dashboard stats: $error');
      return {'success': false, 'message': error.toString()};
    }
  }

  // Get package reviews
  Future<Map<String, dynamic>> getPackageReviews({
    required String packageId,
    int limit = 10,
    int page = 1,
  }) async {
    try {
      final response = await apiClient.get(
        '/packages/$packageId/reviews',
        queryParameters: {
          'limit': limit.toString(),
          'page': page.toString(),
        },
      );
      return _parseResponse(response);
    } catch (error) {
      print('Error fetching package reviews: $error');
      return {'success': false, 'message': error.toString()};
    }
  }

  // Get download count for package
  Future<Map<String, dynamic>> getPackageDownloadCount(String packageId) async {
    try {
      final response = await apiClient.get(
        '/packages/$packageId/downloads',
      );
      return _parseResponse(response);
    } catch (error) {
      print('Error fetching download count: $error');
      return {'success': false, 'message': error.toString()};
    }
  }

  // Search packages with advanced filters
  Future<Map<String, dynamic>> searchPackages({
    required String query,
    String? location,
    List<String>? categories,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? sortBy,
    String? sortOrder,
    int limit = 20,
    int page = 1,
  }) async {
    try {
      final Map<String, String> queryParams = {
        'q': query,
        'limit': limit.toString(),
        'page': page.toString(),
      };

      if (location != null && location.isNotEmpty) {
        queryParams['location'] = location;
      }
      if (categories != null && categories.isNotEmpty) {
        queryParams['categories'] = categories.join(',');
      }
      if (minPrice != null) {
        queryParams['minPrice'] = minPrice.toString();
      }
      if (maxPrice != null) {
        queryParams['maxPrice'] = maxPrice.toString();
      }
      if (minRating != null) {
        queryParams['minRating'] = minRating.toString();
      }
      if (sortBy != null && sortBy.isNotEmpty) {
        queryParams['sortBy'] = sortBy;
      }
      if (sortOrder != null && sortOrder.isNotEmpty) {
        queryParams['sortOrder'] = sortOrder;
      }

      final response = await apiClient.get(
        '/packages/search',
        queryParameters: queryParams,
      );
      return _parseResponse(response);
    } catch (error) {
      print('Error searching packages: $error');
      return {'success': false, 'message': error.toString()};
    }
  }

  // Get popular destinations
  Future<Map<String, dynamic>> getPopularDestinations({
    int limit = 8,
  }) async {
    try {
      final response = await apiClient.get(
        '/destinations/popular',
        queryParameters: {
          'limit': limit.toString(),
        },
      );
      return _parseResponse(response);
    } catch (error) {
      print('Error fetching popular destinations: $error');
      return {'success': false, 'message': error.toString()};
    }
  }

  // Check payment status for a package
  Future<Map<String, dynamic>> checkPaymentStatus(String packageId, String userId) async {
    try {
      // Create a new client without auth header for this endpoint
      final http.Response response = await http.get(
        Uri.parse('${apiClient.baseUrl}/packages/$packageId/payment-status?userId=$userId'),
        headers: {
          'Content-Type': 'application/json',
          // Don't include Authorization header for payment status check
        },
      );

      return _parseResponse(response);
    } catch (error) {
      print('Error checking payment status: $error');
      return {'success': false, 'message': error.toString()};
    }
  }

Future<Map<String, dynamic>> getNearbyPlaces({
  required double latitude,
  required double longitude,
  required int radius,
}) async {
  try {
    print('🚀 API CALL: Getting nearby places');
    print('📍 Latitude: $latitude, Longitude: $longitude, Radius: ${radius}km');
    print('🔗 Endpoint: /traveller/nearby-places');
    
    final response = await apiClient.get(
      '/traveller/nearby-places',
      queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'radius': radius.toString(),
      },
    );
    
    print('✅ API RESPONSE SUCCESS:');
    print('📦 Response Type: ${response.runtimeType}');
    print('📦 Response Data: $response');
    
    return _parseResponse(response);
  } catch (e) {
    print('❌ API ERROR: $e');
    return {
      'success': false, 
      'error': e.toString(),
      'data': []
    };
  }
}

}