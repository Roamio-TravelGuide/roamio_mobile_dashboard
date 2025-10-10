import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:just_audio/just_audio.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import '../../../../core/services/mapbox_service.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/config/env_config.dart';
import 'restaurant_detail.dart';
import 'audioplayer.dart';
import '../../api/traveller_api.dart';

class MyTripScreen extends StatefulWidget {
  final Map<String, dynamic>? stop;
  final List<Map<String, dynamic>>? allStops;
  const MyTripScreen({super.key, this.stop, this.allStops});
  @override
  _MyTripScreenState createState() => _MyTripScreenState();
}

class _MyTripScreenState extends State<MyTripScreen> {
  bool isPlaying = false;
  ValueNotifier<double> currentPositionNotifier = ValueNotifier(
    38.0,
  ); // initial position
  double totalDuration = 116.0; // 1:56
  AudioPlayer? audioPlayer;

  LatLng? currentLocation;
  LatLng? stopLocation;
  List<LatLng> routePoints = [];
  final MapboxService _mapboxService = MapboxService();
  LatLng? mapCenter;
  double? mapZoom;
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  List<Map<String, dynamic>> tourStops = [];
  int currentStopIndex = 0;

  // Dynamic restaurant/POI data
  List<Map<String, dynamic>> restaurants = [];
  bool isLoadingPois = false;

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
    // Listen to player state changes
    _playerStateSubscription = audioPlayer!.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          isPlaying = state.playing && state.processingState != ProcessingState.completed;
        });
      }
      print(
        'Audio player state: ${state.processingState}, playing: ${state.playing}',
      );
    });

    // Listen to position changes for real-time progress
    _positionSubscription = audioPlayer!.positionStream.listen((position) {
      currentPositionNotifier.value = position.inSeconds.toDouble();
    });

    // Listen to duration changes
    _durationSubscription = audioPlayer!.durationStream.listen((duration) {
      if (duration != null && mounted) {
        setState(() {
          totalDuration = duration.inSeconds.toDouble();
        });
        print('Duration updated: $totalDuration seconds');
      }
    });
    _loadCurrentAudio();

    // Initialize tour stops and current stop index
    if (widget.allStops != null && widget.allStops!.isNotEmpty) {
      tourStops = widget.allStops!;
      if (widget.stop != null) {
        // Find the index of the passed stop in the tour stops
        currentStopIndex = tourStops.indexWhere(
          (stop) => stop['id'] == widget.stop!['id'],
        );
        if (currentStopIndex == -1) {
          currentStopIndex = 0; // Fallback to first stop
        }
      }
    } else if (widget.stop != null) {
      // If only a single stop is passed, create a list with just that stop
      tourStops = [widget.stop!];
      currentStopIndex = 0;
    } else {
      // Use hardcoded stops as fallback
      tourStops = [
        {
          'title': 'Tanah Lot Temple',
          'audioUrl':
              'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
        },
        {
          'title': 'Next Stop',
          'audioUrl':
              'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
        },
        {
          'title': 'Another Stop',
          'audioUrl':
              'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
        },
      ];
      currentStopIndex = 0;
    }

    if (widget.stop != null) {
      print('Stop data received: ${widget.stop}');
      _loadDirectionsForStop(tourStops[currentStopIndex]);
    }

    // Load nearby POIs
    _loadNearbyPois();
  }

  void _loadNearbyPois() async {
    // Use default location if currentLocation is null
    final lat = currentLocation?.latitude ?? 6.9271; // Default to Colombo
    final lng = currentLocation?.longitude ?? 79.8612;

    setState(() {
      isLoadingPois = true;
    });

    try {
      final apiClient = ApiClient(customBaseUrl: EnvConfig.baseUrl);
      final travellerApi = TravellerApi(apiClient: apiClient);
      final result = await travellerApi.getNearbyPois(
        lat,
        lng,
        radius: 500,
        category: 'restaurant', // Focus on restaurants/cafes
      );

      if (result['success'] == true && result['data'] != null) {
        final pois = result['data'] as List;
        setState(() {
          restaurants = pois
              .map(
                (poi) => {
                  'name': poi['name'] ?? 'Unknown POI',
                  'description':
                      poi['description'] ?? 'No description available',
                  'image':
                      'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=300&h=200&fit=crop', // Default image
                  'rating':
                      4.5, // Default rating since we don't have this in POI schema
                  'distance': null, // No distance since not calculated
                },
              )
              .toList();
        });
        print('Loaded ${restaurants.length} POIs from database');
      } else {
        print('Failed to load POIs: ${result['message']}');
        // Do not load sample data, show empty list to indicate database data should be shown
        setState(() {
          restaurants = [];
        });
      }
    } catch (e) {
      print('Error loading nearby POIs: $e');
      // Do not load sample data
      setState(() {
        restaurants = [];
      });
    } finally {
      setState(() {
        isLoadingPois = false;
      });
    }
  }

  void _loadSampleRestaurants() {
    setState(() {
      restaurants = [
        {
          'name': 'Sun set Cafe',
          'description': 'Cozy cafe with sunset views and amazing coffee',
          'image':
              'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=300&h=200&fit=crop',
          'rating': 4.6,
        },
        {
          'name': 'Ocean View Restaurant',
          'description': 'Fresh seafood with panoramic ocean views',
          'image':
              'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=300&h=200&fit=crop',
          'rating': 4.8,
        },
        {
          'name': 'Mountain Breeze Cafe',
          'description': 'Traditional cuisine in a serene mountain setting',
          'image':
              'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop',
          'rating': 4.5,
        },
        {
          'name': 'Garden Bistro',
          'description':
              'Farm-to-table dining experience with organic ingredients',
          'image':
              'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=300&h=200&fit=crop',
          'rating': 4.7,
        },
      ];
    });
  }

  void _loadCurrentAudio() async {
    if (audioPlayer != null &&
        tourStops.isNotEmpty &&
        currentStopIndex < tourStops.length) {
      try {
        final currentStop = tourStops[currentStopIndex];
        String audioUrl;
        String stopName;
        double? dbDuration;

        // Check if this is a real tour stop with media
        if (currentStop['media'] != null &&
            (currentStop['media'] as List).isNotEmpty) {
          // Find audio media
          final audioMedia = (currentStop['media'] as List).firstWhere(
            (media) => media['media_type'] == 'audio',
            orElse: () => null,
          );
          if (audioMedia != null) {
            audioUrl =
                audioMedia['media']['url'] ??
                'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav';
            // Try to get duration from database (stored in seconds)
            if (audioMedia['media']['duration_seconds'] != null) {
              dbDuration = (audioMedia['media']['duration_seconds'] as num)
                  .toDouble();
            }
          } else {
            audioUrl =
                'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav';
          }
        } else {
          // Fallback for stops without media
          audioUrl =
              currentStop['audioUrl'] ??
              'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav';
        }

        stopName =
            currentStop['stop_name'] ??
            currentStop['title'] ??
            'Stop ${currentStopIndex + 1}';

        print('Loading audio for stop: $stopName');
        await audioPlayer!.setUrl(audioUrl);

        // Use database duration if available, otherwise rely on audio file duration
        if (dbDuration != null && dbDuration > 0) {
          if (mounted) {
            setState(() {
              totalDuration = dbDuration!;
            });
          }
          print('Using database duration: $dbDuration seconds');
        } else {
          print('Using audio file duration from stream');
        }

        // Duration will be updated via durationStream listener if not set from DB
        currentPositionNotifier.value = 0.0;
        print('Audio loaded successfully');
      } catch (e) {
        print('Error loading audio: $e');
        // Set fallback duration
        if (mounted) {
          setState(() {
            totalDuration = 116.0;
          });
        }
      }
    }
  }

  void _loadDirectionsForStop(Map<String, dynamic> stop) async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print(
          'Location services are disabled. Please enable location services.',
        );
        // You could show a dialog here asking user to enable location services
        return;
      }

      // Check and request location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permissions permanently denied');
        return;
      }

      // Get current location with timeout for web compatibility
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10), // Add timeout for web
      );

      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
      });

      print(
        'Current location obtained: ${position.latitude}, ${position.longitude}',
      );

      // Use location data from stop.location (from Prisma Location table)
      print('Stop location data: ${stop['location']}');
      if (stop['location'] != null &&
          stop['location']['latitude'] != null &&
          stop['location']['longitude'] != null) {
        print(
          'Setting stop location: lat=${stop['location']['latitude']}, lng=${stop['location']['longitude']}',
        );
        setState(() {
          stopLocation = LatLng(
            stop['location']['latitude'],
            stop['location']['longitude'],
          );
        });

        // Get directions
        final directions = await _mapboxService.getDirections(
          {'lat': currentLocation!.latitude, 'lng': currentLocation!.longitude},
          {'lat': stopLocation!.latitude, 'lng': stopLocation!.longitude},
          [],
        );

        if (directions != null) {
          print(
            'Directions loaded successfully. Path points: ${directions['path'].length}',
          );
          setState(() {
            routePoints = (directions['path'] as List)
                .map((point) => LatLng(point['lat'], point['lng']))
                .toList();
            // Center map on the midpoint between current location and stop location
            mapCenter = LatLng(
              (currentLocation!.latitude + stopLocation!.latitude) / 2,
              (currentLocation!.longitude + stopLocation!.longitude) / 2,
            );
            // Calculate appropriate zoom level to fit both points
            mapZoom = _calculateZoomLevel(currentLocation!, stopLocation!);
          });
        } else {
          print('No directions received from Mapbox API');
          // If no directions, center on stop location with default zoom
          setState(() {
            mapCenter = stopLocation;
            mapZoom = 12.0;
          });
        }
      } else {
        print('Location data not available in stop');
      }
    } catch (e) {
      print('Error loading directions: $e');
      // For web, you might want to show a user-friendly message
      if (e.toString().contains('permission') ||
          e.toString().contains('denied')) {
        print(
          'Location permission issue. Please allow location access in your browser.',
        );
      }
      // Fallback: center on current location if available
      if (currentLocation != null) {
        setState(() {
          mapCenter = currentLocation;
        });
      }
    }
  }

  void _changeStop(int newIndex) {
    if (newIndex >= 0 && newIndex < tourStops.length) {
      setState(() {
        currentStopIndex = newIndex;
        isPlaying = true;
      });
      _loadCurrentAudio();
      audioPlayer?.play();
      // Reload directions for the new stop
      _loadDirectionsForStop(tourStops[newIndex]);
    }
  }

  void _onSpeedChange(double speed) {
    audioPlayer?.setSpeed(speed);
  }

  void _onReplay() {
    final currentPosition = currentPositionNotifier.value;
    final newPosition = (currentPosition - 10).clamp(0.0, totalDuration);
    audioPlayer?.seek(Duration(seconds: newPosition.toInt()));
  }

  void _onForward() {
    final currentPosition = currentPositionNotifier.value;
    final newPosition = (currentPosition + 10).clamp(0.0, totalDuration);
    audioPlayer?.seek(Duration(seconds: newPosition.toInt()));
  }

  /// Calculate zoom level to fit both points on the map
  double _calculateZoomLevel(LatLng point1, LatLng point2) {
    const double maxZoom = 18.0;
    const double minZoom = 3.0;

    // Calculate distance between points using Haversine formula
    const double R = 6371000; // Earth's radius in meters
    final double dLat = (point2.latitude - point1.latitude) * math.pi / 180;
    final double dLng = (point2.longitude - point1.longitude) * math.pi / 180;
    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(point1.latitude * math.pi / 180) *
            math.cos(point2.latitude * math.pi / 180) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final double distance = R * c; // Distance in meters

    // Calculate zoom level based on distance
    // This is an approximation - adjust the formula as needed
    double zoom = maxZoom - (distance / 1000) * 0.5; // Rough approximation
    zoom = zoom.clamp(minZoom, maxZoom);

    print('Calculated zoom level: $zoom for distance: ${distance / 1000} km');
    return zoom;
  }

  String _formatTime(double seconds) {
    final int mins = seconds ~/ 60;
    final int secs = seconds.toInt() % 60;
    return '${mins}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int seconds) {
    final int mins = seconds ~/ 60;
    final int secs = seconds % 60;
    return '${mins}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    currentPositionNotifier.dispose();
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    audioPlayer?.dispose();
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
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
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
            icon: Icon(Icons.calendar_today_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Destination name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                tourStops.isNotEmpty && currentStopIndex < tourStops.length
                    ? (tourStops[currentStopIndex]['stop_name'] ??
                          tourStops[currentStopIndex]['title'] ??
                          'Stop')
                    : 'My Trip',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Map integration
            Container(
              margin: const EdgeInsets.all(16),
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade700),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: (kIsWeb || (!Platform.isAndroid && !Platform.isIOS))
                    ? FlutterMap(
                        options: MapOptions(
                          center:
                              mapCenter ??
                              currentLocation ??
                              LatLng(6.8667, 81.0466),
                          zoom: mapZoom ?? 12.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.app',
                          ),
                          if (routePoints.isNotEmpty)
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: routePoints,
                                  strokeWidth: 4.0,
                                  color: Colors.blue,
                                ),
                              ],
                            ),
                          MarkerLayer(
                            markers: [
                              if (currentLocation != null)
                                Marker(
                                  point: currentLocation!,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.my_location,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'You are here',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              if (stopLocation != null)
                                Marker(
                                  point: stopLocation!,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          tourStops[currentStopIndex]['stop_name'] ??
                                              tourStops[currentStopIndex]['title'] ??
                                              'Destination',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      )
                    : mapbox.MapWidget(
                        styleUri: 'mapbox://styles/mapbox/streets-v11',
                        cameraOptions: mapbox.CameraOptions(
                          center: mapbox.Point(
                            coordinates: mapbox.Position(81.0466, 6.8667),
                          ),
                          zoom: 12.0,
                        ),
                      ),
              ),
            ),

            // Bottom Audio Player
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: ValueListenableBuilder<double>(
                valueListenable: currentPositionNotifier,
                builder: (context, value, child) {
                  String stopTitle;
                  String? durationText;
                  if (tourStops.isNotEmpty &&
                      currentStopIndex < tourStops.length) {
                    final currentStop = tourStops[currentStopIndex];
                    stopTitle =
                        currentStop['stop_name'] ??
                        currentStop['title'] ??
                        'Stop ${currentStopIndex + 1}';

                    // Get duration from media table and format as minutes:seconds
                    try {
                      if (currentStop['media'] != null &&
                          currentStop['media'] is List &&
                          (currentStop['media'] as List).isNotEmpty) {
                        final mediaList = currentStop['media'] as List;
                        final audioMedia = mediaList.firstWhere(
                          (media) =>
                              media != null &&
                              media is Map &&
                              media['media_type'] == 'audio',
                          orElse: () => null,
                        );
                        if (audioMedia != null &&
                            audioMedia is Map &&
                            audioMedia['media'] != null &&
                            audioMedia['media'] is Map &&
                            audioMedia['media']['duration_seconds'] != null) {
                          final durationSeconds =
                              (audioMedia['media']['duration_seconds'] as num)
                                  .toInt();
                          durationText = _formatDuration(durationSeconds);
                        }
                      }
                    } catch (e) {
                      print('Error extracting duration: $e');
                      // Keep durationText as null
                    }
                  } else {
                    stopTitle = 'Stop';
                  }
                  return BottomAudioPlayer(
                    title: stopTitle,
                    onPlayPause: () {
                      if (audioPlayer!.playing) {
                        audioPlayer?.pause();
                      } else {
                        audioPlayer?.play();
                      }
                    },
                    onStop: () {
                      setState(() {
                        isPlaying = false;
                        currentPositionNotifier.value = 0.0;
                      });
                      audioPlayer?.stop();
                    },
                    onNext: () => _changeStop(currentStopIndex + 1),
                    onPrevious: () => _changeStop(currentStopIndex - 1),
                    onSeek: (position) {
                      audioPlayer?.seek(Duration(seconds: position.toInt()));
                    },
                    onSpeedChange: _onSpeedChange,
                    onReplay: _onReplay,
                    onForward: _onForward,
                    isPlaying: isPlaying,
                    currentPositionNotifier: currentPositionNotifier,
                    totalDuration: totalDuration,
                    progressText: tourStops.isNotEmpty
                        ? '${currentStopIndex + 1}/${tourStops.length}'
                        : '1/1',
                    durationText: durationText,
                  );
                },
              ),
            ),

            // Cafes & Restaurants section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                'Cafes & Restaurants Near By',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),

            ...restaurants.map(
              (restaurant) => Container(
                margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                child: GestureDetector(
                  onTap: () {
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
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 5, 11, 26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 60,
                            height: 60,
                            child: Image.network(
                              restaurant['image'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.blue.shade300,
                                  child: Icon(
                                    Icons.restaurant,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                restaurant['name'],
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                restaurant['description'],
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.grey.shade500,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // The parent travel app already has its own bottom navigation
    );
  }
}
