import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class MapboxService {
  static const String _accessToken = 'pk.eyJ1IjoiYWJkdWwwMTEiLCJhIjoiY21jYnN5OXl0MDBvMDJrc2I1MjU2Z28yZSJ9.jzJqzPye1bItMiZf7Tyzhg';

  /// Calculate distance between two points using Haversine formula
  double getDistanceBetweenPoints(Map<String, double> point1, Map<String, double> point2) {
    const double R = 6371000; // Earth's radius in meters
    final double dLat = (point2['lat']! - point1['lat']!) * pi / 180;
    final double dLng = (point2['lng']! - point1['lng']!) * pi / 180;
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(point1['lat']! * pi / 180) * cos(point2['lat']! * pi / 180) *
        sin(dLng / 2) * sin(dLng / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  /// Calculate walking time based on distance (average walking speed: 1.4 m/s)
  int getWalkingTime(double distanceInMeters) {
    return (distanceInMeters / 1.4).ceil(); // returns time in seconds
  }

  /// Get directions between points using Mapbox Directions API
  Future<Map<String, dynamic>?> getDirections(Map<String, double> origin, Map<String, double> destination, List<Map<String, double>> waypoints) async {
    try {
      // Build coordinates string for Mapbox Directions API
      final coordinates = [
        '${origin['lng']},${origin['lat']}',
        ...waypoints.map((wp) => '${wp['lng']},${wp['lat']}'),
        '${destination['lng']},${destination['lat']}'
      ].join(';');

      final url = Uri.parse(
        'https://api.mapbox.com/directions/v5/mapbox/walking/$coordinates?'
        'access_token=$_accessToken&'
        'geometries=geojson&'
        'overview=full&'
        'steps=true'
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception('HTTP error! status: ${response.statusCode}');
      }

      final data = json.decode(response.body);

      if (data['routes'] == null || data['routes'].isEmpty) {
        return null;
      }

      final route = data['routes'][0];

      return {
        'distance': route['distance'], // in meters
        'duration': route['duration'], // in seconds
        'path': (route['geometry']['coordinates'] as List)
            .map((coord) => {'lat': coord[1], 'lng': coord[0]})
            .toList()
      };
    } catch (error) {
      print('Error getting directions: $error');
      return null;
    }
  }

  /// Geocode an address to coordinates
  Future<Map<String, dynamic>?> geocode(String address) async {
    try {
      final encodedAddress = Uri.encodeComponent(address);
      final url = Uri.parse(
        'https://api.mapbox.com/geocoding/v5/mapbox.places/$encodedAddress.json?'
        'access_token=$_accessToken&'
        'limit=1'
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception('HTTP error! status: ${response.statusCode}');
      }

      final data = json.decode(response.body);

      if (data['features'] == null || data['features'].isEmpty) {
        return null;
      }

      final feature = data['features'][0];
      return {
        'latitude': feature['center'][1],
        'longitude': feature['center'][0],
        'formatted_address': feature['place_name']
      };
    } catch (error) {
      print('Error geocoding: $error');
      return null;
    }
  }

  /// Reverse geocode coordinates to address
  Future<Map<String, dynamic>?> reverseGeocode(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://api.mapbox.com/geocoding/v5/mapbox.places/$lng,$lat.json?'
        'access_token=$_accessToken&'
        'limit=1'
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception('HTTP error! status: ${response.statusCode}');
      }

      final data = json.decode(response.body);

      if (data['features'] == null || data['features'].isEmpty) {
        return null;
      }

      final feature = data['features'][0];
      return {
        'formatted_address': feature['place_name'],
        'components': feature['context'] ?? []
      };
    } catch (error) {
      print('Error reverse geocoding: $error');
      return null;
    }
  }
}