import 'package:flutter/foundation.dart'; // Add this import
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {

  static Stream<Position> get positionStream {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation, // High accuracy for walking
        distanceFilter: 5, // Update every 5 meters
      ),
    );
  }

  
  static Future<Position?> getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      return null;
    }
  }
static Future<LatLng?> getCurrentLatLng() async {
  try {
    // For web, try to get the pre-fetched location from JavaScript
    if (kIsWeb) {
      try {
        // You might want to use js package to call JavaScript directly
        // or implement MethodChannel for better web integration
        print('Running on web - using browser geolocation');
      } catch (e) {
        print('Web-specific location handling failed: $e');
      }
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled');
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions denied');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permissions permanently denied');
      return null;
    }

    // Use high accuracy with longer timeout for web
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
      timeLimit: Duration(seconds: kIsWeb ? 20 : 15),
    );

    print('Final location obtained:');
    print('- Latitude: ${position.latitude}');
    print('- Longitude: ${position.longitude}');
    print('- Accuracy: ${position.accuracy} meters');
    
    return LatLng(position.latitude, position.longitude);
    
  } catch (e) {
    print('Error getting location: $e');
    return null;
  }
}
}