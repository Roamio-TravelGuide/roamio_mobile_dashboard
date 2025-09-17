import 'dart:ui';
import 'package:flutter/material.dart';
import 'intro_3.dart';

class Intro2Screen extends StatefulWidget {
  const Intro2Screen({super.key});

  @override
  State<Intro2Screen> createState() => _Intro2ScreenState();
}

class _Intro2ScreenState extends State<Intro2Screen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  late AnimationController _floatingController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _floatingAnimation;
  
  int _currentPage = 0;

  final List<Map<String, String>> reviews = [
    {
      'name': 'Emily R.',
      'comment': 'Absolutely loved Bali! The beaches were amazing and the local food is to die for. Every moment was magical.',
      'date': 'Mar 18, 2025',
      'color': '0xFF4F46E5', // Indigo
    },
    {
      'name': 'Liam S.',
      'comment': 'I had a great time exploring the mountains in Switzerland. Highly recommended for adventure seekers!',
      'date': 'Feb 10, 2025',
      'color': '0xFF059669', // Emerald
    },
    {
      'name': 'Sophia K.',
      'comment': 'Tokyo is vibrant and full of life. Loved the culture and shopping experience. Can\'t wait to go back!',
      'date': 'Jan 22, 2025',
      'color': '0xFFDC2626', // Red
    },
  ];

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));

    _floatingAnimation = Tween<double>(
      begin: 0.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
    _floatingController.repeat(reverse: true);

    // Auto-scroll reviews
    _startAutoScroll();
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _nextPage();
        _startAutoScroll();
      }
    });
  }

  void _nextPage() {
    setState(() {
      _currentPage = (_currentPage + 1) % reviews.length;
    });
    _pageController.animateToPage(
      _currentPage,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _floatingController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF000000), // Pure black
              Color(0xFF0A0A0A), // Very dark gray
              Color(0xFF1A1A1A), // Dark gray
              Color(0xFF000000), // Pure black
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated background elements
            _buildBackgroundElements(),
            
            SafeArea(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideAnimation.value),
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: Column(
                        children: [
                          // Title Section
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 40),
                            child: Column(
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) => const LinearGradient(
                                    colors: [
                                      Colors.white,
                                      Color(0xFFE5E5E5), // Light gray
                                      Color(0xFFCCCCCC), // Medium gray
                                    ],
                                  ).createShader(bounds),
                                  child: Text(
                                    'See What Other\nTravelers Say',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 32,
                                          height: 1.2,
                                          letterSpacing: -0.5,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Read real experiences from travelers around the world to plan your next perfect trip.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: const Color(0xFFAAAAAA),
                                        fontSize: 17,
                                        height: 1.6,
                                        fontWeight: FontWeight.w400,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),

                          // Phone mockup with floating animation
                          Expanded(
                            child: AnimatedBuilder(
                              animation: _floatingAnimation,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0, _floatingAnimation.value),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: _buildEnhancedPhoneMockup(context),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Enhanced Page Indicators
                          _buildPageIndicators(),

                          const SizedBox(height: 40),

                          // Enhanced Next Button
                          _buildNextButton(context),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundElements() {
    return Stack(
      children: [
        // Floating orbs
        Positioned(
          top: 100,
          left: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.02),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 150,
          right: -80,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.03),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedPhoneMockup(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      height: MediaQuery.of(context).size.height * 0.55,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2A2A2A), // Dark gray
            Color(0xFF1A1A1A), // Darker gray
            Color(0xFF0A0A0A), // Very dark gray
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(45),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.8),
            blurRadius: 40,
            offset: const Offset(0, 15),
            spreadRadius: 8,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 0),
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(43),
        child: Stack(
          children: [
            // Screen notch
            Positioned(
              top: 15,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 120,
                  height: 25,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
            
            // Screen content
            Positioned.fill(
              top: 50,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.03),
                        Colors.white.withOpacity(0.01),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Header
                        Text(
                          'Reviews',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 40,
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.white, Color(0xFFCCCCCC)],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Review cards
                        Expanded(
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: reviews.length,
                            onPageChanged: (index) {
                              setState(() {
                                _currentPage = index;
                              });
                            },
                            itemBuilder: (context, index) {
                              return _buildReviewCard(reviews[index]);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Screen glare effect
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.white.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(Map<String, String> review) {
    // Use white/gray colors for black theme
    final color = Colors.white;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.white.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.9),
                      Colors.white.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    review['name']!.substring(0, 1),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review['name']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      review['date']!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Review text
          Text(
            '"${review['comment']!}"',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 15,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Star rating
          Row(
            children: List.generate(5, (starIndex) {
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.star,
                  color: const Color(0xFFFBBF24), // Amber-400
                  size: 18,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: index == 1 ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            gradient: index == 1
                ? const LinearGradient(
                    colors: [Colors.white, Color(0xFFCCCCCC)],
                  )
                : null,
            color: index == 1 ? null : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            boxShadow: index == 1
                ? [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildNextButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFE5E5E5)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/intro3');
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Next',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.black,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}