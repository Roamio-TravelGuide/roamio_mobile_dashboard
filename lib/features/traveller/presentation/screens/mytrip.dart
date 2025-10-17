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
import '../../../../core/widgets/audio_player_widget.dart';
import '../../../../core/services/media_service.dart';
import '../../../../core/widgets/tour_route_map.dart';
import '../../../../core/models/tour_package.dart';
import 'package_checkout.dart';
import '../../api/dashboard_api.dart';
import '../../../../core/utils/storage_helper.dart';

class MyTripScreen extends StatefulWidget {
  final Map<String, dynamic>? stop;
  final List<Map<String, dynamic>>? allStops;
  final Map<String, dynamic>? package;
  final bool? isPreviewMode;
  final bool? isPaidPackage; // New flag to indicate this is a paid package

  const MyTripScreen({super.key, this.stop, this.allStops, this.package, this.isPreviewMode, this.isPaidPackage});

  @override
  State<MyTripScreen> createState() => _MyTripScreenState();
}

class _MyTripScreenState extends State<MyTripScreen> {
  final AudioPlayer audioPlayer = AudioPlayer();
  final DirectionsService _directionsService = DirectionsService();
  late TravellerApi _travellerApi;
  late DashboardApi dashboardApi;
  
  late List<Map<String, dynamic>> tourStops;
  int currentStopIndex = 0;
  bool hasPurchased = false;

  LatLng? currentLocation;
  LatLng? stopLocation;
  List<LatLng> routePoints = [];

  List<Map<String, dynamic>> restaurants = [];
  bool isLoadingPois = false;
  bool isLoadingDirections = false;

  // No dummy reviews data needed since we're only showing the add review UI

  // State for adding new review
  int _selectedRating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isAddingReview = false;

  @override
  void initState() {
    super.initState();
    // Initialize TravellerApi with ApiClient
    _travellerApi = TravellerApi(
      apiClient: ApiClient(customBaseUrl: EnvConfig.baseUrl),
    );
    dashboardApi = DashboardApi(apiClient: ApiClient(customBaseUrl: EnvConfig.baseUrl));
    _initializeTourStops();
    _initializeLocationAndDirections();
  }

  void _initializeTourStops() async {
    // Check if this is explicitly marked as a paid package (from successful payment or MyTrips)
    if (widget.isPaidPackage == true || (widget.package != null && widget.isPreviewMode != true)) {
      hasPurchased = true;
      print('MyTrip: This is a paid package or from MyTrips - granting full access');
    } else {
      // Check if this is preview mode (from package details for unpaid users)
      bool isPreviewMode = widget.isPreviewMode == true;

      // Check purchase status if package is provided and in preview mode
      if (widget.package != null && isPreviewMode) {
        await _checkPurchaseStatus();
      } else if (isPreviewMode) {
        // Force preview mode for unpaid users
        hasPurchased = false;
      } else {
        // If no package provided and not preview mode, assume this is from MyTrips (paid packages)
        hasPurchased = true;
      }
    }

    if (widget.allStops != null && widget.allStops!.isNotEmpty) {
      // For paid packages, show all stops; for preview mode, limit to first 2
      if (hasPurchased) {
        tourStops = widget.allStops!;
      } else {
        tourStops = widget.allStops!.take(2).toList();
      }
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
          'audio_url': 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
        },
      ];
      currentStopIndex = 0;
    }
    print('Initialized tour stops (hasPurchased: $hasPurchased, isPaidPackage: ${widget.isPaidPackage}, total stops: ${tourStops.length}): $tourStops');
  }

  void _initializeLocationAndDirections() async {
    print('MyTrip: Initializing location and directions');
    // Get current location
    final location = await LocationService.getCurrentLatLng();
    print('MyTrip: Got current location: $location');
    if (location != null && mounted) {
      setState(() {
        currentLocation = location;
      });
      print('MyTrip: Set current location state: $currentLocation');
      // Load nearby restaurants after getting location
      _loadNearbyRestaurants();
    } else {
      print('MyTrip: Failed to get current location - this may be why current location is not showing on map');
      // Set a default location for testing (Colombo, Sri Lanka)
      setState(() {
        currentLocation = const LatLng(6.9271, 79.8612); // Colombo coordinates
      });
      print('MyTrip: Set default location for testing: $currentLocation');
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
    print('MyTrip: _changeStop called with newIndex: $newIndex, tourStops.length: ${tourStops.length}, hasPurchased: $hasPurchased, isPreviewMode: ${widget.isPreviewMode}');
    if (newIndex >= 0 && newIndex < tourStops.length) {
      // For purchased packages, allow full access to all stops
      print('MyTrip: Allowing stop change to index: $newIndex (user has purchased: $hasPurchased)');
      setState(() => currentStopIndex = newIndex);
      _loadDirectionsForStop(tourStops[newIndex]);
      // Reload restaurants for new location if stop has coordinates
      _loadRestaurantsForStop(tourStops[newIndex]);
    } else {
      // If trying to access beyond available stops, show dialog for unpaid users in preview mode
      bool isPreviewMode = widget.isPreviewMode == true;
      if (!hasPurchased && isPreviewMode && newIndex >= 2) {
        print('MyTrip: Attempting to access beyond preview limit (index $newIndex >= 2), showing preview dialog');
        _showPreviewLimitDialog();
      } else {
        print('MyTrip: Invalid index or out of bounds: $newIndex (user has purchased: $hasPurchased, isPreviewMode: $isPreviewMode)');
      }
    }
  }

  void _showPreviewLimitDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Close button
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => Navigator.of(dialogContext).pop(),
                    child: Icon(Icons.close, color: Colors.white54, size: 24),
                  ),
                ),
                const SizedBox(height: 8),
                // Warning icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF40C4AA).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_outlined,
                    color: const Color(0xFF40C4AA),
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                // Warning text
                const Text(
                  'Preview is limited to the first 2 stops. Buy the tour to access all stops.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                // Buy Now button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Close the dialog first
                      Navigator.of(dialogContext).pop();
                      // Navigate to checkout screen with package data
                      print('MyTrip: Navigating to checkout with package: ${widget.package}');
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => CheckoutScreen(package: widget.package ?? {}),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Buy Now',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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

  Future<void> _checkPurchaseStatus() async {
    try {
      // Get the package ID
      final packageId = widget.package?['id']?.toString();
      if (packageId == null) {
        print('MyTrip: No package ID found');
        setState(() {
          hasPurchased = false;
        });
        return;
      }

      // Get user ID from storage
      final userId = await _getCurrentUserId();
      if (userId == null) {
        print('MyTrip: No user ID found');
        setState(() {
          hasPurchased = false;
        });
        return;
      }

      print('MyTrip: Checking payment status for package ID: $packageId, user ID: $userId');

      // Check payment status via API
      final response = await dashboardApi.checkPaymentStatus(packageId, userId);
      print('MyTrip: Payment status API response: $response');

      if (response['success'] == true) {
        final hasPaid = response['data']?['hasPaid'] ?? false;
        print('MyTrip: hasPaid value from API: $hasPaid');
        setState(() {
          hasPurchased = hasPaid;
        });
      } else {
        print('MyTrip: API response not successful');
        setState(() {
          hasPurchased = false;
        });
      }
    } catch (e) {
      print('MyTrip: Error checking payment status: $e');
      setState(() {
        hasPurchased = false;
      });
    }
  }

  Future<String?> _getCurrentUserId() async {
    try {
      // Get user ID from secure storage
      return await StorageHelper.getUserId();
    } catch (e) {
      print('MyTrip: Error getting current user ID: $e');
      return null;
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
    _reviewController.dispose();
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDestinationHeader(),
            _buildMapSection(),
            _buildAudioPlayer(),
            if (hasPurchased) _buildReviewsSection(),
            _buildRestaurantsSection(),
          ],
        ),
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
    // Convert tour stops to TourStop objects for TourRouteMap
    final tourStops = _convertToTourStops();
    print('MyTrip: Building map section with ${tourStops.length} stops');
    print('MyTrip: Current location: $currentLocation');
    print('MyTrip: Current stop index: $currentStopIndex');

    return Container(
      margin: const EdgeInsets.all(16),
      height: 400, // Reduced height to prevent overflow
      child: TourRouteMap(
        tourStops: tourStops,
        showRouteLine: hasPurchased || widget.isPreviewMode == true, // Show route line for paid users OR preview mode (first 2 stops)
        focusedStopIndex: currentStopIndex,
        currentLocation: currentLocation,
        onStopTap: () {
          // Handle stop tap if needed
          print('MyTrip: Stop tapped on map');
        },
        onMapTap: () {
          // Handle map tap if needed
          print('MyTrip: Map tapped');
        },
      ),
    );
  }

  List<TourStop> _convertToTourStops() {
    return tourStops.asMap().entries.map((entry) {
      final index = entry.key;
      final stop = entry.value;

      // Create Location object if coordinates exist
      Location? location;
      if (stop['location'] != null) {
        final locData = stop['location'];
        if (locData['latitude'] != null && locData['longitude'] != null) {
          location = Location(
            id: locData['id'] ?? 0,
            latitude: (locData['latitude'] as num).toDouble(),
            longitude: (locData['longitude'] as num).toDouble(),
            district: locData['district'],
            city: locData['city'],
            province: locData['province'],
            address: locData['address'],
            postalCode: locData['postal_code'],
          );
        }
      }

      // Convert media data
      List<Media> mediaList = [];
      if (stop['media'] != null && stop['media'] is List) {
        mediaList = (stop['media'] as List).map((mediaItem) {
          return Media(
            id: mediaItem['id'] ?? 0,
            url: mediaItem['url'] ?? '',
            mediaType: mediaItem['media_type'] == 'audio' ? MediaType.audio : MediaType.image,
            durationSeconds: mediaItem['duration_seconds'],
          );
        }).toList();
      }

      return TourStop(
        id: stop['id'] ?? index + 1,
        sequenceNo: index + 1,
        stopName: stop['stop_name'] ?? stop['title'] ?? 'Stop ${index + 1}',
        description: stop['description'],
        location: location,
        media: mediaList,
      );
    }).toList();
  }

  Widget _buildReviewsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Write a Review',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Rate this tour',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(
              5,
              (index) => GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedRating = index + 1;
                  });
                },
                child: Icon(
                  index < _selectedRating ? Icons.star : Icons.star_border,
                  color: Colors.blue,
                  size: 32,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reviewController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Write your review...',
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: const Color(0xFF2A2A2A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Submit Review',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
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
    // Get audio URL for current stop
    String audioUrl = _getAudioUrlForCurrentStop();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFF0D0D12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.skip_previous, color: Colors.white, size: 28),
            onPressed: () => _changeStop(currentStopIndex - 1),
          ),
          Expanded(
            child: AudioPlayerWidget(
              audioUrl: audioUrl,
              title: currentStopTitle,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.skip_next, color: Colors.white, size: 28),
            onPressed: () {
              print('MyTrip: Next button pressed in audio player');
              _changeStop(currentStopIndex + 1);
            },
          ),
        ],
      ),
    );
  }

  String _getAudioUrlForCurrentStop() {
    if (tourStops.isEmpty) {
      print('No tour stops available, using fallback audio');
      return 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav';
    }

    final currentStop = tourStops[currentStopIndex];
    print('Current stop data: $currentStop');

    // Check if this stop has media data (like in package-details)
    if (currentStop['media'] != null && (currentStop['media'] as List).isNotEmpty) {
      print('Stop has media data: ${currentStop['media']}');
      // Find audio media
      final audioMedia = (currentStop['media'] as List).firstWhere(
        (media) => media['media_type'] == 'audio',
        orElse: () => null,
      );
      if (audioMedia != null) {
        // The media is directly in the audioMedia object, not nested under 'media'
        final url = audioMedia['url'];
        print('Found audio media URL: $url');
        if (url != null && url.isNotEmpty) {
          final fullUrl = MediaService.getFullUrl(url);
          print('Full audio URL: $fullUrl');
          return fullUrl;
        }
      }
    }

    // Fallback to audio_url field
    final audioUrl = currentStop['audio_url'] ?? currentStop['audioUrl'];
    print('Fallback audio URL: $audioUrl');
    if (audioUrl != null && audioUrl.isNotEmpty) {
      final fullUrl = MediaService.getFullUrl(audioUrl);
      print('Full fallback URL: $fullUrl');
      return fullUrl;
    }

    // Final fallback - use a working audio URL that supports CORS and is accessible
    print('Using final fallback audio');
    // Try a different audio URL that might work better on web - use a more compatible format
    return 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav';
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

  void _submitReview() {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write a review'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // In a real app, this would send the review to the backend
    // For now, just show success message and reset the form
    setState(() {
      _selectedRating = 0;
      _reviewController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Review submitted successfully!'),
        backgroundColor: Color(0xFF40C4AA),
      ),
    );
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