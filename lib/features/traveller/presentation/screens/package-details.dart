import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:just_audio/just_audio.dart';
import './package_checkout.dart';
import 'audioplayer.dart';
import 'gallery_page.dart';
import 'mytrip.dart'; // Added import for MyTripScreen
import '../../../../core/services/mapbox_service.dart';


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

  const DestinationDetailsPage({super.key, this.package});

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

  List<Map<String, dynamic>> get stopTitles {
    if (widget.package?['tour_stops'] != null) {
      return List<Map<String, dynamic>>.from(widget.package!['tour_stops']);
    }
    return [];
  }

  @override
  void initState() {
    super.initState();
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

  String get heroImage => widget.package?['cover_image']?['url'] ?? 'https://via.placeholder.com/400x250.png?text=No+Image';


  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    double currentPosition = 0.0; // current slider position in seconds
    double totalDuration =
        225.0; // total audio duration in seconds (e.g., 3:45)
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                        heroImage,
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
                          return _EllaDetailsSection(package: widget.package, getPackageLocation: _getPackageLocation, distanceToFirstStop: distanceToFirstStop, allStops: stopTitles, totalDistance: totalDistance);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Gallery section
                    _SectionHeader(
                      title: 'Gallery',
                      actionLabel: 'See All',
                      onAction: () {
                        // Create gallery data with stop names and images
                        final galleryItems = stopTitles.map((stop) {
                          return {
                            'image': stop['media'] != null && (stop['media'] as List).isNotEmpty
                                ? (stop['media'] as List).firstWhere(
                                    (media) => media['media_type'] == 'image',
                                    orElse: () => {'media': {'url': 'https://via.placeholder.com/400x250.png?text=No+Image'}}
                                  )['media']['url']
                                : 'https://via.placeholder.com/400x250.png?text=No+Image',
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
                        itemCount: stopTitles.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final stop = stopTitles[index];
                          final imageUrl = stop['media'] != null && (stop['media'] as List).isNotEmpty
                              ? (stop['media'] as List).firstWhere(
                                  (media) => media['media_type'] == 'image',
                                  orElse: () => {'media': {'url': 'https://via.placeholder.com/400x250.png?text=No+Image'}}
                                )['media']['url']
                              : 'https://via.placeholder.com/400x250.png?text=No+Image';
                          return _GalleryThumb(url: imageUrl);
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
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _AudioCard(
                              title: stop['stop_name'] ?? 'Stop ${index + 1}',
                              description: stop['description'] ?? 'No description available.',
                              image: 'https://via.placeholder.com/400x250.png?text=Stop+${index + 1}',
                              index: index,
                              onPlayAudio: () => _onPlayAudio(index),
                              onShowDirections: () => _onShowDirections(index),
                              isCurrentlyPlaying:
                                  currentPlayingIndex == index && isPlaying,
                            ),
                          );
                        }),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),

          // Fixed bottom audio player overlay
          if (currentPlayingIndex != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ValueListenableBuilder<double>(
                valueListenable: currentPositionNotifier,
                builder: (context, positionValue, child) {
                  return ValueListenableBuilder<double>(
                    valueListenable: totalDurationNotifier,
                    builder: (context, durationValue, child) {
                      final currentStop = stopTitles[currentPlayingIndex!];

                      return BottomAudioPlayer(
                        title: currentStop['stop_name'] ?? 'Stop ${currentPlayingIndex! + 1}',
                        onPlayPause: () {
                          if (audioPlayer!.playing) {
                            // When pausing, stop and hide the player
                            setState(() {
                              isPlaying = false;
                              currentPositionNotifier.value = 0.0;
                              currentPlayingIndex = null;
                            });
                            audioPlayer?.stop();
                          } else {
                            audioPlayer?.play();
                          }
                        },
                        onStop: () {
                          setState(() {
                            isPlaying = false;
                            currentPositionNotifier.value = 0.0;
                            currentPlayingIndex = null;
                          });
                          audioPlayer?.stop();
                        },
                        onNext: () => _changeStop(currentPlayingIndex! + 1),
                        onPrevious: () => _changeStop(currentPlayingIndex! - 1),
                        onSeek: (position) {
                          audioPlayer?.seek(Duration(seconds: position.toInt()));
                        },
                        isPlaying: isPlaying,
                        currentPositionNotifier: currentPositionNotifier,
                        totalDuration: durationValue,
                        progressText: '${_formatTime(positionValue)} / ${_formatTime(durationValue)}',
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _onPlayAudio(int index) {
    // Since this package is already purchased (from my trips), allow all stops
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
          audioUrl = audioMedia['media']['url'] ?? 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav';
          // Try to get duration from database (stored in seconds)
          if (audioMedia['media']['duration_seconds'] != null) {
            dbDuration = (audioMedia['media']['duration_seconds'] as num).toDouble();
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
      setState(() {
        currentPlayingIndex = newIndex;
        isPlaying = true;
      });
      _loadCurrentAudio();
      audioPlayer?.play();
    }
  }

  void _onShowDirections(int index) {
    final stop = stopTitles[index];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MyTripScreen(stop: stop, allStops: stopTitles),
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
      if (firstStop['location'] != null && firstStop['location']['district'] != null) {
        return firstStop['location']['district'];
      }
    }
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
}

// When user drags the slider

/* ------------------------------ Gallery Page ------------------------------- */
void _showBuyTourDialog(BuildContext parentContext) {
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
                            CheckoutScreen(),
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

  const _EllaDetailsSection({this.package, required this.getPackageLocation, this.distanceToFirstStop, this.allStops, this.totalDistance});

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
              package?['title'] ?? 'Package Title',
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
                  MaterialPageRoute(builder: (context) => MyTripScreen(stop: firstStop, allStops: allStops)),
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
                    'View Tour',
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
                subtitle: package?['guide']?['user']?['name'] ?? 'Guide Name',
              ),
            ),
            Expanded(
              child: _InfoColumn(
                icon: Icons.attach_money,
                title: 'Price',
                subtitle: '\$${(package?['price'] ?? 0).toStringAsFixed(0)} USD',
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

  const _AudioCard({
    required this.title,
    required this.description,
    required this.image,
    required this.index,
    required this.onPlayAudio,
    this.onShowDirections,
    required this.isCurrentlyPlaying,
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
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                // Buttons row
                Row(
                  children: [
                    _ActionButton(
                      icon: isCurrentlyPlaying ? Icons.pause : Icons.play_arrow,
                      label: 'Play audio',
                      onTap: onPlayAudio,
                    ),
                    const SizedBox(width: 16),
                    _ActionButton(
                      icon: Icons.directions,
                      label: 'Show directions',
                      onTap: onShowDirections ?? () {},
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

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.blue, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: const Color.fromARGB(255, 193, 198, 202),
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


