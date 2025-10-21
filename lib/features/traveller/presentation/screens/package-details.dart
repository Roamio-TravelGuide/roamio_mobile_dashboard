import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:just_audio/just_audio.dart';
import './package_checkout.dart';
import 'audioplayer.dart';
import 'gallery_page.dart';
import 'mytrip.dart';
import '../../../../core/services/mapbox_service.dart';
import '../../../../core/services/media_service.dart';
import '../../../../core/services/payment_verification_service.dart';
import '../../../../core/widgets/audio_player_widget.dart';
import '../../api/dashboard_api.dart';
import '../../api/traveller_api.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/utils/storage_helper.dart';

class DestinationDetailsPage extends StatefulWidget {
  final Map<String, dynamic>? package;
  final bool? isFromMyTrips;

  const DestinationDetailsPage({super.key, this.package, this.isFromMyTrips});

  @override
  State<DestinationDetailsPage> createState() => _DestinationDetailsPageState();
}

class _DestinationDetailsPageState extends State<DestinationDetailsPage> {
  int? currentPlayingIndex;
  bool isPlaying = false;
  AudioPlayer? audioPlayer;
  double? distanceToFirstStop;
  double? totalDistance;
  final MapboxService _mapboxService = MapboxService();
  late DashboardApi dashboardApi;
  bool? hasPurchased;

  List<Map<String, dynamic>> get stopTitles {
    if (widget.package?['tour_stops'] != null) {
      return List<Map<String, dynamic>>.from(widget.package!['tour_stops']);
    }
    return [];
  }

  @override
  void initState() {
    super.initState();
    print('PackageDetails: initState called with package data: ${widget.package}');
    print('PackageDetails: Number of tour stops: ${stopTitles.length}');
    for (int i = 0; i < stopTitles.length; i++) {
      print('PackageDetails: Stop $i data: ${stopTitles[i]}');
    }
    dashboardApi = DashboardApi(apiClient: ApiClient(customBaseUrl: EnvConfig.baseUrl));
    audioPlayer = AudioPlayer();
    
    _setupAudioListeners();
    _calculateDistanceToFirstStop();
    _calculateTotalDistance();
    _checkPurchaseStatus();
  }

  void _setupAudioListeners() {
    audioPlayer!.playerStateStream.listen((state) {
      setState(() {
        isPlaying = state.playing && state.processingState != ProcessingState.completed;
      });
    });
  }

  Future<void> _checkPurchaseStatus() async {
    print('PackageDetails: Checking purchase status...');

    if (widget.isFromMyTrips == true) {
      hasPurchased = true;
      print('PackageDetails: This is explicitly marked as from MyTrips - granting full access');
    } else if (widget.package != null) {
      final packageIdRaw = widget.package!['id'];
      final packageId = packageIdRaw?.toString();
      if (packageId != null) {
        print('PackageDetails: Checking payment status for package ID: $packageId');
        try {
          final accessLevel = await PaymentVerificationService.getPackageAccessLevel(packageId);
          hasPurchased = accessLevel == PackageAccessLevel.fullAccess;
          print('PackageDetails: Payment verification result - Access Level: $accessLevel, hasPurchased: $hasPurchased');
        } catch (e) {
          print('PackageDetails: Error checking payment status: $e');
          hasPurchased = false;
        }
      } else {
        hasPurchased = false;
        print('PackageDetails: No package ID available');
      }
    } else {
      hasPurchased = true;
      print('PackageDetails: No package provided, assuming paid access');
    }

    // Ensure state is updated
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    audioPlayer?.dispose();
    super.dispose();
  }

  String get heroImage {
    print('Getting hero image for package: ${widget.package?.keys.toList()}');
    
    // Try cover_image first
    if (widget.package?['cover_image'] != null) {
      String? coverImageUrl;
      
      if (widget.package!['cover_image'] is String) {
        coverImageUrl = widget.package!['cover_image'];
      } else if (widget.package!['cover_image'] is Map && widget.package!['cover_image']['url'] != null) {
        coverImageUrl = widget.package!['cover_image']['url'];
      }
      
      if (coverImageUrl != null && coverImageUrl.isNotEmpty) {
        final url = MediaService.getFullUrl(coverImageUrl);
        print('Hero image from cover_image: $url');
        return url;
      }
    }
    
    // Fallback to first stop image if cover image is not available
    if (stopTitles.isNotEmpty) {
      final firstStopImage = _getStopImageUrl(stopTitles[0]);
      if (!firstStopImage.contains('placeholder')) {
        print('Hero image from first stop: $firstStopImage');
        return firstStopImage;
      }
    }
    
    print('Using fallback for hero image');
    return 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&h=400&fit=crop';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      extendBody: true,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildAppBar(),
              _buildContent(),
            ],
          ),
          if (currentPlayingIndex != null) _buildAudioPlayerOverlay(),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      pinned: true,
      expandedHeight: 320, // Increased height for better image visibility
      elevation: 0,
      automaticallyImplyLeading: false,
      leadingWidth: 0,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax, // Changed to parallax for better effect
        background: Stack(
          fit: StackFit.expand,
          children: [
            _buildHeroImage(),
            const _TopToBottomShade(),
            _buildAppBarActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroImage() {
    return Positioned.fill(
      child: ClipRect(
        child: Image.network(
          heroImage,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey.shade800,
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('Error loading hero image: $error');
            print('Hero image URL: $heroImage');
            // Try fallback image instead of showing error container
            return ClipRect(
              child: Image.network(
                'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&h=400&fit=crop',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (context, error, stackTrace) {
                  // Final fallback to container
                  return Container(
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
    );
  }

  Widget _buildAppBarActions() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 12,
      right: 12,
      child: Row(
        children: [
          _CircleIconButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const Spacer(),
          _CircleIconButton(
            icon: Icons.bookmark_border,
            onTap: () {},
          ),
          const SizedBox(width: 8),
          _CircleIconButton(icon: Icons.ios_share, onTap: () {}),
          const SizedBox(width: 8),
          _CircleIconButton(icon: Icons.warning, onTap: _testDialog),
        ],
      ),
    );
  }

  SliverPadding _buildContent() {
    return SliverPadding(
      padding: EdgeInsets.only(
        top: 16,
        bottom: currentPlayingIndex != null ? 160 : 16,
      ),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _buildPackageDetails(),
          const SizedBox(height: 16),
          _buildGallerySection(),
          const SizedBox(height: 20),
          _buildTripStopsSection(),
          const SizedBox(height: 20),
          _buildReviewsSection(),
          if (currentPlayingIndex != null) const SizedBox(height: 120),
        ]),
      ),
    );
  }

  Widget _buildPackageDetails() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _EllaDetailsSection(
        package: widget.package,
        getPackageLocation: _getPackageLocation,
        distanceToFirstStop: distanceToFirstStop,
        allStops: stopTitles,
        totalDistance: totalDistance,
        hasPurchased: hasPurchased ?? false,
      ),
    );
  }

  Widget _buildGallerySection() {
    print('Building gallery section with ${stopTitles.length} stops');
    return Column(
      children: [
        _SectionHeader(
          title: 'Gallery',
          actionLabel: 'See All',
          onAction: () {
            final availableStops = hasPurchased ?? false ? stopTitles : stopTitles.take(1).toList();
            final galleryItems = availableStops.map((stop) {
              final imageUrl = _getStopImageUrl(stop);
              return {
                'image': imageUrl,
                'title': stop['stop_name'] ?? 'Stop'
              };
            }).toList();

            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => GalleryPage(
                  title: 'Package Gallery',
                  galleryItems: galleryItems,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: (hasPurchased ?? false) ? stopTitles.length : 1,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final stop = stopTitles[index];
              final imageUrl = _getStopImageUrl(stop);
              final stopName = stop['stop_name'] ?? 'Stop ${index + 1}';

              return GestureDetector(
                onTap: () {
                  if ((hasPurchased ?? false) || index == 0) {
                    _showFullScreenImage(context, imageUrl, stopName);
                  } else {
                    _showBuyTourDialog(context, widget.package);
                  }
                },
                child: Column(
                  children: [
                    Expanded(
                      child: SizedBox(
                        width: 100,
                        child: Stack(
                          children: [
                            _GalleryThumb(url: imageUrl),
                            if ((hasPurchased == null || hasPurchased == false) && index > 0)
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.lock,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 100,
                      child: Text(
                        stopName,
                        style: TextStyle(
                          color: (hasPurchased == null || hasPurchased == false) && index > 0 
                            ? Colors.white38 
                            : Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTripStopsSection() {
    print('Building trip stops section with ${stopTitles.length} stops');
    for (int i = 0; i < stopTitles.length; i++) {
      print('Stop $i: ${stopTitles[i]}');
    }
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Trip to ${widget.package?['title'] ?? 'Package'}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: List.generate(stopTitles.length, (index) {
              final stop = stopTitles[index];
              final isPreviewLimited = !(hasPurchased ?? false) && index > 0;
              final showPreviewBadge = (hasPurchased == null || hasPurchased == false) && index <= 0;
              final imageUrl = _getStopImageUrl(stop);
              
              print('Building audio card for stop $index with image: $imageUrl');

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AudioCard(
                  title: stop['stop_name'] ?? 'Stop ${index + 1}',
                  description: stop['description'] ?? 'No description available.',
                  image: imageUrl, // Use our image URL method
                  index: index,
                  onPlayAudio: () => _onPlayAudio(index),
                  onShowDirections: () => _onShowDirections(index), // Pass the correct index
                  isCurrentlyPlaying: currentPlayingIndex == index && isPlaying,
                  isPreviewLimited: isPreviewLimited,
                  showPreviewBadge: showPreviewBadge,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      children: [
        _SectionHeader(
          title: 'Reviews',
          actionLabel: 'See All',
          onAction: _showAllReviews,
        ),
        const SizedBox(height: 12),
        _ReviewsSection(
          packageId: widget.package?['id'] is String
              ? int.tryParse(widget.package!['id'])
              : widget.package?['id'] as int?,
          averageRating: widget.package?['average_rating'] ?? 0.0,
        ),
      ],
    );
  }

  Widget _buildAudioPlayerOverlay() {
    final currentStop = stopTitles[currentPlayingIndex!];
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E2E),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                currentStop['stop_name'] ?? 'Current Stop',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: currentPlayingIndex! > 0 ? () {
                      _changeStop(currentPlayingIndex! - 1);
                    } : null,
                    icon: const Icon(Icons.skip_previous, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AudioPlayerWidget(
                      audioUrl: _getAudioUrlForStop(currentStop),
                      title: 'Play Audio for ${currentStop['stop_name'] ?? 'Current Stop'}',
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: currentPlayingIndex! < stopTitles.length - 1 ? () {
                      _onNextStop();
                    } : null,
                    icon: const Icon(Icons.skip_next, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Audio Methods
  void _onPlayAudio(int index) {
    if ((hasPurchased == null || hasPurchased == false) && index > 0) {
      _showBuyTourDialog(context, widget.package);
      return;
    }

    setState(() {
      if (currentPlayingIndex == index && isPlaying) {
        isPlaying = false;
      } else {
        currentPlayingIndex = index;
        isPlaying = true;
      }
    });
    _loadCurrentAudio();
  }

  void _onNextStop() {
    if (currentPlayingIndex != null && currentPlayingIndex! < stopTitles.length - 1) {
      _onPlayAudio(currentPlayingIndex! + 1);
    }
  }

  void _loadCurrentAudio() async {
    if (audioPlayer != null && currentPlayingIndex != null && stopTitles.isNotEmpty) {
      final stop = stopTitles[currentPlayingIndex!];
      String audioUrl;

      if (stop['media'] != null && (stop['media'] as List).isNotEmpty) {
        final audioMedia = (stop['media'] as List).firstWhere(
          (media) => media['media_type'] == 'audio',
          orElse: () => null,
        );
        if (audioMedia != null) {
          audioUrl = audioMedia['url'] ?? 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav';
        } else {
          audioUrl = 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav';
        }
      } else {
        audioUrl = stop['audio_url'] ?? 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav';
      }

      try {
        await audioPlayer!.setUrl(audioUrl);
        if (isPlaying) {
          audioPlayer?.play();
        }
      } catch (e) {
        print('Error loading audio: $e');
      }
    }
  }

  void _changeStop(int newIndex) {
    if (newIndex >= 0 && newIndex < stopTitles.length) {
      setState(() {
        currentPlayingIndex = newIndex;
        isPlaying = true;
      });
      _loadCurrentAudio();
      audioPlayer?.play();
    }
  }

  void _onShowDirections(int index) {
    print('PackageDetails: Show directions for stop index: $index');
    
    if ((hasPurchased == null || hasPurchased == false) && index > 0) {
      _showBuyTourDialog(context, widget.package);
      return;
    }

    // Get the specific stop to show directions to
    final targetStop = stopTitles.isNotEmpty && index < stopTitles.length 
        ? stopTitles[index] 
        : null;
        
    final isPreviewMode = (hasPurchased == null || hasPurchased == false);
    
    print('PackageDetails: Navigating to MyTrip with stop index: $index');
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MyTripScreen(
          stop: targetStop,
          allStops: stopTitles,
          package: widget.package,
          isPreviewMode: isPreviewMode,
          isPaidPackage: hasPurchased ?? false,
        ),
      ),
    );
  }

  // Helper Methods
  String _getPackageLocation(Map<String, dynamic>? package) {
    if (package != null && package['tour_stops'] != null && package['tour_stops'] is List && package['tour_stops'].isNotEmpty) {
      final firstStop = package['tour_stops'][0];
      if (firstStop['location'] != null && firstStop['location']['city'] != null) {
        return firstStop['location']['city'];
      }
    }
    if (package != null && package['location'] != null) {
      return package['location'].toString();
    }
    return 'Location TBD';
  }

  Future<void> _calculateDistanceToFirstStop() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          distanceToFirstStop = -2;
        });
        return;
      }

      if (widget.package == null ||
          widget.package!['tour_stops'] == null ||
          widget.package!['tour_stops'] is! List ||
          widget.package!['tour_stops'].isEmpty) {
        return;
      }

      final firstStop = widget.package!['tour_stops'][0];
      if (firstStop['location'] == null ||
          firstStop['location']['latitude'] == null ||
          firstStop['location']['longitude'] == null) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            distanceToFirstStop = -1;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          distanceToFirstStop = -1;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final currentLocation = {'lat': position.latitude, 'lng': position.longitude};
      final stopLocation = {
        'lat': (firstStop['location']['latitude'] as num).toDouble(),
        'lng': (firstStop['location']['longitude'] as num).toDouble()
      };

      final distanceInMeters = _mapboxService.getDistanceBetweenPoints(
        Map<String, double>.from(currentLocation),
        Map<String, double>.from(stopLocation)
      );
      final distanceInKm = distanceInMeters / 1000;

      setState(() {
        distanceToFirstStop = distanceInKm;
      });
    } catch (e) {
      print('Error calculating distance: $e');
    }
  }

  Future<void> _calculateTotalDistance() async {
    try {
      if (widget.package == null ||
          widget.package!['tour_stops'] == null ||
          widget.package!['tour_stops'] is! List ||
          widget.package!['tour_stops'].length < 2) {
        return;
      }

      final firstStop = widget.package!['tour_stops'][0];
      final lastStop = widget.package!['tour_stops'].last;

      if (firstStop['location'] == null ||
          firstStop['location']['latitude'] == null ||
          firstStop['location']['longitude'] == null ||
          lastStop['location'] == null ||
          lastStop['location']['latitude'] == null ||
          lastStop['location']['longitude'] == null) {
        return;
      }

      final firstLat = (firstStop['location']['latitude'] as num).toDouble();
      final firstLng = (firstStop['location']['longitude'] as num).toDouble();
      final lastLat = (lastStop['location']['latitude'] as num).toDouble();
      final lastLng = (lastStop['location']['longitude'] as num).toDouble();

      final distanceInMeters = _mapboxService.getDistanceBetweenPoints(
        Map<String, double>.from({'lat': firstLat, 'lng': firstLng}),
        Map<String, double>.from({'lat': lastLat, 'lng': lastLng})
      );
      final distanceInKm = distanceInMeters / 1000;

      setState(() {
        totalDistance = distanceInKm;
      });
    } catch (e) {
      print('Error calculating total distance: $e');
    }
  }

  Future<bool> _hasUserPurchasedPackage() async {
    try {
      final packageIdRaw = widget.package?['id'];
      final packageId = packageIdRaw?.toString();
      if (packageId == null) return false;

      final userId = await _getCurrentUserId();
      if (userId == null) return false;

      final response = await dashboardApi.checkPaymentStatus(packageId, userId);
      if (response['success'] == true) {
        return response['data']?['hasPaid'] ?? false;
      }
      return false;
    } catch (e) {
      print('PackageDetails: Error checking payment status: $e');
      return false;
    }
  }

  Future<String?> _getCurrentUserId() async {
    try {
      return await StorageHelper.getUserId();
    } catch (e) {
      print('PackageDetails: Error getting current user ID: $e');
      return null;
    }
  }

  String _getStopImageUrl(Map<String, dynamic> stop) {
    print('Getting image URL for stop: ${stop.keys.toList()}');
    
    String? rawUrl;
    
    // First try to get image from media array
    if (stop['media'] != null && (stop['media'] as List).isNotEmpty) {
      final mediaList = stop['media'] as List;
      print('Found media array with ${mediaList.length} items');
      
      final imageMedia = mediaList.firstWhere(
        (media) => media['media_type'] == 'image',
        orElse: () => null,
      );
      
      if (imageMedia != null && imageMedia['url'] != null && imageMedia['url'].isNotEmpty) {
        rawUrl = imageMedia['url'];
        print('Found image in media array: $rawUrl');
      }
    }

    // Try different possible image field names if media array didn't work
    if (rawUrl == null) {
      final possibleFields = ['image_url', 'imageUrl', 'image', 'picture_url', 'pictureUrl', 'photo', 'thumbnail'];
      for (final field in possibleFields) {
        if (stop[field] != null && stop[field].toString().isNotEmpty) {
          rawUrl = stop[field].toString();
          print('Found image in field "$field": $rawUrl');
          break;
        }
      }
    }

    // Fallback to cover_image if available
    if (rawUrl == null && stop['cover_image'] != null) {
      if (stop['cover_image'] is String && stop['cover_image'].isNotEmpty) {
        rawUrl = stop['cover_image'];
        print('Found image in cover_image string: $rawUrl');
      } else if (stop['cover_image'] is Map && stop['cover_image']['url'] != null) {
        rawUrl = stop['cover_image']['url'];
        print('Found image in cover_image object: $rawUrl');
      }
    }

    // If we found a URL, construct the proper URL
    if (rawUrl != null && rawUrl.isNotEmpty) {
      final finalUrl = MediaService.getFullUrl(rawUrl);
      print('Final image URL: $finalUrl');
      print('DEBUG: Testing URL accessibility for: $finalUrl');
      return finalUrl;
    }

    // Only use fallback when no image URL is found at all
    print('No image found for stop, using fallback image');
    final fallbackImages = [
      'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400&h=250&fit=crop',
      'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=400&h=250&fit=crop',
      'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=400&h=250&fit=crop',
      'https://images.unsplash.com/photo-1472214103451-9374bd1c798e?w=400&h=250&fit=crop',
    ];
    
    final stopName = stop['stop_name'] ?? 'Stop';
    final imageIndex = stopName.hashCode.abs() % fallbackImages.length;
    return fallbackImages[imageIndex];
  }

  String _getAudioUrlForStop(Map<String, dynamic> stop) {
    if (stop['media'] != null && (stop['media'] as List).isNotEmpty) {
      final audioMedia = (stop['media'] as List).firstWhere(
        (media) => media['media_type'] == 'audio',
        orElse: () => null,
      );
      if (audioMedia != null) {
        final url = audioMedia['url'];
        if (url != null && url.isNotEmpty) {
          return MediaService.getFullUrl(url);
        }
      }
    }

    final audioUrl = stop['audio_url'];
    if (audioUrl != null && audioUrl.isNotEmpty) {
      return MediaService.getFullUrl(audioUrl);
    }

    final audioUrlAlt = stop['audioUrl'];
    if (audioUrlAlt != null && audioUrlAlt.isNotEmpty) {
      return MediaService.getFullUrl(audioUrlAlt);
    }

    return '';
  }

  void _showFullScreenImage(BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    },
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.white54,
                        size: 100,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _testDialog() {
    _showBuyTourDialog(context, widget.package);
  }

  void _showAllReviews() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All reviews page coming soon!')),
    );
  }

  void _testImageUrl(String url) async {
    try {
      print('Testing image URL: $url');
      // This will trigger the image loading and we can see errors in the console
    } catch (e) {
      print('Error testing image URL: $e');
    }
  }
}

// Shared Widgets
class _TopToBottomShade extends StatelessWidget {
  const _TopToBottomShade();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x990A1220),
            Color(0x00000000),
            Color(0xCC0A1220),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.14),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}

class _EllaDetailsSection extends StatelessWidget {
  final Map<String, dynamic>? package;
  final String Function(Map<String, dynamic>?) getPackageLocation;
  final double? distanceToFirstStop;
  final List<Map<String, dynamic>>? allStops;
  final double? totalDistance;
  final bool hasPurchased;

  const _EllaDetailsSection({
    this.package, 
    required this.getPackageLocation, 
    this.distanceToFirstStop, 
    this.allStops, 
    this.totalDistance, 
    required this.hasPurchased
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              package?['title']?.toString() ?? 'Package Title',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.star, color: Colors.amber, size: 14),
            const SizedBox(width: 4),
            Text(
              (package?['average_rating'] ?? 0.0).toStringAsFixed(1),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(width: 2),
            Text(
              '/5 (Reviews)',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 6),
            Text('•', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
            const SizedBox(width: 6),
            const Icon(Icons.map, size: 12, color: Colors.white70),
            const SizedBox(width: 4),
            Text(
              totalDistance != null ? '${totalDistance!.toStringAsFixed(1)} km' : 'Calculating...',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: distanceToFirstStop != null
                        ? distanceToFirstStop == -1
                            ? 'Location access denied '
                            : distanceToFirstStop == -2
                                ? 'Location services disabled '
                                : '${distanceToFirstStop!.toStringAsFixed(1)} km '
                        : 'Calculating distance... ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: 'away from you',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _onShowDirectionsToFirstStop(context),
              child: Row(
                children: [
                  Icon(Icons.subdirectory_arrow_right, color: Colors.blue, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Show directions',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            OutlinedButton(
              onPressed: () {
                final firstStop = allStops?.isNotEmpty == true ? allStops![0] : null;
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyTripScreen(
                    stop: firstStop,
                    allStops: allStops,
                    package: package,
                    isPreviewMode: !hasPurchased,
                    isPaidPackage: hasPurchased,
                  )),
                );
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.blue, width: 1),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.headset, color: Colors.blue, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    hasPurchased ? 'View Tour' : 'Preview First Stop',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        RichText(
          text: TextSpan(
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
              height: 1.4,
            ),
            children: [
              TextSpan(text: package?['description'] ?? 'No description available.'),
              TextSpan(
                text: 'Read more...',
                style: TextStyle(
                  color: const Color.fromARGB(255, 212, 216, 224),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _InfoColumn(
              icon: Icons.location_on_outlined,
              title: 'Location',
              subtitle: getPackageLocation(package),
            ),
            _InfoColumn(
              icon: Icons.person_outline,
              title: 'Tour Guide',
              subtitle: package?['guide']?['user']?['name']?.toString() ?? 'Guide Name',
            ),
            _InfoColumn(
              icon: Icons.attach_money,
              title: 'Price',
              subtitle: '${((package?['price'] ?? 0) as num).toStringAsFixed(0)} LKR',
            ),
          ],
        ),
      ],
    );
  }

  void _onShowDirectionsToFirstStop(BuildContext context) {
    if (package != null && package!['tour_stops'] != null && package!['tour_stops'] is List && package!['tour_stops'].isNotEmpty) {
      final firstStop = package!['tour_stops'][0];
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MyTripScreen(stop: firstStop),
        ),
      );
    }
  }
}

class _InfoColumn extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoColumn({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Color.fromARGB(179, 183, 181, 181),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AudioCard extends StatelessWidget {
  final String title;
  final String description;
  final String image;
  final int index;
  final VoidCallback onPlayAudio;
  final VoidCallback? onShowDirections;
  final bool isCurrentlyPlaying;
  final bool isPreviewLimited;
  final bool showPreviewBadge;

  const _AudioCard({
    required this.title,
    required this.description,
    required this.image,
    required this.index,
    required this.onPlayAudio,
    this.onShowDirections,
    required this.isCurrentlyPlaying,
    this.isPreviewLimited = false,
    this.showPreviewBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 5, 11, 26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (showPreviewBadge)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withOpacity(0.5)),
                        ),
                        child: const Text(
                          'PREVIEW',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _ActionButton(
                      icon: isCurrentlyPlaying ? Icons.pause : Icons.play_arrow,
                      label: 'Play audio',
                      onTap: onPlayAudio,
                      isDisabled: isPreviewLimited,
                    ),
                    const SizedBox(width: 16),
                    _ActionButton(
                      icon: Icons.directions,
                      label: 'Show directions',
                      onTap: onShowDirections ?? () {},
                      isDisabled: isPreviewLimited,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: Color.fromARGB(179, 233, 221, 221),
                      fontSize: 13,
                      height: 1.3,
                    ),
                    children: [
                      TextSpan(text: description),
                      const TextSpan(text: ' '),
                      TextSpan(
                        text: 'Read more...',
                        style: TextStyle(
                          color: const Color.fromARGB(179, 248, 249, 250),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              image,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 60,
                  height: 60,
                  color: Colors.white10,
                  child: const Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                print('AudioCard image error for URL "$image": $error');
                print('Attempting fallback image for audio card');
                
                // Try fallback scenic image
                final fallbackImages = [
                  'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=120&h=120&fit=crop',
                  'https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=120&h=120&fit=crop',
                  'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=120&h=120&fit=crop',
                  'https://images.unsplash.com/photo-1472214103451-9374bd1c798e?w=120&h=120&fit=crop',
                ];
                
                final fallbackIndex = image.hashCode.abs() % fallbackImages.length;
                
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    fallbackImages[fallbackIndex],
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Final fallback to icon
                      return Container(
                        width: 60, 
                        height: 60, 
                        color: Colors.grey.shade700,
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.white54,
                            size: 20,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDisabled;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isDisabled ? null : onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isDisabled ? Colors.grey : Colors.blue, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isDisabled ? Colors.grey : const Color.fromARGB(255, 193, 198, 202),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GalleryThumb extends StatelessWidget {
  final String url;

  const _GalleryThumb({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.white10,
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              print('Error loading gallery thumb: $error for URL: $url');
              return Container(
                color: Colors.grey.shade700,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_not_supported,
                        color: Colors.white54,
                        size: 20,
                      ),
                      SizedBox(height: 2),
                      Text(
                        'No Image',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// Reviews Section
class _ReviewsSection extends StatefulWidget {
  final int? packageId;
  final double averageRating;

  const _ReviewsSection({this.packageId, required this.averageRating});

  @override
  State<_ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<_ReviewsSection> {
  List<Map<String, dynamic>> reviews = [];
  bool isLoading = true;
  String? error;
  late TravellerApi travellerApi;

  @override
  void initState() {
    super.initState();
    travellerApi = TravellerApi(apiClient: ApiClient(customBaseUrl: EnvConfig.baseUrl));
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    if (widget.packageId == null) {
      setState(() {
        isLoading = false;
        error = 'Package ID not available';
      });
      return;
    }

    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final response = await travellerApi.getReviewsByPackage(widget.packageId!, limit: 3);
      
      if (response['success'] == true && response['data'] != null) {
        setState(() {
          reviews = List<Map<String, dynamic>>.from(response['data']);
          isLoading = false;
        });
      } else {
        _loadSampleReviews();
      }
    } catch (e) {
      print('Error loading reviews from API: $e');
      _loadSampleReviews();
    }
  }

  void _loadSampleReviews() {
    final sampleReviews = [
      {
        'id': 1,
        'rating': 5,
        'comments': 'Amazing tour! The audio guide was very informative and the locations were breathtaking.',
        'date': '2024-01-15T10:30:00Z',
        'traveler': {
          'user': {
            'name': 'John Doe',
            'profile_picture_url': null,
          }
        }
      },
      {
        'id': 2,
        'rating': 4,
        'comments': 'Great experience overall. Would recommend to anyone visiting the area.',
        'date': '2024-01-10T14:20:00Z',
        'traveler': {
          'user': {
            'name': 'Sarah Smith',
            'profile_picture_url': null,
          }
        }
      },
      {
        'id': 3,
        'rating': 5,
        'comments': 'Perfect tour guide and beautiful spots. Worth every penny!',
        'date': '2024-01-08T09:15:00Z',
        'traveler': {
          'user': {
            'name': 'Mike Johnson',
            'profile_picture_url': null,
          }
        }
      },
    ];

    setState(() {
      reviews = sampleReviews;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          error!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (reviews.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'No reviews yet. Be the first to review this tour!',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(
                widget.averageRating.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${reviews.length} ${reviews.length == 1 ? 'review' : 'reviews'})',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...reviews.take(3).map((review) => _ReviewCard(review: review)).toList(),
        if (reviews.length > 3)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '+ ${reviews.length - 3} more reviews',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final rating = review['rating'] as int? ?? 0;
    final comments = review['comments'] as String? ?? '';
    final userName = review['traveler']?['user']?['name'] as String? ?? 'Anonymous';
    final dateStr = review['date'] as String? ?? '';
    
    String formattedDate = '';
    if (dateStr.isNotEmpty) {
      try {
        final date = DateTime.parse(dateStr);
        final now = DateTime.now();
        final difference = now.difference(date).inDays;
        
        if (difference == 0) {
          formattedDate = 'Today';
        } else if (difference == 1) {
          formattedDate = 'Yesterday';
        } else if (difference < 7) {
          formattedDate = '$difference days ago';
        } else if (difference < 30) {
          final weeks = (difference / 7).floor();
          formattedDate = '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
        } else {
          final months = (difference / 30).floor();
          formattedDate = '$months ${months == 1 ? 'month' : 'months'} ago';
        }
      } catch (e) {
        formattedDate = 'Recently';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 5, 11, 26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue.withOpacity(0.2),
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (formattedDate.isNotEmpty)
                      Text(
                        formattedDate,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          if (comments.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              comments,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Buy Tour Dialog
void _showBuyTourDialog(BuildContext parentContext, Map<String, dynamic>? package) {
  showDialog(
    context: parentContext,
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
                'Previews are limited to the first location. Buy the tour to get access to all locations.',        
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
                    Navigator.of(parentContext).push(
                      MaterialPageRoute(
                        builder: (context) => CheckoutScreen(package: package),
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