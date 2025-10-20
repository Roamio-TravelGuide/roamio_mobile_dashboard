// widgets/tour_route_map.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import '../models/tour_package.dart';
import '../../services/mapbox_route_service.dart';

class TourRouteMap extends StatefulWidget {
  final List<TourStop> tourStops;
  final List<NearbyPlace>? nearbyPlaces; // Add this parameter
  final bool showRouteLine;
  final int? focusedStopIndex;
  final LatLng? currentLocation;
  final VoidCallback? onStopTap;
  final VoidCallback? onMapTap;

  const TourRouteMap({
    super.key,
    required this.tourStops,
    this.nearbyPlaces, // Add this parameter
    this.showRouteLine = true,
    this.focusedStopIndex,
    this.currentLocation,
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
  List<LatLng> _currentToStopRoute = [];
  List<Polyline> _currentToStopPolylines = [];
  bool _isLoadingRoute = false;
  String _routeError = '';
  Map<String, dynamic>? _routeInfo;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadRoute();
    _loadCurrentToStopRoute();
  }

  @override
  void didUpdateWidget(covariant TourRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusedStopIndex != widget.focusedStopIndex ||
        oldWidget.currentLocation != widget.currentLocation) {
      _focusOnStop();
      _loadCurrentToStopRoute();
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

  Future<void> _loadCurrentToStopRoute() async {
    if (widget.currentLocation == null || widget.focusedStopIndex == null) {
      setState(() {
        _currentToStopRoute = [];
        _currentToStopPolylines = [];
      });
      return;
    }

    final focusedStop = widget.tourStops[widget.focusedStopIndex!];
    if (focusedStop.location == null) {
      setState(() {
        _currentToStopRoute = [];
        _currentToStopPolylines = [];
      });
      return;
    }

    try {
      final points = [
        widget.currentLocation!,
        LatLng(focusedStop.location!.latitude, focusedStop.location!.longitude),
      ];

      final routePoints = await MapboxRouteService.getWalkingRoute(points.first, points.last);

      setState(() {
        _currentToStopRoute = routePoints ?? points;
        if (_currentToStopRoute.isNotEmpty) {
          _currentToStopPolylines = [
            Polyline(
              points: _currentToStopRoute,
              strokeWidth: 4.0,
              color: Colors.blue.withOpacity(0.8),
              borderColor: Colors.white.withOpacity(0.5),
              borderStrokeWidth: 2.0,
            ),
          ];
        }
      });
    } catch (e) {
      setState(() {
        _currentToStopRoute = [];
        _currentToStopPolylines = [];
      });
    }
  }

  List<Marker> _buildStopMarkers() {
    final markers = <Marker>[];
    final validStops = widget.tourStops
        .where((stop) => stop.location != null)
        .toList()
      ..sort((a, b) => a.sequenceNo.compareTo(b.sequenceNo));

    // Add current location marker if provided
    if (widget.currentLocation != null) {
      markers.add(
        Marker(
          point: widget.currentLocation!,
          width: 40.0,
          height: 35.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // "You are here" label above the marker
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text(
                  'You are here',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 1),
              // Small blue circle marker
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.9),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: const Icon(
                  Icons.my_location,
                  color: Colors.white,
                  size: 11,
                ),
              ),
            ],
          ),
        ),
      );
    }

    for (int i = 0; i < validStops.length; i++) {
      final stop = validStops[i];
      final isFocused = widget.tourStops.indexOf(stop) == widget.focusedStopIndex;

      markers.add(
        Marker(
          point: LatLng(stop.location!.latitude, stop.location!.longitude),
          width: 60.0, // Increased width to accommodate label
          height: 60.0, // Increased height to accommodate label
          child: GestureDetector(
            onTap: () {
              widget.onStopTap?.call();
              _mapController.move(
                LatLng(stop.location!.latitude, stop.location!.longitude),
                15.0,
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Label above the marker for focused stop
                if (isFocused)
                  Container(
                    constraints: const BoxConstraints(maxWidth: 120), // Increased width for multi-line text
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      stop.stopName ?? 'Stop ${i + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2, // Allow up to 2 lines
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 2),
                // The stop marker
                _buildStopMarker(i + 1, isFocused, i == 0, i == validStops.length - 1),
              ],
            ),
          ),
        ),
      );
    }

    return markers;
  }
  

  List<Marker> _buildNearbyPlaceMarkers() {
  if (widget.nearbyPlaces == null || widget.nearbyPlaces!.isEmpty) {
    return [];
  }

  return widget.nearbyPlaces!.map((place) {
    Color markerColor;
    IconData markerIcon;
    String typeLabel;

    switch (place.type) {
      case PlaceType.restaurant:
        markerColor = Colors.blue;
        markerIcon = Icons.restaurant;
        typeLabel = 'Restaurant';
        break;
      case PlaceType.hiddenGem:
        markerColor = Colors.amber;
        markerIcon = Icons.auto_awesome;
        typeLabel = 'Hidden Gem';
        break;
      case PlaceType.attraction:
      default:
        markerColor = Colors.green;
        markerIcon = Icons.explore;
        typeLabel = 'Attraction';
    }

    return Marker(
      point: place.location,
      width: 45.0, // Reduced width
      height: 45.0, // Reduced height
      child: GestureDetector(
        onTap: () {
          // You can add specific behavior for nearby place taps here
          _mapController.move(place.location, 15.0);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Type label above marker
            Container(
              constraints: const BoxConstraints(maxWidth: 80), // Reduced max width
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1), // Reduced padding
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(2), // Smaller border radius
              ),
              child: Text(
                typeLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 7, // Smaller font
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 1), // Reduced spacing
            // Nearby place marker
            Container(
              width: 20, // Smaller marker
              height: 20, // Smaller marker
              decoration: BoxDecoration(
                color: markerColor.withOpacity(0.9),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.0), // Thinner border
              ),
              child: Icon(
                markerIcon,
                color: Colors.white,
                size: 10, // Smaller icon
              ),
            ),
            const SizedBox(height: 1), // Reduced spacing
            // Distance label below marker
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0), // Reduced padding
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(1), // Smaller border radius
              ),
              child: Text(
                '${place.distance.toStringAsFixed(1)}km',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 6, // Smaller font
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }).toList();
}

  Widget _buildStopMarker(int stopNumber, bool isFocused, bool isStart, bool isEnd) {
    // Use brown color for all stops in preview mode, red only for the actual last stop
    final isPreviewMode = widget.tourStops.length <= 2; // Assuming preview mode shows max 2 stops
    final iconColor = (isEnd && !isPreviewMode) ? Colors.red : const Color.fromARGB(255, 157, 92, 30);
    final icon = (isEnd && !isPreviewMode) ? Icons.flag : Icons.location_on;

    if (isFocused) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.red, width: 2),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 24,
        ),
      );
    }

    return Icon(
      icon,
      color: iconColor,
      size: 24,
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

              if (_currentToStopPolylines.isNotEmpty)
                PolylineLayer(polylines: _currentToStopPolylines),

              // Add nearby places markers layer
              MarkerLayer(markers: _buildNearbyPlaceMarkers()),

              // Add tour stop markers layer (on top of nearby places)
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
            if (widget.nearbyPlaces != null && widget.nearbyPlaces!.isNotEmpty)
              Text('Nearby Places: ${widget.nearbyPlaces!.length}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
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

// Add these model classes at the bottom of the file
class NearbyPlace {
  final String id;
  final String name;
  final LatLng location;
  final PlaceType type;
  final double distance;

  NearbyPlace({
    required this.id,
    required this.name,
    required this.location,
    required this.type,
    required this.distance,
  });
}

enum PlaceType {
  restaurant,
  hiddenGem,
  attraction,
}