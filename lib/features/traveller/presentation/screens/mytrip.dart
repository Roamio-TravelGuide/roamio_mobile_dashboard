import 'package:flutter/material.dart';
import 'restaurant_detail.dart';

class MyTripScreen extends StatefulWidget {
  @override
  _MyTripScreenState createState() => _MyTripScreenState();
}

class _MyTripScreenState extends State<MyTripScreen> {
  bool isPlaying = false;
  double audioProgress = 0.3; // 30% progress for demo
  double playbackSpeed = 1.0;

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
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

            // Map placeholder area
            Container(
              margin: const EdgeInsets.all(16),
              height: 300,
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
                    const SizedBox(height: 8),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Tanah Lot Temple (2/5)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: Color(0xFF2D1B69), // Purple background like in the image
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Speed control and time display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Speed control
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.speed, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${playbackSpeed}x',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Current time
                      Text(
                        '0:38',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      
                      // Remaining time
                      Text(
                        '-1:18',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Progress slider
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white.withOpacity(0.3),
                      thumbColor: Colors.white,
                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: audioProgress,
                      onChanged: (value) {
                        setState(() {
                          audioProgress = value;
                        });
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Control buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.skip_previous, color: Colors.white, size: 32),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 24),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isPlaying = !isPlaying;
                          });
                        },
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Color(0xFF2D1B69),
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      IconButton(
                        icon: Icon(Icons.skip_next, color: Colors.white, size: 32),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Cafes & Restaurants section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    color: Colors.grey.shade900,
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
            )).toList(),
            
            // Add some bottom padding
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNavigationBar(),
    );
  }
}

class _BottomNavigationBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(color: Colors.grey.shade800, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(Icons.home_outlined, 'Home', false),
          _NavItem(Icons.location_on, 'My Trip', true),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.add, color: Colors.white, size: 24),
          ),
          _NavItem(Icons.favorite_outline, 'Favorite', false),
          _NavItem(Icons.person_outline, 'Profile', false),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;

  const _NavItem(this.icon, this.label, this.isActive);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: isActive ? Colors.blue : Colors.grey.shade500,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.blue : Colors.grey.shade500,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
