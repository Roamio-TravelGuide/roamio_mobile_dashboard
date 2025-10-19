import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:just_audio/just_audio.dart';
import './package_checkout.dart';
import 'audioplayer.dart';
import 'gallery_page.dart';
import 'mytrip.dart'; // Added import for MyTripScreen
import '../../../../core/services/mapbox_service.dart';
import '../../../../core/services/media_service.dart';
import '../../../../core/widgets/audio_player_widget.dart';
import '../../api/dashboard_api.dart';
import '../../api/traveller_api.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/utils/storage_helper.dart';


void main() {
  runApp(const TravelApp());
}

class TravelApp extends StatelessWidget {
  const TravelApp({super.key});

  @override
  Widget build(BuildContext context) {
    //final seed = const Color.fromARGB(255, 7, 37, 94); // Dark blue seed color
    return MaterialApp(
      title: 'Travel Details',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: Colors.blue, // Exact color
          //background: Color(0xFF0A1220),
        ),
        scaffoldBackgroundColor: const Color(0xFF0D0D12),
        useMaterial3: true,
      ),
      home: DestinationDetailsPage(package: _getSamplePackage()),
    );
  }

  // Sample package data for testing
  static Map<String, dynamic> _getSamplePackage() {
    return {
      'id': 1,
      'title': 'Sample Tour Package',
      'description': 'A beautiful tour package for testing',
      'price': 150.0,
      'cover_image': {
        'url': 'https://via.placeholder.com/400x250.png?text=Sample+Image'
      },
      'tour_stops': [
        {
          'id': 1,
          'stop_name': 'Sample Stop 1',
          'description': 'First stop description',
          'audio_url': 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
          'location': {
            'latitude': 6.9271, // Colombo coordinates for testing
            'longitude': 79.8612,
            'district': 'Colombo'
          },
          'media': [
            {
              'media_type': 'image',
              'media': {
                'url': '/uploads/media/sample_image1.jpg'
              }
            },
            {
              'media_type': 'audio',
              'media': {
                'url': 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
                'duration_seconds': 180 // 3:00 minutes
              }
            }
          ]
        },
        {
          'id': 2,
          'stop_name': 'Sample Stop 2',
          'description': 'Second stop description',
          'audio_url': 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
          'location': {
            'latitude': 6.9171, // Near Colombo
            'longitude': 79.8712,
            'district': 'Colombo'
          },
          'media': [
            {
              'media_type': 'image',
              'media': {
                'url': '/uploads/media/sample_image2.jpg'
              }
            },
            {
              'media_type': 'audio',
              'media': {
                'url': 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
                'duration_seconds': 240 // 4:00 minutes
              }
            }
          ]
        },
        {
          'id': 3,
          'stop_name': 'Sample Stop 3',
          'description': 'Third stop description',
          'audio_url': 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
          'location': {
            'latitude': 6.9371, // Near Colombo
            'longitude': 79.8512,
            'district': 'Colombo'
          },
          'media': [
            {
              'media_type': 'image',
              'media': {
                'url': '/uploads/media/sample_image3.jpg'
              }
            },
            {
              'media_type': 'audio',
              'media': {
                'url': 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
                'duration_seconds': 300 // 5:00 minutes
              }
            }
          ]
        }
      ]
    };
  }
}

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
    ValueNotifier<double> currentPositionNotifier = ValueNotifier(0.0);
    ValueNotifier<double> totalDurationNotifier = ValueNotifier(225.0); // 3:45 in seconds
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
    print('PackageDetails: isFromMyTrips: ${widget.isFromMyTrips}');
    dashboardApi = DashboardApi(apiClient: ApiClient(customBaseUrl: EnvConfig.baseUrl));
    audioPlayer = AudioPlayer();
    // Listen to player state changes
    audioPlayer!.playerStateStream.listen((state) {
      setState(() {
        isPlaying = state.playing && state.processingState != ProcessingState.completed;
      });
      print('Audio player state: ${state.processingState}, playing: ${state.playing}');
    });

    // Listen to position changes for real-time progress
    audioPlayer!.positionStream.listen((position) {
      currentPositionNotifier.value = position.inSeconds.toDouble();
    });

    // Listen to duration changes - only update if we don't have database duration
    audioPlayer!.durationStream.listen((duration) {
      if (duration != null && totalDurationNotifier.value == 225.0) { // Only update if still default value
        totalDurationNotifier.value = duration.inSeconds.toDouble();
        print('Duration updated from audio file: ${totalDurationNotifier.value} seconds');
      }
    });
    _calculateDistanceToFirstStop();
    _calculateTotalDistance();
    _checkPurchaseStatus();
    // For testing: force unpaid status
    // _forceUnpaidForTesting();
  }

  Future<void> _checkPurchaseStatus() async {
    // If coming from My Trips, assume the package is already paid for
    if (widget.isFromMyTrips == true) {
      print('PackageDetails: Coming from My Trips - assuming package is paid for');
      setState(() {
        hasPurchased = true;
      });
      return;
    }

    try {
      final purchased = await _hasUserPurchasedPackage();
      print('PackageDetails: Payment status check result: $purchased for package ${widget.package?['id']}');
      print('PackageDetails: Setting hasPurchased to: $purchased');
      setState(() {
        hasPurchased = purchased;
      });
      print('PackageDetails: hasPurchased state is now: $hasPurchased');
    } catch (e) {
      print('PackageDetails: Error checking purchase status: $e');
      setState(() {
        hasPurchased = false;
      });
    }
  }

  // Force set hasPurchased to false for testing
  void _forceUnpaidForTesting() {
    setState(() {
      hasPurchased = false;
    });
    print('PackageDetails: Forced hasPurchased to false for testing');
  }

  void onSeek(double value) {
    currentPositionNotifier.value = value;
    // If using an actual audio player, seek to position:
    // audioPlayer.seek(Duration(seconds: value.toInt()));
  }

  @override
  void dispose() {
    currentPositionNotifier.dispose();
    totalDurationNotifier.dispose();
    audioPlayer?.dispose();
    super.dispose();
  }

  String get heroImage {
    final imageUrl = widget.package?['cover_image']?['url'] ?? 'https://via.placeholder.com/400x250.png?text=No+Image';
    print('PackageDetails: heroImage = $imageUrl');
    return imageUrl;
  }


  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    double currentPosition = 0.0; // current slider position in seconds
    double totalDuration =
        225.0; // total audio duration in seconds (e.g., 3:45)
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12), // Dark background like other screens
      extendBody: true, // let content go behind bottom nav
      body: Stack(
        children: [
          // Main scrollable content
          CustomScrollView(
            slivers: [
              // SliverAppBar with hero image
              SliverAppBar(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                pinned: true,
                expandedHeight: 280,
                elevation: 0,
                automaticallyImplyLeading: false,
                leadingWidth: 0,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        MediaService.getFullUrl(heroImage),
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        cacheWidth: 800,
                        cacheHeight: 600,
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
                              ),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) =>
                            Container(color: Colors.grey.shade700),
                      ),
                      const _TopToBottomShade(),
                      Positioned(
                        top:
                            MediaQuery.of(context).padding.top +
                            8, // below status bar
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
                      ),
                    ],
                  ),
                ),
              ),

              // Main content
              SliverPadding(
                padding: EdgeInsets.only(
                  top: 16,
                  bottom: currentPlayingIndex != null ? 160 : 16, // extra space for audio player
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Builder(
                        builder: (context) {
                          print('Building UI with distanceToFirstStop: $distanceToFirstStop');
                          print('PackageDetails: Building UI with hasPurchased: $hasPurchased');
                          print('PackageDetails: widget.package keys: ${widget.package?.keys.toList()}');
                          print('PackageDetails: package title: ${widget.package?['title']}');
                          print('PackageDetails: package price: ${widget.package?['price']}');
                          print('PackageDetails: package guide: ${widget.package?['guide']}');
                          return _EllaDetailsSection(package: widget.package, getPackageLocation: _getPackageLocation, distanceToFirstStop: distanceToFirstStop, allStops: stopTitles, totalDistance: totalDistance, hasPurchased: hasPurchased ?? false);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Gallery section
                    _SectionHeader(
                      title: 'Gallery',
                      actionLabel: 'See All',
                      onAction: () {
                        // Create gallery data with stop names and images - limit based on payment status
                        print('Gallery: Creating gallery items for ${stopTitles.length} stops, hasPurchased: $hasPurchased');
                        final availableStops = hasPurchased ?? false ? stopTitles : stopTitles.take(2).toList();
                        final galleryItems = availableStops.map((stop) {
                          print('Gallery: Processing stop for gallery: ${stop['stop_name']}');

                          String imageUrl = 'https://via.placeholder.com/400x250.png?text=No+Image';

                          // Check if this stop has media data
                          if (stop['media'] != null && (stop['media'] as List).isNotEmpty) {
                            print('Gallery: Stop has media for gallery: ${stop['media']}');
                            // Find image media
                            final imageMedia = (stop['media'] as List).firstWhere(
                              (media) => media['media_type'] == 'image',
                              orElse: () => null,
                            );
                            if (imageMedia != null) {
                              // The media is directly in the imageMedia object, not nested under 'media'
                              final url = imageMedia['url'];
                              print('Gallery: Found image URL for gallery: $url');
                              if (url != null && url.isNotEmpty) {
                                imageUrl = MediaService.getFullUrl(url);
                                print('Gallery: Full image URL for gallery: $imageUrl');
                              }
                            }
                          }

                          return {
                            'image': imageUrl,
                            'title': stop['stop_name'] ?? 'Stop'
                          };
                        }).toList();

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => GalleryPage(
                              title: 'Gallery',
                              galleryItems: galleryItems,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 86,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: (hasPurchased ?? false) ? stopTitles.length : stopTitles.take(2).toList().length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final stop = stopTitles[index];
                          print('Gallery: Processing stop ${index}: ${stop['stop_name']}');

                          // Check if this stop has media data
                          if (stop['media'] != null && (stop['media'] as List).isNotEmpty) {
                            print('Gallery: Stop has media: ${stop['media']}');
                            // Find image media
                            final imageMedia = (stop['media'] as List).firstWhere(
                              (media) => media['media_type'] == 'image',
                              orElse: () => null,
                            );
                            if (imageMedia != null) {
                              // The media is directly in the imageMedia object, not nested under 'media'
                              final url = imageMedia['url'];
                              print('Gallery: Found image URL: $url');
                              if (url != null && url.isNotEmpty) {
                                final fullUrl = MediaService.getFullUrl(url);
                                print('Gallery: Full image URL: $fullUrl');
                                return _GalleryThumb(url: fullUrl);
                              }
                            }
                          }

                          // Fallback to placeholder
                          print('Gallery: No image found, using placeholder');
                          return _GalleryThumb(url: 'https://via.placeholder.com/400x250.png?text=No+Image');
                        },
                      ),
                    ),
    
                    const SizedBox(height: 20),
    
                    // Trip to Ella section
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
                           // Limit to first 2 stops only for unpaid users
                           final isPreviewLimited = !(hasPurchased ?? false) && index > 1;
                           // Show preview badge for unpaid users on the first 2 stops
                           final showPreviewBadge = (hasPurchased == null || hasPurchased == false) && index <= 1;

                           return Padding(
                             padding: const EdgeInsets.only(bottom: 10),
                             child: _AudioCard(
                               title: stop['stop_name'] ?? 'Stop ${index + 1}',
                               description: stop['description'] ?? 'No description available.',
                               image: 'https://via.placeholder.com/400x250.png?text=Stop+${index + 1}',
                               index: index,
                               onPlayAudio: () => _onPlayAudio(index),
                               onShowDirections: () => _onShowDirections(index),
                               isCurrentlyPlaying: currentPlayingIndex == index && isPlaying,
                               isPreviewLimited: isPreviewLimited,
                               showPreviewBadge: showPreviewBadge,
                             ),
                           );
                         }),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Reviews section
                    _SectionHeader(
                      title: 'Reviews',
                      actionLabel: 'See All',
                      onAction: () {
                        // Navigate to all reviews page
                        _showAllReviews();
                      },
                    ),
                    const SizedBox(height: 12),
                    
                    // Reviews list
                    _ReviewsSection(
                      packageId: widget.package?['id'] is String
                          ? int.tryParse(widget.package!['id'])
                          : widget.package?['id'] as int?,
                      averageRating: widget.package?['average_rating'] ?? 0.0,
                    ),
                    
                    // Add extra space for bottom player
                    if (currentPlayingIndex != null) const SizedBox(height: 120),
                  ]),
                ),
              ),
            ],
          ),

          // Fixed bottom audio player overlay
          if (currentPlayingIndex != null) ...[
            () {
              final currentStop = stopTitles[currentPlayingIndex!];
              final mediaList = currentStop['media'] as List?;
              final audioMedia = mediaList?.firstWhere(
                (media) => media['media_type'] == 'audio',
                orElse: () => null,
              );

              // Always show the player overlay for the current playing stop
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
                        // Navigation buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Previous stop button
                            IconButton(
                              onPressed: currentPlayingIndex! > 0 ? () {
                                print('PackageDetails: Previous button pressed, changing to stop ${currentPlayingIndex! - 1}');
                                _changeStop(currentPlayingIndex! - 1);
                              } : null,
                              icon: const Icon(Icons.skip_previous, color: Colors.white, size: 28),
                              tooltip: 'Previous Stop',
                            ),
                            const SizedBox(width: 16),
                            // Current audio player
                                              Expanded(
                                                child: AudioPlayerWidget(
                                                  audioUrl: _getAudioUrlForStop(currentStop),
                                                  title: 'Play Audio for ${currentStop['stop_name'] ?? 'Current Stop'}',
                                                ),
                                              ),
                            const SizedBox(width: 16),
                            // Next stop button
                            IconButton(
                              onPressed: currentPlayingIndex! < stopTitles.length - 1 ? () {
                                print('PackageDetails: Next button pressed, changing to stop ${currentPlayingIndex! + 1}');
                                _onNextStop();
                              } : null,
                              icon: const Icon(Icons.skip_next, color: Colors.white, size: 28),
                              tooltip: 'Next Stop',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }(),
          ]
        ],
      ),
    );
  }

  void _onPlayAudio(int index) {
     print('PackageDetails: _onPlayAudio called with index: $index, hasPurchased: $hasPurchased, isFromMyTrips: ${widget.isFromMyTrips}');
     // Check if user has purchased this package using state
     if ((hasPurchased == null || hasPurchased == false) && index > 1) {
       print('PackageDetails: Showing preview dialog for unpaid user on stop index: $index');
       // Show preview dialog for stops beyond the first 2
       _showBuyTourDialog(context, widget.package);
       return;
     }

     print('PackageDetails: Allowing audio play for index: $index');
     // Allow playing for purchased packages or first 2 stops for preview
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
    print('PackageDetails: Next button pressed');
    if (currentPlayingIndex != null && currentPlayingIndex! < stopTitles.length - 1) {
      int nextIndex = currentPlayingIndex! + 1;
      print('PackageDetails: Attempting to go to next stop index: $nextIndex');
      _onPlayAudio(nextIndex);
    }
  }

  // Test function to show dialog
  void _testDialog() {
    print('PackageDetails: Testing dialog');
    _showBuyTourDialog(context, widget.package);
  }

  void _loadCurrentAudio() async {
    if (audioPlayer != null && currentPlayingIndex != null && stopTitles.isNotEmpty) {
      final stop = stopTitles[currentPlayingIndex!];
      String audioUrl;
      double? dbDuration;

      // Check if this is a real tour stop with media
      if (stop['media'] != null && (stop['media'] as List).isNotEmpty) {
        // Find audio media
        final audioMedia = (stop['media'] as List).firstWhere(
          (media) => media['media_type'] == 'audio',
          orElse: () => null,
        );
        if (audioMedia != null) {
          audioUrl = audioMedia['url'] ?? 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav';
          // Try to get duration from database (stored in seconds)
          if (audioMedia['duration_seconds'] != null) {
            dbDuration = (audioMedia['duration_seconds'] as num).toDouble();
          }
        } else {
          audioUrl = 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav';
        }
      } else {
        // Fallback for stops without media
        audioUrl = stop['audio_url'] ?? 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav';
      }

      try {
        print('Loading audio for stop: ${stop['stop_name']}');
        await audioPlayer!.setUrl(audioUrl);

        // Use database duration if available, otherwise rely on audio file duration
        if (dbDuration != null && dbDuration > 0) {
          totalDurationNotifier.value = dbDuration!;
          print('Using database duration: $dbDuration seconds');
        } else {
          print('Using audio file duration from stream');
        }

        // Duration will be updated via durationStream listener if not set from DB
        currentPositionNotifier.value = 0.0;
        print('Audio loaded successfully');
        if (isPlaying) {
          audioPlayer?.play();
        }
      } catch (e) {
        print('Error loading audio: $e');
        // Set fallback duration
        totalDurationNotifier.value = 225.0;
      }
    }
  }

  void _changeStop(int newIndex) {
    if (newIndex >= 0 && newIndex < stopTitles.length) {
      print('PackageDetails: Changing to stop index: $newIndex');
      setState(() {
        currentPlayingIndex = newIndex;
        isPlaying = true;
      });
      _loadCurrentAudio();
      audioPlayer?.play();
    }
  }

  void _onShowDirections(int index) {
     print('PackageDetails: Show directions clicked for stop index: $index, navigating to MyTripScreen with same functionality as View Tour');

     // Check if user has purchased this package using state
     if ((hasPurchased == null || hasPurchased == false) && index > 1) {
       print('PackageDetails: Showing preview dialog for unpaid user on directions for stop index: $index');
       // Show preview dialog for stops beyond the first 2
       _showBuyTourDialog(context, widget.package);
       return;
     }

     print('PackageDetails: Allowing directions navigation for index: $index');
     // Navigate to MyTripScreen with the same functionality as "View Tour" button
     // Pass the first stop and all stops to provide full tour functionality
     // Pass isPreviewMode: true for unpaid users to limit to first 2 stops
     final firstStop = stopTitles.isNotEmpty ? stopTitles[0] : null;
     final isPreviewMode = (hasPurchased == null || hasPurchased == false);
     Navigator.push(
       context,
       MaterialPageRoute(
         builder: (context) => MyTripScreen(
           stop: firstStop,
           allStops: stopTitles,
           package: widget.package,
           isPreviewMode: isPreviewMode,
           isPaidPackage: hasPurchased ?? false, // Explicitly pass payment status
         ),
       ),
     );
   }

  String _formatTime(double seconds) {
    final int mins = seconds ~/ 60;
    final int secs = seconds.toInt() % 60;
    return '${mins}:${secs.toString().padLeft(2, '0')}';
  }

  String _getPackageLocation(Map<String, dynamic>? package) {
    if (package != null && package['tour_stops'] != null && package['tour_stops'] is List && package['tour_stops'].isNotEmpty) {
      final firstStop = package['tour_stops'][0];
      if (firstStop['location'] != null && firstStop['location']['city'] != null) {
        final city = firstStop['location']['city'];
        print('PackageDetails: Found city from location table: $city');
        return city;
      }
    }
    // Fallback to package-level location if available
    if (package != null && package['location'] != null) {
      print('PackageDetails: Using package-level location: ${package['location']}');
      return package['location'].toString();
    }
    print('PackageDetails: No location found, returning default');
    return 'Location TBD';
  }

  Future<void> _calculateDistanceToFirstStop() async {
    try {
      // Step 1: Check if location services are enabled (ensure user allows access)
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          distanceToFirstStop = -2; // Special value to indicate services disabled
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

      // Step 2: Request location permissions from the user (browser will show a popup)
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            distanceToFirstStop = -1; // Special value to indicate permission denied
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          distanceToFirstStop = -1; // Special value to indicate permission denied
        });
        return;
      }

      // Step 3: Retrieve the current latitude and longitude using Geolocator
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final currentLocation = {'lat': position.latitude, 'lng': position.longitude};
      final stopLocation = {
        'lat': (firstStop['location']['latitude'] as num).toDouble(),
        'lng': (firstStop['location']['longitude'] as num).toDouble()
      };

      print('Current location: $currentLocation');
      print('Stop location: $stopLocation');

      // Calculate distance
      final distanceInMeters = _mapboxService.getDistanceBetweenPoints(
        Map<String, double>.from(currentLocation),
        Map<String, double>.from(stopLocation)
      );
      final distanceInKm = distanceInMeters / 1000;

      print('Calculated distance: ${distanceInKm} km');

      setState(() {
        distanceToFirstStop = distanceInKm;
      });

      print('UI should now show distance: $distanceInKm km');
    } catch (e) {
      print('Error calculating distance: $e');
      // Keep the default "Calculating distance..." message on error
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

      print('Calculated total distance: ${distanceInKm} km');
    } catch (e) {
      print('Error calculating total distance: $e');
    }
  }

  Future<bool> _hasUserPurchasedPackage() async {
    try {
      // Get the package ID and ensure it's a string
      final packageIdRaw = widget.package?['id'];
      final packageId = packageIdRaw?.toString();
      if (packageId == null) {
        print('PackageDetails: No package ID found');
        return false;
      }

      // Get user ID from storage (assuming we have a way to get current user)
      final userId = await _getCurrentUserId();
      if (userId == null) {
        print('PackageDetails: No user ID found');
        return false;
      }

      print('PackageDetails: Checking payment status for package ID: $packageId, user ID: $userId');

      // Check payment status via API
      final response = await dashboardApi.checkPaymentStatus(packageId, userId);
      print('PackageDetails: Payment status API response: $response');

      if (response['success'] == true) {
        final hasPaid = response['data']?['hasPaid'] ?? false;
        print('PackageDetails: hasPaid value from API: $hasPaid');
        return hasPaid;
      }
      print('PackageDetails: API response not successful');
      return false;
    } catch (e) {
      print('PackageDetails: Error checking payment status: $e');
      return false; // Default to preview mode on error
    }
  }

  Future<String?> _getCurrentUserId() async {
    try {
      // Get user ID from secure storage
      return await StorageHelper.getUserId();
    } catch (e) {
      print('PackageDetails: Error getting current user ID: $e');
      return null;
    }
  }

  String _getAudioUrlForStop(Map<String, dynamic> stop) {
    print('PackageDetails: Getting audio URL for stop: ${stop['stop_name']}');
    print('PackageDetails: Full stop data keys: ${stop.keys.toList()}');

    // Debug: Print all fields that might contain audio
    print('PackageDetails: audio_url field: ${stop['audio_url']}');
    print('PackageDetails: audioUrl field: ${stop['audioUrl']}');
    print('PackageDetails: media field: ${stop['media']}');

    // Check if this stop has media data
    if (stop['media'] != null && (stop['media'] as List).isNotEmpty) {
      print('PackageDetails: Stop has media data: ${stop['media']}');
      // Find audio media
      final audioMedia = (stop['media'] as List).firstWhere(
        (media) => media['media_type'] == 'audio',
        orElse: () => null,
      );
      if (audioMedia != null) {
        print('PackageDetails: Found audio media object: $audioMedia');
        // The media is directly in the audioMedia object, not nested under 'media'
        final url = audioMedia['url'];
        print('PackageDetails: Found audio media URL: $url');
        if (url != null && url.isNotEmpty) {
          final fullUrl = MediaService.getFullUrl(url);
          print('PackageDetails: Full audio URL: $fullUrl');
          return fullUrl;
        }
      }
    }

    // Fallback to audio_url field
    final audioUrl = stop['audio_url'];
    print('PackageDetails: Checking audio_url: $audioUrl');
    if (audioUrl != null && audioUrl.isNotEmpty) {
      final fullUrl = MediaService.getFullUrl(audioUrl);
      print('PackageDetails: Full fallback URL from audio_url: $fullUrl');
      return fullUrl;
    }

    // Check for other possible audio fields
    final audioUrlAlt = stop['audioUrl'];
    print('PackageDetails: Checking audioUrl: $audioUrlAlt');
    if (audioUrlAlt != null && audioUrlAlt.isNotEmpty) {
      final fullUrl = MediaService.getFullUrl(audioUrlAlt);
      print('PackageDetails: Full alternative URL from audioUrl: $fullUrl');
      return fullUrl;
    }

    // Check if there's a direct URL in the stop data
    final directUrl = stop['url'];
    print('PackageDetails: Checking direct url field: $directUrl');
    if (directUrl != null && directUrl.isNotEmpty) {
      final fullUrl = MediaService.getFullUrl(directUrl);
      print('PackageDetails: Full URL from direct url field: $fullUrl');
      return fullUrl;
    }

    // Final fallback - don't use external URL, use empty string to indicate no audio
    print('PackageDetails: No audio URL found in any field, returning empty string');
    return '';
  }

  void _showAllReviews() {
    // Navigate to all reviews page - for now just show a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All reviews page coming soon!')),
    );
  }
}

// When user drags the slider

/* ------------------------------ Gallery Page ------------------------------- */
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
              Text(
                'Previews are limited to the first 2 locations. Buy the tour to get access to other locations.',
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
                    // Navigate using the parent screen context
                    Navigator.of(parentContext).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            CheckoutScreen(package: package),
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
                  child: Text(
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

/* ------------------------------ Shared Widgets ------------------------------- */

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
            Color(0x990A1220), // top dim
            Color(0x00000000), // center clear
            Color(0xCC0A1220), // bottom dark
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
          child: Icon(icon, size: 20),
        ),
      ),
    );
  }
}

// New Ella-style details section
class _EllaDetailsSection extends StatelessWidget {
  final Map<String, dynamic>? package;
  final String Function(Map<String, dynamic>?) getPackageLocation;
  final double? distanceToFirstStop;
  final List<Map<String, dynamic>>? allStops;
  final double? totalDistance;
  final bool hasPurchased;

  const _EllaDetailsSection({this.package, required this.getPackageLocation, this.distanceToFirstStop, this.allStops, this.totalDistance, required this.hasPurchased});

  void _onShowDirectionsToFirstStop(BuildContext context) {
    if (package != null &&
        package!['tour_stops'] != null &&
        package!['tour_stops'] is List &&
        package!['tour_stops'].isNotEmpty) {
      final firstStop = package!['tour_stops'][0];
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MyTripScreen(stop: firstStop),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title + rating + distance
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
                color: Colors.white.withOpacity(0.8), // Darker than default white
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
            Text(
              '•',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
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
        // "Show map" row
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
                  Icon(
                    Icons.subdirectory_arrow_right,
                    color: Colors.blue,
                    size: 14,
                  ),
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
                // Pass the first stop to show directions to it when opening the tour
                final firstStop = allStops?.isNotEmpty == true ? allStops![0] : null;
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyTripScreen(
                    stop: firstStop,
                    allStops: allStops,
                    package: package,
                    isPreviewMode: !hasPurchased,
                    isPaidPackage: hasPurchased, // Explicitly pass payment status
                  )),
                );
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.blue, width: 1),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.headset, color: Colors.blue, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    hasPurchased ? 'View Tour' : 'Preview Tour',
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
        // Description
        RichText(
          text: TextSpan(
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
              height: 1.4,
            ),
            children: [
              TextSpan(
                text: package?['description'] ?? 'No description available.',
              ),
              TextSpan(
                text: 'Read more...',
                style: TextStyle(
                  color: Color.fromARGB(255, 212, 216, 224),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Info row
        Row(
          children: [
            Expanded(
              child: _InfoColumn(
                icon: Icons.location_on_outlined,
                title: 'Location',
                subtitle: getPackageLocation(package),
              ),
            ),
            Expanded(
              child: _InfoColumn(
                icon: Icons.person_outline,
                title: 'Tour Guide',
                subtitle: package?['guide']?['user']?['name']?.toString() ?? 'Guide Name',
              ),
            ),
            Expanded(
              child: _InfoColumn(
                icon: Icons.attach_money,
                title: 'Price',
                subtitle: '\$${((package?['price'] ?? 0) as num).toStringAsFixed(0)} USD',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoColumn extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoColumn({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}

// Audio card for the new trip section
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
    final cs = Theme.of(context).colorScheme;
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
                // Buttons row
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
                // Description with read more
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
              cacheWidth: 132,
              cacheHeight: 132,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 66,
                  height: 66,
                  color: Colors.white10,
                  child: const Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    ),
                  ),
                );
              },
              errorBuilder: (_, __, ___) =>
                  Container(width: 60, height: 60, color: Colors.grey.shade700),
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
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: isDisabled ? null : onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isDisabled ? Colors.grey : Colors.blue,
            size: 18
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isDisabled
                  ? Colors.grey
                  : const Color.fromARGB(255, 193, 198, 202),
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
    final text = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: Colors.white);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(title, style: text),
          const Spacer(),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
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
        child: Image.network(
          url,
          fit: BoxFit.cover,
          cacheWidth: 200,
          cacheHeight: 200,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.white10,
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade700),
        ),
      ),
    );
  }
}

class _RadioOption extends StatelessWidget {
  final String value;
  final String groupValue;
  final String title;
  final ValueChanged<String?> onChanged;

  const _RadioOption({
    required this.value,
    required this.groupValue,
    required this.title,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Row(
        children: [
          Radio<String>(
            value: value,
            groupValue: groupValue,
            onChanged: onChanged,
            activeColor: Colors.blue,
          ),
          Text(title, style: TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }
}

// Reviews Section Widget
class _ReviewsSection extends StatefulWidget {
  final int? packageId;
  final double averageRating;

  const _ReviewsSection({
    this.packageId,
    required this.averageRating,
  });

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

      // Try to load real reviews from API
      final response = await travellerApi.getReviewsByPackage(widget.packageId!, limit: 3);
      
      if (response['success'] == true && response['data'] != null) {
        setState(() {
          reviews = List<Map<String, dynamic>>.from(response['data']);
          isLoading = false;
        });
      } else {
        // Fallback to sample data if API fails
        _loadSampleReviews();
      }
    } catch (e) {
      print('Error loading reviews from API: $e');
      // Fallback to sample data
      _loadSampleReviews();
    }
  }

  void _loadSampleReviews() {
    // Sample reviews data as fallback
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
        child: Center(
          child: CircularProgressIndicator(),
        ),
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
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rating summary
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
        
        // Reviews list (show first 3)
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

// Individual Review Card Widget
class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final rating = review['rating'] as int? ?? 0;
    final comments = review['comments'] as String? ?? '';
    final userName = review['traveler']?['user']?['name'] as String? ?? 'Anonymous';
    final dateStr = review['date'] as String? ?? '';
    
    // Parse and format date
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
          // User info and rating
          Row(
            children: [
              // User avatar placeholder
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
              // Star rating
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


