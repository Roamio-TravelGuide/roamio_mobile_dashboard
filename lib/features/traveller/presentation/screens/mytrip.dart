// mytrip.dart - Fixed MediaService usage and improved filtering
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/widgets/audio_player_widget.dart';
import '../../../../core/services/media_service.dart'; // Import your MediaService
import '../../../../core/widgets/tour_route_map.dart';
import '../../../../core/models/tour_package.dart';
import 'package_checkout.dart';
import '../../api/dashboard_api.dart';
import '../../api/traveller_api.dart';
import '../../../../core/utils/storage_helper.dart';
import '../../../../core/services/payment_verification_service.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/services/location_service.dart';

class MyTripScreen extends StatefulWidget {
  final Map<String, dynamic>? stop;
  final List<Map<String, dynamic>>? allStops;
  final Map<String, dynamic>? package;
  final bool? isPreviewMode;
  final bool? isPaidPackage;

  const MyTripScreen({
    super.key, 
    this.stop, 
    this.allStops, 
    this.package, 
    this.isPreviewMode, 
    this.isPaidPackage
  });

  @override
  State<MyTripScreen> createState() => _MyTripScreenState();
}

class _MyTripScreenState extends State<MyTripScreen> {
  final AudioPlayer audioPlayer = AudioPlayer();
  late DashboardApi dashboardApi;
  
  List<Map<String, dynamic>> tourStops = [];
  int currentStopIndex = 0;
  bool hasPurchased = false;

  LatLng? currentLocation;
  LatLng? currentStopLocation;

  List<Map<String, dynamic>> nearbyPlaces = [];
  bool isLoadingPlaces = false;

  // Review state
  int _selectedRating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isAddingReview = false;

  @override
  void initState() {
    super.initState();
    dashboardApi = DashboardApi(apiClient: ApiClient(customBaseUrl: EnvConfig.baseUrl));
    _initializeTourStops();
    _initializeLocation();
  }

  void _initializeTourStops() async {
    print('MyTrip: Initializing tour stops...');
    
    if (widget.isPaidPackage == true) {
      hasPurchased = true;
      print('MyTrip: This is explicitly marked as a paid package - granting full access');
    } else if (widget.package != null) {
      final packageIdRaw = widget.package!['id'];
      final packageId = packageIdRaw?.toString();
      if (packageId != null) {
        print('MyTrip: Checking payment status for package ID: $packageId');
        try {
          final accessLevel = await PaymentVerificationService.getPackageAccessLevel(packageId);
          hasPurchased = accessLevel == PackageAccessLevel.fullAccess;
          print('MyTrip: Payment verification result - Access Level: $accessLevel, hasPurchased: $hasPurchased');
        } catch (e) {
          print('MyTrip: Error checking payment status: $e');
          hasPurchased = widget.isPreviewMode != true;
        }
      } else {
        hasPurchased = widget.isPreviewMode != true;
      }
    } else {
      hasPurchased = true;
      print('MyTrip: No package provided, assuming paid access');
    }

    // Initialize tour stops based on payment status
    if (widget.allStops != null && widget.allStops!.isNotEmpty) {
      if (hasPurchased) {
        tourStops = List.from(widget.allStops!);
        print('MyTrip: Full access granted - showing all ${tourStops.length} stops');
      } else {
        tourStops = widget.allStops!.take(2).toList();
        print('MyTrip: Preview mode - limiting to first ${tourStops.length} stops');
      }
      
      // Set current stop index
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
          'id': 1,
          'stop_name': 'Tanah Lot Temple',
          'title': 'Tanah Lot Temple',
          'audio_url': 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
          'description': 'A beautiful temple by the sea',
        },
      ];
      currentStopIndex = 0;
    }
    
    // Extract current stop location for API calls
    _extractCurrentStopLocation();
    
    // Ensure state is updated
    if (mounted) setState(() {});
  }

  void _extractCurrentStopLocation() {
    if (tourStops.isNotEmpty && currentStopIndex < tourStops.length) {
      final currentStop = tourStops[currentStopIndex];
      if (currentStop['location'] != null) {
        final location = currentStop['location'];
        if (location['latitude'] != null && location['longitude'] != null) {
          setState(() {
            currentStopLocation = LatLng(
              (location['latitude'] as num).toDouble(),
              (location['longitude'] as num).toDouble()
            );
          });
          print('MyTrip: Current stop location - Lat: ${currentStopLocation!.latitude}, Lng: ${currentStopLocation!.longitude}');
          
          // Load nearby places using stop location
          _loadNearbyPlaces();
        }
      }
    }
  }

  void _initializeLocation() async {
  print('MyTrip: Initializing location...');
  
  try {
    final location = await LocationService.getCurrentLatLng();
    
    if (location != null && mounted) {
      print('MyTrip: Current location obtained: ${location.latitude}, ${location.longitude}');
      setState(() {
        currentLocation = location;
      });
    } else {
      print('MyTrip: Failed to get current location, using default');
      // Fallback to default location if current location can't be obtained
      setState(() {
        currentLocation = const LatLng(6.9271, 79.8612); // Colombo coordinates as fallback
      });
    }
  } catch (e) {
    print('MyTrip: Error getting current location: $e');
    // Fallback to default location on error
    setState(() {
      currentLocation = const LatLng(6.9271, 79.8612); // Colombo coordinates as fallback
    });
  }
}

  Future<void> _loadNearbyPlaces() async {
    if (currentStopLocation == null) {
      print('MyTrip: No stop location available for places API call');
      return;
    }
    
    setState(() => isLoadingPlaces = true);

    try {
      print('MyTrip: Calling API for nearby places at ${currentStopLocation!.latitude}, ${currentStopLocation!.longitude}');
      
      // Call your backend API to get nearby places with 5km radius
      final response = await dashboardApi.getNearbyPlaces(
        latitude: currentStopLocation!.latitude,
        longitude: currentStopLocation!.longitude,
        radius: 5,
      );

    print('MyTrip: API Response: $response');
    
    if (response['success'] == true && response['data'] != null) {
      final placesData = List<Map<String, dynamic>>.from(response['data']);
      print('MyTrip: Received ${placesData.length} places from API');
      
      // Show ALL places without any filtering
      print('MyTrip: Showing all ${placesData.length} places from API');
      
      if (mounted) {
        setState(() {
          nearbyPlaces = placesData;
        });
      }
    } else {
      print('MyTrip: API call failed or no data received');
      print('MyTrip: Success: ${response['success']}');
      print('MyTrip: Error: ${response['error']}');
    }
  } catch (e) {
    print('MyTrip: Error loading nearby places: $e');
  } finally {
    if (mounted) {
      setState(() {
        isLoadingPlaces = false;
      });
    }
  }
}

  void _changeStop(int newIndex) async {
    print('MyTrip: _changeStop called with newIndex: $newIndex');
    print('MyTrip: Current tourStops length: ${tourStops.length}');
    print('MyTrip: Has purchased: $hasPurchased');
    
    // Check if the new index is within available stops
    if (newIndex >= 0 && newIndex < tourStops.length) {
      // For preview mode, only allow first stop (index 0)
      if (!hasPurchased && newIndex > 0) {
        print('MyTrip: Preview mode - cannot access stop $newIndex, showing dialog');
        _showPreviewLimitDialog();
        return;
      }
      
      print('MyTrip: Allowing stop change to index: $newIndex');
      setState(() => currentStopIndex = newIndex);
      
      // Extract new stop location and load nearby places
      _extractCurrentStopLocation();
      return;
    }

    // Handle going beyond available stops
    if (newIndex >= tourStops.length) {
      print('MyTrip: Attempting to access beyond available stops');
      
      if (hasPurchased) {
        print('MyTrip: User has paid but no more stops available');
        return;
      }

      // For preview mode, show dialog when trying to go beyond first stop
      _showPreviewLimitDialog();
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
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => Navigator.of(dialogContext).pop(),
                    child: const Icon(Icons.close, color: Colors.white54, size: 24),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF40C4AA).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_outlined,
                    color: Color(0xFF40C4AA),
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
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

  void _refreshPlaces() {
    _loadNearbyPlaces();
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
            onPressed: _refreshPlaces,
            tooltip: 'Refresh nearby places',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDestinationHeader(),
            _buildMapSection(),
            _buildStopDetailsSection(),
            _buildAudioPlayer(),
            if (hasPurchased) _buildReviewsSection(),
            if (nearbyPlaces.isNotEmpty || isLoadingPlaces) _buildNearbyPlacesSection(),
            const SizedBox(height: 20),
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
    final tourStopsList = _convertToTourStops();
    final nearbyPlacesList = _convertToNearbyPlaces();
    
    return Container(
      margin: const EdgeInsets.all(16),
      height: 400,
      child: TourRouteMap(
        tourStops: tourStopsList,
        nearbyPlaces: nearbyPlacesList, // Pass nearby places to the map
        showRouteLine: hasPurchased || widget.isPreviewMode == true,
        focusedStopIndex: currentStopIndex,
        currentLocation: currentLocation,
        onStopTap: () {
          print('MyTrip: Stop tapped on map');
        },
        onMapTap: () {
          print('MyTrip: Map tapped');
        },
      ),
    );
  }

  Widget _buildStopDetailsSection() {
    if (tourStops.isEmpty || currentStopIndex >= tourStops.length) {
      return const SizedBox.shrink();
    }

    final currentStop = tourStops[currentStopIndex];
    final description = currentStop['description'];
    final hasDescription = description != null && 
                          description.toString().trim().isNotEmpty && 
                          description.toString().trim().toLowerCase() != 'null';
    
    // Get stop image from media array
    String? stopImageUrl;
    if (currentStop['media'] != null && (currentStop['media'] as List).isNotEmpty) {
      final mediaList = currentStop['media'] as List;
      final imageMedia = mediaList.firstWhere(
        (media) => media['media_type'] == 'image',
        orElse: () => null,
      );
      
      if (imageMedia != null && imageMedia['url'] != null && imageMedia['url'].isNotEmpty) {
        stopImageUrl = MediaService.getFullUrl(imageMedia['url']);
      }
    }

    // Show the section if there's an image, even without description
    if (!hasDescription && stopImageUrl == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'About this Stop',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          if (stopImageUrl != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              constraints: BoxConstraints(
                minHeight: 200,
                maxHeight: 400,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade800,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  stopImageUrl,
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: double.infinity,
                    height: 200,
                    color: Colors.grey.shade800,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                        strokeWidth: 2,
                        color: Colors.blue,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  print('Stop image failed to load: $error');
                  print('Stop image URL: $stopImageUrl');
                  // Use fallback image when server image fails
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=600&h=300&fit=crop',
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        // Final fallback to container
                        return Container(
                          width: double.infinity,
                          height: 200,
                          color: Colors.grey.shade700,
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_not_supported,
                                  color: Colors.white54,
                                  size: 50,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Image not available',
                                  style: TextStyle(color: Colors.white54, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          ],
          
          if (hasDescription) ...[
            const SizedBox(height: 16),
            Text(
              description.toString(),
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ] else if (stopImageUrl != null) ...[
            // Show a message when there's an image but no description
            const SizedBox(height: 16),
            Text(
              'Enjoy the beautiful scenery at this stop. Listen to the audio guide for more information about this location.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<TourStop> _convertToTourStops() {
    return tourStops.asMap().entries.map((entry) {
      final index = entry.key;
      final stop = entry.value;

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

  List<NearbyPlace> _convertToNearbyPlaces() {
    return nearbyPlaces.map((place) {
      final placeType = place['place_type']?.toString().toLowerCase() ?? '';
      final category = place['category']?.toString().toLowerCase() ?? '';
      
      // Determine place type for map marker
      PlaceType type;
      if (placeType == 'restaurant' || category == 'restaurant') {
        type = PlaceType.restaurant;
      } else if (placeType == 'hidden_gem' || category == 'hidden_gem') {
        type = PlaceType.hiddenGem;
      } else {
        type = PlaceType.attraction;
      }

      return NearbyPlace(
        id: place['id']?.toString() ?? '0',
        name: place['name'] ?? 'Nearby Place',
        location: LatLng(
          (place['latitude'] as num).toDouble(),
          (place['longitude'] as num).toDouble(),
        ),
        type: type,
        distance: place['distance_km']?.toDouble() ?? 0.0,
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
              onPressed: _isAddingReview ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isAddingReview
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
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

  Widget _buildNearbyPlacesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nearby Places',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isLoadingPlaces)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildPlacesList(),
      ],
    );
  }

  Widget _buildPlacesList() {
    if (isLoadingPlaces) {
      return _buildLoadingIndicator();
    }

    if (nearbyPlaces.isEmpty) {
      return _buildEmptyState(
        icon: Icons.explore,
        message: 'No nearby places found',
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: nearbyPlaces.map((place) {
          return _buildPlaceChip(place);
        }).toList(),
      ),
    );
  }

  Widget _buildPlaceChip(Map<String, dynamic> place) {
    final name = place['name'] ?? 'Place';
    final distance = place['distance_km'] != null 
        ? '${place['distance_km']} km' 
        : 'Nearby';
    
    // Determine place type and styling
    final placeType = place['place_type']?.toString().toLowerCase() ?? '';
    final category = place['category']?.toString().toLowerCase() ?? '';
    final businessType = place['business_type']?.toString().toLowerCase() ?? '';
    
    bool isRestaurant = placeType == 'restaurant' || 
                       category == 'restaurant' || 
                       businessType == 'restaurant' ||
                       name.toLowerCase().contains('restaurant') ||
                       name.toLowerCase().contains('cafe') ||
                       name.toLowerCase().contains('food');
    
    bool isHiddenGem = placeType == 'hidden_gem' || 
                      category == 'hidden_gem' ||
                      (name.toLowerCase().contains('hidden') ||
                       name.toLowerCase().contains('secret') ||
                       name.toLowerCase().contains('local'));
    
    // Set colors and icon based on type
    Color primaryColor;
    IconData icon;
    String typeLabel;
    
    if (isRestaurant) {
      primaryColor = Colors.blue;
      icon = Icons.restaurant;
      typeLabel = 'Restaurant';
    } else if (isHiddenGem) {
      primaryColor = Colors.amber;
      icon = Icons.auto_awesome;
      typeLabel = 'Hidden Gem';
    } else {
      primaryColor = Colors.green;
      icon = Icons.explore;
      typeLabel = 'Attraction';
    }

    return GestureDetector(
      onTap: () {
        _showPlaceDetails(place);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 6),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                distance,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlaceDetails(Map<String, dynamic> place) {
    final name = place['name'] ?? 'Place';
    final description = place['description'] ?? 'A great place to visit';
    final distance = place['distance_km'] != null 
        ? '${place['distance_km']} km' 
        : 'Nearby';
    
    // Determine place type and styling
    final placeType = place['place_type']?.toString().toLowerCase() ?? '';
    final category = place['category']?.toString().toLowerCase() ?? '';
    final businessType = place['business_type']?.toString().toLowerCase() ?? '';
    
    bool isRestaurant = placeType == 'restaurant' || 
                       category == 'restaurant' || 
                       businessType == 'restaurant' ||
                       name.toLowerCase().contains('restaurant') ||
                       name.toLowerCase().contains('cafe') ||
                       name.toLowerCase().contains('food');
    
    bool isHiddenGem = placeType == 'hidden_gem' || 
                      category == 'hidden_gem' ||
                      (name.toLowerCase().contains('hidden') ||
                       name.toLowerCase().contains('secret') ||
                       name.toLowerCase().contains('local'));
    
    // Set colors and icon based on type
    Color primaryColor;
    IconData icon;
    String typeLabel;
    
    if (isRestaurant) {
      primaryColor = Colors.blue;
      icon = Icons.restaurant;
      typeLabel = 'Restaurant';
    } else if (isHiddenGem) {
      primaryColor = Colors.amber;
      icon = Icons.auto_awesome;
      typeLabel = 'Hidden Gem';
    } else {
      primaryColor = Colors.green;
      icon = Icons.explore;
      typeLabel = 'Attraction';
    }

    // Get image URL
    String? imageUrl;
    if (place['cover_image'] != null && place['cover_image'].toString().isNotEmpty) {
      imageUrl = place['cover_image'];
    } else if (place['logo_image'] != null && place['logo_image'].toString().isNotEmpty) {
      imageUrl = place['logo_image'];
    } else if (place['images'] != null && (place['images'] as List).isNotEmpty) {
      imageUrl = (place['images'] as List).first;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with close button
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: primaryColor, size: 24),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                
                // Image if available
                if (imageUrl != null)
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: NetworkImage(MediaService.getFullUrl(imageUrl)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                
                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Type and distance
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              typeLabel,
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              distance,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Description
                      if (description != null && description.isNotEmpty)
                        Text(
                          description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      
                      // Additional info
                      if (place['address'] != null && place['address'].toString().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.location_on, color: primaryColor, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                place['address'].toString(),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      
                      if (place['rating'] != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.star, color: primaryColor, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${place['rating']}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white54, size: 20),
            const SizedBox(width: 8),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
      ),
    );
  }

  Widget _buildAudioPlayer() {
    String audioUrl = _getAudioUrlForCurrentStop();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: const Color(0xFF0D0D12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.skip_previous, color: Colors.white, size: 28),
            onPressed: currentStopIndex > 0 ? () => _changeStop(currentStopIndex - 1) : null,
          ),
          Expanded(
            child: AudioPlayerWidget(
              audioUrl: audioUrl,
              title: currentStopTitle,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.skip_next, color: Colors.white, size: 28),
            onPressed: currentStopIndex < tourStops.length - 1 ? () {
              _changeStop(currentStopIndex + 1);
            } : null,
          ),
        ],
      ),
    );
  }

  String _getAudioUrlForCurrentStop() {
    if (tourStops.isEmpty) {
      return 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav';
    }

    final currentStop = tourStops[currentStopIndex];

    // First check media array
    if (currentStop['media'] != null && (currentStop['media'] as List).isNotEmpty) {
      final audioMedia = (currentStop['media'] as List).firstWhere(
        (media) => media['media_type'] == 'audio',
        orElse: () => null,
      );
      if (audioMedia != null) {
        final url = audioMedia['url'];
        if (url != null && url.isNotEmpty) {
          return MediaService.getFullUrl(url); // FIXED: Using correct method name
        }
      }
    }

    // Then check direct audio_url
    final audioUrl = currentStop['audio_url'];
    if (audioUrl != null && audioUrl.isNotEmpty) {
      return MediaService.getFullUrl(audioUrl); // FIXED: Using correct method name
    }

    // Fallback to default audio
    return 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav';
  }

  Future<void> _submitReview() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isAddingReview = true);

    try {
      final travellerApi = TravellerApi(apiClient: ApiClient(customBaseUrl: EnvConfig.baseUrl));

      final packageId = widget.package?['id'];
      if (packageId == null) {
        throw Exception('Package ID is required');
      }

      final response = await travellerApi.createReview(
        packageId: packageId is String ? int.parse(packageId) : packageId as int,
        rating: _selectedRating,
        comments: _reviewController.text.trim().isNotEmpty ? _reviewController.text.trim() : null,
      );

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          _selectedRating = 0;
          _reviewController.clear();
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to submit review');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit review: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isAddingReview = false);
    }
  }
}