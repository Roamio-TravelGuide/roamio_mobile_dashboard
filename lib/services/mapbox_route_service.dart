import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class MapboxRouteService {
  static const String _baseUrl = 'https://api.mapbox.com/directions/v5/mapbox';
  static const String _apiKey = 'pk.eyJ1IjoiYWJkdWwwMTEiLCJhIjoiY21jYnN5OXl0MDBvMDJrc2I1MjU2Z28yZSJ9.jzJqzPye1bItMiZf7Tyzhg'; // Replace with your token
  static const String _profile = 'walking'; // walking, driving, cycling

  static Future<List<LatLng>?> getWalkingRoute(
    LatLng start, 
    LatLng end,
  ) async {
    try {
      final url = '$_baseUrl/$_profile/'
          '${start.longitude},${start.latitude};'
          '${end.longitude},${end.latitude}'
          '?geometries=geojson&'
          'steps=true&'
          'overview=full&'
          'access_token=$_apiKey';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseMapboxRoute(data);
      } else {
        print('Mapbox API error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error getting Mapbox route: $e');
      return null;
    }
  }

  static List<LatLng>? _parseMapboxRoute(Map<String, dynamic> data) {
    if (data['code'] != 'Ok' || data['routes'] == null || data['routes'].isEmpty) {
      return null;
    }

    final route = data['routes'][0];
    final geometry = route['geometry'];
    
    if (geometry['type'] == 'LineString') {
      final coordinates = geometry['coordinates'] as List;
      return coordinates.map<LatLng>((coord) {
        // GeoJSON format is [lng, lat] - FIXED: Ensure double conversion
        return LatLng(
          (coord[1] as num).toDouble(), // Explicit conversion to double
          (coord[0] as num).toDouble(), // Explicit conversion to double
        );
      }).toList();
    }
    
    return null;
  }

  // Get complete route for all stops
  static Future<List<LatLng>?> getCompleteWalkingRoute(List<LatLng> points) async {
    if (points.length < 2) return null;

    try {
      final waypoints = points.map((point) => '${point.longitude},${point.latitude}').join(';');
      final url = '$_baseUrl/$_profile/$waypoints'
          '?geometries=geojson&'
          'steps=true&'
          'overview=full&'
          'access_token=$_apiKey';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseMapboxRoute(data);
      } else {
        print('Mapbox API error for complete route: ${response.statusCode}');
        return _getFallbackRoute(points);
      }
    } catch (e) {
      print('Error getting complete Mapbox route: $e');
      return _getFallbackRoute(points);
    }
  }

  // Fallback to straight lines with more points for smoother appearance
  static List<LatLng> _getFallbackRoute(List<LatLng> points) {
    final fallbackRoute = <LatLng>[];
    
    for (int i = 0; i < points.length - 1; i++) {
      final start = points[i];
      final end = points[i + 1];
      
      // Add multiple intermediate points for smoother line
      const numPoints = 10; // Number of intermediate points
      for (int j = 0; j <= numPoints; j++) {
        final ratio = j / numPoints;
        final lat = start.latitude + (end.latitude - start.latitude) * ratio;
        final lng = start.longitude + (end.longitude - start.longitude) * ratio;
        fallbackRoute.add(LatLng(lat, lng));
      }
    }
    
    return fallbackRoute;
  }

  // Get route distance and duration
  static Future<Map<String, dynamic>?> getRouteInfo(List<LatLng> points) async {
    if (points.length < 2) return null;

    try {
      final waypoints = points.map((point) => '${point.longitude},${point.latitude}').join(';');
      final url = '$_baseUrl/$_profile/$waypoints'
          '?overview=false&'
          'access_token=$_apiKey';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseRouteInfo(data);
      }
      return null;
    } catch (e) {
      print('Error getting route info: $e');
      return null;
    }
  }

  static Map<String, dynamic>? _parseRouteInfo(Map<String, dynamic> data) {
    if (data['code'] != 'Ok' || data['routes'] == null || data['routes'].isEmpty) {
      return null;
    }

    final route = data['routes'][0];
    return {
      'distance': (route['distance'] as num).toDouble(), // Ensure double
      'duration': (route['duration'] as num).toDouble(), // Ensure double
    };
  }
}