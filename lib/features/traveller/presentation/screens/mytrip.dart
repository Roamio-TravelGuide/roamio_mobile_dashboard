import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'restaurant_detail.dart';
import 'audioplayer.dart';

class MyTripScreen extends StatefulWidget {
    const MyTripScreen({super.key});
  @override
  _MyTripScreenState createState() => _MyTripScreenState();
}

class _MyTripScreenState extends State<MyTripScreen> {
  bool isPlaying = false;
  ValueNotifier<double> currentPositionNotifier = ValueNotifier(38.0); // initial position
  double totalDuration = 116.0; // 1:56
  AudioPlayer? audioPlayer;
  int currentStopIndex = 0;

  // List of stops with audio URLs
  final List<Map<String, dynamic>> stops = [
    {
      'title': 'Tanah Lot Temple',
      'audioUrl': 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav', // placeholder
    },
    {
      'title': 'Next Stop',
      'audioUrl': 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav', // placeholder
    },
    {
      'title': 'Another Stop',
      'audioUrl': 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav', // placeholder
    },
  ];

  // Sample restaurant data
  final List<Map<String, dynamic>> restaurants = [
    {
      'name': 'Sun set Cafe',
      'description': 'Cozy cafe with sunset views and amazing coffee',
      'image': 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?w=300&h=200&fit=crop',
      'rating': 4.6,
    },
    {
      'name': 'Ocean View Restaurant',
      'description': 'Fresh seafood with panoramic ocean views',
      'image': 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=300&h=200&fit=crop',
      'rating': 4.8,
    },
    {
      'name': 'Mountain Breeze Cafe',
      'description': 'Traditional cuisine in a serene mountain setting',
      'image': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=300&h=200&fit=crop',
      'rating': 4.5,
    },
    {
      'name': 'Garden Bistro',
      'description': 'Farm-to-table dining experience with organic ingredients',
      'image': 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=300&h=200&fit=crop',
      'rating': 4.7,
    },
  ];

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
    // Listen to player state changes
    audioPlayer!.playerStateStream.listen((state) {
      setState(() {
        isPlaying = state.playing;
      });
      print('Audio player state: ${state.processingState}, playing: ${state.playing}');
    });

    // Listen to position changes for real-time progress
    audioPlayer!.positionStream.listen((position) {
      currentPositionNotifier.value = position.inSeconds.toDouble();
    });

    // Listen to duration changes
    audioPlayer!.durationStream.listen((duration) {
      if (duration != null) {
        setState(() {
          totalDuration = duration.inSeconds.toDouble();
        });
        print('Duration updated: $totalDuration seconds');
      }
    });
    _loadCurrentAudio();
  }

  void _loadCurrentAudio() async {
    if (audioPlayer != null && stops.isNotEmpty) {
      try {
        print('Loading audio for stop: ${stops[currentStopIndex]['title']}');
        await audioPlayer!.setUrl(stops[currentStopIndex]['audioUrl']);
        // Duration will be updated via durationStream listener
        currentPositionNotifier.value = 0.0;
        print('Audio loaded successfully');
      } catch (e) {
        print('Error loading audio: $e');
        // Set fallback duration
        setState(() {
          totalDuration = 116.0;
        });
      }
    }
  }

  void _changeStop(int newIndex) {
    if (newIndex >= 0 && newIndex < stops.length) {
      setState(() {
        currentStopIndex = newIndex;
        isPlaying = true;
      });
      _loadCurrentAudio();
      audioPlayer?.play();
    }
  }

  String _formatTime(double seconds) {
    final int mins = seconds ~/ 60;
    final int secs = seconds.toInt() % 60;
    return '${mins}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    currentPositionNotifier.dispose();
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
        padding: const EdgeInsets.only(bottom: 120), // increased from 100 to 120
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Destination name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Ella',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Map placeholder
            Container(
              margin: const EdgeInsets.all(16),
              height: 370,
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade700),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      color: Colors.grey.shade500,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Map will be integrated here',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Current location info
            

            const SizedBox(height: 16),

            // Bottom Audio Player
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: ValueListenableBuilder<double>(
                valueListenable: currentPositionNotifier,
                builder: (context, value, child) {
                  return BottomAudioPlayer(
                    title: stops[currentStopIndex]['title'],
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
                    isPlaying: isPlaying,
                    currentPositionNotifier: currentPositionNotifier,
                    totalDuration: totalDuration,
                    progressText: '${_formatTime(currentPositionNotifier.value)} / ${_formatTime(totalDuration)}',
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

            ...restaurants.map((restaurant) => Container(
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
                )),
          ],
        ),
      ),
      // The parent travel app already has its own bottom navigation
    );
  }
}
