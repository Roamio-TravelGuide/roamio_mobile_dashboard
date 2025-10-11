import 'package:latlong2/latlong.dart';
import './mapbox_service.dart';

class DirectionsService {
  final MapboxService _mapboxService = MapboxService();

  Future<DirectionsResult?> getDirections({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final directions = await _mapboxService.getDirections(
        {'lat': origin.latitude, 'lng': origin.longitude},
        {'lat': destination.latitude, 'lng': destination.longitude},
        [],
      );

      if (directions != null) {
        final routePoints = (directions['path'] as List)
            .map((point) => LatLng(point['lat'], point['lng']))
            .toList();

        return DirectionsResult(
          routePoints: routePoints,
          distance: directions['distance']?.toDouble(),
          duration: directions['duration']?.toDouble(),
        );
      }
    } catch (e) {
      // Handle error silently
    }
    return null;
  }
}

class DirectionsResult {
  final List<LatLng> routePoints;
  final double? distance;
  final double? duration;

  DirectionsResult({
    required this.routePoints,
    this.distance,
    this.duration,
  });
}