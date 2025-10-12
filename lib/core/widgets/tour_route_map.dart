// widgets/tour_route_map.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import '../models/tour_package.dart';
import '../../services/mapbox_route_service.dart';

class TourRouteMap extends StatefulWidget {
  final List<TourStop> tourStops;
  final bool showRouteLine;
  final int? focusedStopIndex;
  final VoidCallback? onStopTap;
  final VoidCallback? onMapTap;

  const TourRouteMap({
    super.key,
    required this.tourStops,
    this.showRouteLine = true,
    this.focusedStopIndex,
    this.onStopTap,
    this.onMapTap,
  });

  @override
  State<TourRouteMap> createState() => _TourRouteMapState();
}

class _TourRouteMapState extends State<TourRouteMap> {
  late MapController _mapController;
  List<LatLng> _routePoints = [];
  List<Polyline> _routePolylines = [];
  bool _isLoadingRoute = false;
  String _routeError = '';
  Map<String, dynamic>? _routeInfo;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadRoute();
  }

  @override
  void didUpdateWidget(covariant TourRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusedStopIndex != widget.focusedStopIndex) {
      _focusOnStop();
    }
    if (oldWidget.tourStops != widget.tourStops) {
      _loadRoute();
    }
  }

  Future<void> _loadRoute() async {
    final validStops = widget.tourStops
        .where((stop) => stop.location != null)
        .toList()
      ..sort((a, b) => a.sequenceNo.compareTo(b.sequenceNo));

    if (validStops.length < 2) {
      setState(() {
        _routePoints = validStops.map((stop) => LatLng(
          stop.location!.latitude,
          stop.location!.longitude,
        )).toList();
        _routePolylines = [];
      });
      return;
    }

    setState(() {
      _isLoadingRoute = true;
      _routeError = '';
    });

    try {
      final points = validStops.map((stop) => LatLng(
        stop.location!.latitude,
        stop.location!.longitude,
      )).toList();

      final routePoints = await MapboxRouteService.getCompleteWalkingRoute(points);
      _routeInfo = await MapboxRouteService.getRouteInfo(points);

      setState(() {
        _routePoints = routePoints ?? points;
        _isLoadingRoute = false;
        
        if (_routePoints.isNotEmpty) {
          _routePolylines = [
            Polyline(
              points: _routePoints,
              strokeWidth: 4.0,
              color: const Color(0xFF6366F1).withOpacity(0.8),
              borderColor: Colors.white.withOpacity(0.5),
              borderStrokeWidth: 6.0,
            ),
          ];
        }
      });

      if (_routePoints.isNotEmpty) {
        _focusOnRoute();
      }
    } catch (e) {
      setState(() {
        _isLoadingRoute = false;
        _routeError = 'Failed to load route: $e';
      });
    }
  }

  void _focusOnStop() {
    if (widget.focusedStopIndex != null) {
      final stop = widget.tourStops[widget.focusedStopIndex!];
      if (stop.location != null) {
        Future.delayed(const Duration(milliseconds: 100), () {
          _mapController.move(
            LatLng(stop.location!.latitude, stop.location!.longitude),
            15.0,
          );
        });
      }
    } else if (_routePoints.isNotEmpty) {
      _focusOnRoute();
    }
  }

  void _focusOnRoute() {
    if (_routePoints.isNotEmpty) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _mapController.fitBounds(
          LatLngBounds.fromPoints(_routePoints),
          options: const FitBoundsOptions(padding: EdgeInsets.all(50)),
        );
      });
    }
  }

  List<Marker> _buildStopMarkers() {
    final markers = <Marker>[];
    final validStops = widget.tourStops
        .where((stop) => stop.location != null)
        .toList()
      ..sort((a, b) => a.sequenceNo.compareTo(b.sequenceNo));
    
    for (int i = 0; i < validStops.length; i++) {
      final stop = validStops[i];
      final isFocused = widget.tourStops.indexOf(stop) == widget.focusedStopIndex;
      
      markers.add(
        Marker(
          point: LatLng(stop.location!.latitude, stop.location!.longitude),
          width: 40.0,
          height: 40.0,
          child: GestureDetector(
            onTap: () {
              widget.onStopTap?.call();
              _mapController.move(
                LatLng(stop.location!.latitude, stop.location!.longitude),
                15.0,
              );
            },
            child: _buildStopMarker(i + 1, isFocused, i == 0, i == validStops.length - 1),
          ),
        ),
      );
    }
    
    return markers;
  }

  Widget _buildStopMarker(int stopNumber, bool isFocused, bool isStart, bool isEnd) {
    Color iconColor;
    IconData icon;

    if (isStart) {
      iconColor = Colors.green;
      icon = Icons.play_arrow;
    } else if (isEnd) {
      iconColor = Colors.red;
      icon = Icons.flag;
    } else {
      iconColor = const Color.fromARGB(255, 157, 92, 30);
      icon = Icons.location_on;
    }

    return Icon(
      icon,
      color: iconColor,
      size: isFocused ? 30 : 24,
    );
  }

  @override
  Widget build(BuildContext context) {
    final validStops = widget.tourStops.where((stop) => stop.location != null).toList();
    
    return Stack(
      children: [
        GestureDetector(
          onTap: widget.onMapTap,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _routePoints.isNotEmpty 
                  ? _routePoints.first 
                  : const LatLng(6.8667, 81.0466),
              zoom: 12.0,
              interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.roamio.app',
                tileProvider: CancellableNetworkTileProvider(),
              ),
              
              if (widget.showRouteLine && _routePolylines.isNotEmpty)
                PolylineLayer(polylines: _routePolylines),
              
              MarkerLayer(markers: _buildStopMarkers()),
            ],
          ),
        ),
        
        if (_routeInfo != null && !_isLoadingRoute)
          _buildRouteInfoOverlay(validStops),
        
        if (_isLoadingRoute)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),
            ),
          ),
        
        if (_routeError.isNotEmpty)
          _buildErrorOverlay(),
      ],
    );
  }

  Widget _buildRouteInfoOverlay(List<TourStop> validStops) {
    final distance = _routeInfo?['distance'] ?? 0;
    final duration = _routeInfo?['duration'] ?? 0;
    
    return Align(
      alignment: Alignment.topRight,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Route Info',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text('Stops: ${validStops.length}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text('Distance: ${(distance / 1000).toStringAsFixed(1)} km', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text('Walking time: ${_formatDuration(duration.toInt())}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
  }

  Widget _buildErrorOverlay() {
    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning, color: Colors.orange, size: 32),
            const SizedBox(height: 8),
            const Text(
              'Route Loading Failed',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(_routeError, style: const TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadRoute,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}