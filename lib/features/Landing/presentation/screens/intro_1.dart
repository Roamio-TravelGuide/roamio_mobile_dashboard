import 'dart:ui';
import 'package:flutter/material.dart';
import 'intro_2.dart';

class Intro1Screen extends StatefulWidget {
  const Intro1Screen({super.key});

  @override
  State<Intro1Screen> createState() => _Intro1ScreenState();
}

class _Intro1ScreenState extends State<Intro1Screen> {
  int selectedTabIndex = 0;
  final List<String> tabs = ['Guided Tours', 'Local Insights'];
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F0F0F), Color(0xFF1C1C1C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Phone mockup
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 40,
                ),
                child: _buildPhoneMockup(),
              ),

              // Content section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Title
                      Text(
                        'Discover cities like a local',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 30,
                              height: 1.3,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Subtitle
                      Text(
                        'Join guided tours and uncover hidden gems with expert tips from locals who know the city best.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: const Color(0xFFAAAAAA),
                              fontSize: 16,
                              height: 1.6,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Page indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: index == 0 ? 20 : 8, // Active = first dot
                            height: 8,
                            decoration: BoxDecoration(
                              color: index == 0
                                  ? Colors.blueAccent
                                  : Colors.grey[700],
                              borderRadius: BorderRadius.circular(8),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 32),

                      // Next button
                      _buildNextButton(context),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Phone mockup
  Widget _buildPhoneMockup() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.75,
      height: MediaQuery.of(context).size.height * 0.55,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C2C2C), Color(0xFF1A1A1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildGuideProfile(),
                const SizedBox(height: 24),
                _buildTourSearch(),
                const SizedBox(height: 24),
                _buildTabs(),
                const SizedBox(height: 24),
                Expanded(child: _buildTourCarousel()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Guide Profile
  Widget _buildGuideProfile() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blue,
              child: const Icon(Icons.map, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Text(
              'Your Travel Guide',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const Icon(Icons.star_border, color: Colors.grey, size: 22),
      ],
    );
  }

  /// Tour Search
  Widget _buildTourSearch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Find your perfect tour',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              Icon(Icons.search, color: Colors.grey, size: 18),
              SizedBox(width: 12),
              Text(
                'Search guided tours',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Tabs
  Widget _buildTabs() {
    return Row(
      children: tabs.asMap().entries.map((entry) {
        int index = entry.key;
        String tab = entry.value;
        bool isActive = index == selectedTabIndex;

        return GestureDetector(
          onTap: () {
            setState(() {
              selectedTabIndex = index;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              gradient: isActive
                  ? const LinearGradient(
                      colors: [Color(0xFF007AFF), Color(0xFF00C6FF)],
                    )
                  : null,
              color: isActive ? null : Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Text(
              tab,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Carousel
  Widget _buildTourCarousel() {
    final List<Map<String, String>> tourData = [
      {
        'date': 'April 10, 2025',
        'title': 'Sunset Walking Tour',
        'location': 'Barcelona • 4.9 ★',
      },
      {
        'date': 'April 12, 2025',
        'title': 'Food & Culture Tour',
        'location': 'Madrid • 4.8 ★',
      },
      {
        'date': 'April 15, 2025',
        'title': 'Historic City Center',
        'location': 'Valencia • 4.7 ★',
      },
    ];

    return PageView.builder(
      controller: _pageController,
      itemCount: tourData.length,
      itemBuilder: (context, index) {
        final tour = tourData[index];
        return Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.tour, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tour['date']!,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tour['title']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tour['location']!,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Next Button
  Widget _buildNextButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(builder: (context) => const Intro2Screen()),
          // );
          // Navigator.pushNamed(context, '/intro2');
          
          // Option 2: Direct navigation (alternative)
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Intro2Screen()),
          );
          
          // Option 3: Replace current screen (for onboarding flow)
          // Navigator.pushReplacementNamed(context, '/intro2');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 6,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Next',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}