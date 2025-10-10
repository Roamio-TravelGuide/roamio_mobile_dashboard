import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
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
      print('Fetching tours with params: search=$search, location=$location, status=$status');

      // Build query parameters
      final Map<String, String> queryParams = {};
      if (status != null) queryParams['status'] = status;
      if (search != null) queryParams['search'] = search;
      if (location != null) queryParams['location'] = location;
      if (dateFrom != null) queryParams['dateFrom'] = dateFrom;
      if (dateTo != null) queryParams['dateTo'] = dateTo;
      queryParams['page'] = page.toString();
      queryParams['limit'] = limit.toString();
      queryParams['disablePagination'] = disablePagination.toString();

      // Make API request using ApiClient
      final response = await apiClient.get(
        '/tour-package',
        queryParameters: queryParams,
      );

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      // Parse response
      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        
        // Check if the response structure matches what we expect
        if (responseBody is Map<String, dynamic>) {
          return responseBody;
        } else {
          throw Exception('Invalid response format: Expected Map<String, dynamic>');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else if (response.statusCode == 404) {
        throw Exception('Endpoint not found: /tour-packages');
      } else {
        throw Exception('Failed to load tours: ${response.statusCode} - ${response.body}');
      }
    } catch (error) {
      print('Error fetching tours: $error');
      // Return a sample response for debugging
      return _getSampleResponse();
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
    };
  }
}