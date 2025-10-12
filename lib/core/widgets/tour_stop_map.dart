// widgets/tour_stop_map.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/models/tour_package.dart';

class TourStopMap extends StatelessWidget {
  final Location stopLocation;
  final String stopName;
  final int stopNumber;
  final VoidCallback? onMapTap;

  const TourStopMap({
    super.key,
    required this.stopLocation,
    required this.stopName,
    required this.stopNumber,
    this.onMapTap,
  });

  @override
  Widget build(BuildContext context) {
    final stopLatLng = LatLng(stopLocation.latitude, stopLocation.longitude);

    return GestureDetector(
      onTap: onMapTap,
      child: FlutterMap(
        options: MapOptions(
          center: stopLatLng,
          zoom: 15.0,
          interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.roamio.app',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: stopLatLng,
                width: 40.0,
                height: 40.0,
                child: _buildStopMarker(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStopMarker() {
    return const Icon(
      Icons.location_on,
      color: Color(0xFF6366F1),
      size: 40,
    );
  }
}