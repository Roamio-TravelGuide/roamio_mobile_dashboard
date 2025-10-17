import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class CustomMap extends StatelessWidget {
  final LatLng? center;
  final double? zoom;
  final List<LatLng>? routePoints;
  final LatLng? currentLocation;
  final LatLng? destinationLocation;
  final String? destinationName;
  final VoidCallback? onMapTap;

  const CustomMap({
    super.key,
    this.center,
    this.zoom = 12.0,
    this.routePoints,
    this.currentLocation,
    this.destinationLocation,
    this.destinationName,
    this.onMapTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildMapContent(),
      ),
    );
  }

  Widget _buildMapContent() {
    final defaultCenter = const LatLng(6.8667, 81.0466);
    final effectiveCenter = center ?? currentLocation ?? defaultCenter;
    final effectiveZoom = zoom ?? 12.0;

    return GestureDetector(
      onTap: onMapTap,
      child: FlutterMap(
        options: MapOptions(
          center: effectiveCenter,
          zoom: effectiveZoom,
          interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.roamio.app',
          ),
          if (routePoints != null && routePoints!.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: routePoints!,
                  strokeWidth: 4.0,
                  color: Colors.blue,
                ),
              ],
            ),
          MarkerLayer(
            markers: _buildMarkers(),
          ),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // Current location marker
    if (currentLocation != null) {
      markers.add(
        Marker(
          point: currentLocation!,
          width: 80.0,
          height: 80.0,
          child: _buildLocationMarker(
            Icons.my_location,
            'You are here',
            Colors.blue,
          ),
        ),
      );
    }

    // Destination marker
    if (destinationLocation != null) {
      markers.add(
        Marker(
          point: destinationLocation!,
          width: 80.0,
          height: 80.0,
          child: _buildLocationMarker(
            Icons.location_on,
            destinationName ?? 'Destination',
            Colors.red,
          ),
        ),
      );
    }

    return markers;
  }

  Widget _buildLocationMarker(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}