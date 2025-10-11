import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import '../../../../core/models/destination.dart';
import '../../../../core/widgets/map_component.dart';
import '../../../../core/widgets/retaurant_list.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/direction_service.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/config/env_config.dart';
import '../../api/traveller_api.dart';
import 'restaurant_detail.dart';
import 'audioplayer.dart';

class MyTripScreen extends StatefulWidget {
  final Map<String, dynamic>? stop;
  final List<Map<String, dynamic>>? allStops;

  const MyTripScreen({super.key, this.stop, this.allStops});

  @override
  State<MyTripScreen> createState() => _MyTripScreenState();
}

class _MyTripScreenState extends State<MyTripScreen> {
  final AudioPlayer audioPlayer = AudioPlayer();
  final DirectionsService _directionsService = DirectionsService();
  late TravellerApi _travellerApi;
  
  late List<Map<String, dynamic>> tourStops;
  int currentStopIndex = 0;
  
  LatLng? currentLocation;
  LatLng? stopLocation;
  List<LatLng> routePoints = [];
  
  List<Map<String, dynamic>> restaurants = [];
  bool isLoadingPois = false;
  bool isLoadingDirections = false;

  @override
  void initState() {
    super.initState();
    // Initialize TravellerApi with ApiClient
    _travellerApi = TravellerApi(
      apiClient: ApiClient(customBaseUrl: EnvConfig.baseUrl),
    );
    _initializeTourStops();
    _initializeLocationAndDirections();
  }

  void _initializeTourStops() {
    if (widget.allStops != null && widget.allStops!.isNotEmpty) {
      tourStops = widget.allStops!;
      if (widget.stop != null) {
        currentStopIndex = tourStops.indexWhere(
          (stop) => stop['id'] == widget.stop!['id'],
        );
        if (currentStopIndex == -1) currentStopIndex = 0;
      }
    } else if (widget.stop != null) {
      tourStops = [widget.stop!];
      currentStopIndex = 0;
    } else {
      tourStops = [
        {
          'title': 'Tanah Lot Temple',
          'audioUrl': 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
        },
      ];
      currentStopIndex = 0;
    }
  }

  void _initializeLocationAndDirections() async {
    // Get current location
    final location = await LocationService.getCurrentLatLng();
    if (location != null && mounted) {
      setState(() {
        currentLocation = location;
      });
      // Load nearby restaurants after getting location
      _loadNearbyRestaurants();
    }

    // Load directions for current stop
    if (tourStops.isNotEmpty) {
      _loadDirectionsForStop(tourStops[currentStopIndex]);
    }
  }

  void _loadDirectionsForStop(Map<String, dynamic> stop) async {
    if (currentLocation == null) return;

    final stopLocationData = stop['location'];
    if (stopLocationData == null || 
        stopLocationData['latitude'] == null || 
        stopLocationData['longitude'] == null) {
      return;
    }

    setState(() {
      isLoadingDirections = true;
      stopLocation = LatLng(
        stopLocationData['latitude'],
        stopLocationData['longitude'],
      );
    });

    final directions = await _directionsService.getDirections(
      origin: currentLocation!,
      destination: stopLocation!,
    );

    if (mounted) {
      setState(() {
        isLoadingDirections = false;
        if (directions != null) {
          routePoints = directions.routePoints;
        }
      });
    }
  }

  void _loadNearbyRestaurants() async {
    if (currentLocation == null) return;
    
    setState(() => isLoadingPois = true);

    try {
      final nearbyRestaurants = await _travellerApi.getNearbyRestaurants(
        lat: currentLocation!.latitude,
        lng: currentLocation!.longitude,
        radius: 1000, // 1km radius
      );

      if (mounted) {
        setState(() {
          restaurants = nearbyRestaurants;
        });
      }
    } catch (e) {
      // Handle error silently
      if (mounted) {
        setState(() {
          restaurants = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoadingPois = false;
        });
      }
    }
  }

  void _changeStop(int newIndex) {
    if (newIndex >= 0 && newIndex < tourStops.length) {
      setState(() => currentStopIndex = newIndex);
      _loadDirectionsForStop(tourStops[newIndex]);
      // Reload restaurants for new location if stop has coordinates
      _loadRestaurantsForStop(tourStops[newIndex]);
    }
  }

  void _loadRestaurantsForStop(Map<String, dynamic> stop) {
    final stopLocationData = stop['location'];
    if (stopLocationData != null && 
        stopLocationData['latitude'] != null && 
        stopLocationData['longitude'] != null) {
      
      final stopLatLng = LatLng(
        stopLocationData['latitude'],
        stopLocationData['longitude'],
      );
      
      _loadRestaurantsAtLocation(stopLatLng);
    } else {
      // Use current location if stop doesn't have coordinates
      if (currentLocation != null) {
        _loadNearbyRestaurants();
      }
    }
  }

  void _loadRestaurantsAtLocation(LatLng location) async {
    setState(() => isLoadingPois = true);

    try {
      final nearbyRestaurants = await _travellerApi.getNearbyRestaurants(
        lat: location.latitude,
        lng: location.longitude,
        radius: 1000,
      );

      if (mounted) {
        setState(() {
          restaurants = nearbyRestaurants;
        });
      }
    } catch (e) {
      // Handle error silently
      if (mounted) {
        setState(() {
          restaurants = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoadingPois = false;
        });
      }
    }
  }

  void _refreshRestaurants() {
    if (currentLocation != null) {
      _loadNearbyRestaurants();
    }
  }

  String get currentStopTitle {
    if (tourStops.isEmpty) return 'My Trip';
    final stop = tourStops[currentStopIndex];
    return stop['stop_name'] ?? stop['title'] ?? 'Stop';
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D12),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Trip',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshRestaurants,
            tooltip: 'Refresh nearby restaurants',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDestinationHeader(),
                  _buildMapSection(),
                  _buildRestaurantsSection(),
                ],
              ),
            ),
          ),
          _buildAudioPlayer(),
        ],
      ),
    );
  }

  Widget _buildDestinationHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        currentStopTitle,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMapSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 300,
      child: CustomMap(
        center: _calculateMapCenter(),
        zoom: _calculateZoomLevel(),
        currentLocation: currentLocation,
        destinationLocation: stopLocation,
        destinationName: currentStopTitle,
        routePoints: routePoints,
      ),
    );
  }

  Widget _buildRestaurantsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Cafes & Restaurants Nearby',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isLoadingPois)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        RestaurantList(
          restaurants: restaurants,
          isLoading: isLoadingPois,
          onRestaurantTap: (restaurant) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RestaurantDetailScreen(
                  name: restaurant['name'],
                  image: restaurant['image'],
                  rating: restaurant['rating'],
                  description: restaurant['description'],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAudioPlayer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      color: const Color(0xFF0D0D12),
      child: BottomAudioPlayer(
        title: currentStopTitle,
        onPlayPause: _togglePlayPause,
        onStop: _stopAudio,
        onNext: () => _changeStop(currentStopIndex + 1),
        onPrevious: () => _changeStop(currentStopIndex - 1),
        onSeek: _seekAudio, // Add this required parameter
        isPlaying: audioPlayer.playing,
        currentPositionNotifier: ValueNotifier(0.0),
        totalDuration: 116.0,
        progressText: '${currentStopIndex + 1}/${tourStops.length}',
      ),
    );
  }

  // Add this method to handle seeking
  void _seekAudio(double position) {
    audioPlayer.seek(Duration(seconds: position.toInt()));
  }

  void _togglePlayPause() {
    if (audioPlayer.playing) {
      audioPlayer.pause();
    } else {
      audioPlayer.play();
    }
  }

  void _stopAudio() {
    audioPlayer.stop();
  }

  LatLng? _calculateMapCenter() {
    if (currentLocation != null && stopLocation != null) {
      return LatLng(
        (currentLocation!.latitude + stopLocation!.latitude) / 2,
        (currentLocation!.longitude + stopLocation!.longitude) / 2,
      );
    }
    return currentLocation ?? stopLocation;
  }

  double _calculateZoomLevel() {
    if (currentLocation != null && stopLocation != null) {
      final distance = _calculateDistance(currentLocation!, stopLocation!);
      return (18 - (distance / 1000) * 0.5).clamp(10.0, 18.0);
    }
    return 12.0;
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const R = 6371000;
    final dLat = (point2.latitude - point1.latitude) * math.pi / 180;
    final dLng = (point2.longitude - point1.longitude) * math.pi / 180;
    final a = 
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(point1.latitude * math.pi / 180) *
        math.cos(point2.latitude * math.pi / 180) *
        math.sin(dLng / 2) *
        math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }
}