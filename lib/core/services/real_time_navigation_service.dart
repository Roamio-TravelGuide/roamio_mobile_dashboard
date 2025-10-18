// real_time_navigation_service.dart
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class RealTimeNavigationService {
  final Function(LatLng) onLocationUpdate;
  final Function(double) onDistanceUpdate;
  final Function(double) onBearingUpdate;

  RealTimeNavigationService({
    required this.onLocationUpdate,
    required this.onDistanceUpdate,
    required this.onBearingUpdate,
  });

  Stream<Position>? _positionStream;
  LatLng? _previousPosition;
  LatLng? _destination;

  void startNavigation(LatLng destination) {
    _destination = destination;
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 3, // Update every 3 meters for walking
      ),
    );

    _positionStream!.listen((Position position) {
      final currentLocation = LatLng(position.latitude, position.longitude);
      
      // Update location
      onLocationUpdate(currentLocation);
      
      // Calculate distance to destination
      if (_destination != null) {
        final distance = _calculateDistance(currentLocation, _destination!);
        onDistanceUpdate(distance);
      }
      
      // Calculate bearing/direction
      if (_previousPosition != null) {
        final bearing = _calculateBearing(_previousPosition!, currentLocation);
        onBearingUpdate(bearing);
      }
      
      _previousPosition = currentLocation;
    });
  }

  void stopNavigation() {
    _positionStream = null;
    _previousPosition = null;
  }

  double _calculateDistance(LatLng start, LatLng end) {
    const R = 6371000; // Earth's radius in meters
    final dLat = (end.latitude - start.latitude) * pi / 180;
    final dLng = (end.longitude - start.longitude) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(start.latitude * pi / 180) *
            cos(end.latitude * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _calculateBearing(LatLng start, LatLng end) {
    final startLat = start.latitude * pi / 180;
    final startLng = start.longitude * pi / 180;
    final endLat = end.latitude * pi / 180;
    final endLng = end.longitude * pi / 180;

    final y = sin(endLng - startLng) * cos(endLat);
    final x = cos(startLat) * sin(endLat) -
        sin(startLat) * cos(endLat) * cos(endLng - startLng);
    final bearing = atan2(y, x);
    return (bearing * 180 / pi + 360) % 360;
  }
}