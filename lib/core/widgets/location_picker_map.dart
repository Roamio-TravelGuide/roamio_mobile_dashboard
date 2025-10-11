import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LocationPickerMap extends StatelessWidget {
  final LatLng? center;
  final double? zoom;
  final LatLng? currentLocation;
  final LatLng? selectedLocation;
  final Function(LatLng) onMapTap;

  const LocationPickerMap({
    super.key,
    this.center,
    this.zoom = 14.0,
    this.currentLocation,
    this.selectedLocation,
    required this.onMapTap,
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
    final effectiveZoom = zoom ?? 14.0;

    return FlutterMap(
      options: MapOptions(
        center: effectiveCenter,
        zoom: effectiveZoom,
        interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        onTap: (_, latlng) => onMapTap(latlng),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.roamio.app',
        ),
        MarkerLayer(
          markers: _buildMarkers(),
        ),
      ],
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // Current location marker - Blue navigation icon
    if (currentLocation != null) {
      markers.add(
        Marker(
          point: currentLocation!,
          width: 30.0,
          height: 30.0,
          child: Icon(
            Icons.my_location,
            color: Colors.blue,
            size: 30,
          ),
        ),
      );
    }

    // Selected location marker - Red location pin
    if (selectedLocation != null) {
      markers.add(
        Marker(
          point: selectedLocation!,
          width: 30.0,
          height: 30.0,
          child: Icon(
            Icons.location_pin,
            color: Colors.red,
            size: 30,
          ),
        ),
      );
    }

    return markers;
  }
}