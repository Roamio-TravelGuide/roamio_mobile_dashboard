import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'select_user.dart';

class Intro3Screen extends StatefulWidget {
  const Intro3Screen({super.key});

  @override
  State<Intro3Screen> createState() => _Intro3ScreenState();
}

class _Intro3ScreenState extends State<Intro3Screen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _floatingController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _floatingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
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

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
    ));

    _floatingAnimation = Tween<double>(
      begin: -15.0,
      end: 15.0,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
    _floatingController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _floatingController.dispose();
    _pulseController.dispose();
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
                          const SizedBox(height: 60),

                          // Title Section
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              children: [
                                Transform.scale(
                                  scale: _scaleAnimation.value,
                                  child: ShaderMask(
                                    shaderCallback: (bounds) => const LinearGradient(
                                      colors: [
                                        Colors.white,
                                        Color(0xFFE5E5E5),
                                        Color(0xFFCCCCCC),
                                      ],
                                    ).createShader(bounds),
                                    child: Text(
                                      'Are You Excited to\nStart the Journey?',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 34,
                                            height: 1.2,
                                            letterSpacing: -0.5,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Your adventure awaits! Get ready to explore amazing destinations, create unforgettable memories, and discover the world like never before.',
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

                          const SizedBox(height: 60),

                          // Animated Journey Icon
                          Expanded(
                            child: AnimatedBuilder(
                              animation: _floatingAnimation,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0, _floatingAnimation.value),
                                  child: _buildJourneyVisualization(context),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Enhanced Page Indicators
                          _buildPageIndicators(),

                          const SizedBox(height: 50),

                          // Get Started Button
                          _buildGetStartedButton(context),

                          const SizedBox(height: 40),
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
          top: 120,
          right: -30,
          child: Container(
            width: 180,
            height: 180,
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
        Positioned(
          bottom: 200,
          left: -50,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.02),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // Scattered dots
        ...List.generate(20, (index) {
          return Positioned(
            top: (index * 47.0) % MediaQuery.of(context).size.height,
            left: (index * 73.0) % MediaQuery.of(context).size.width,
            child: Container(
              width: 2,
              height: 2,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildJourneyVisualization(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      height: MediaQuery.of(context).size.height * 0.4,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Central journey icon with pulse animation
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.05),
                        Colors.transparent,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Colors.white,
                          Color(0xFFE5E5E5),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.flight_takeoff_rounded,
                      color: Colors.black,
                      size: 40,
                    ),
                  ),
                ),
              );
            },
          ),

          // Orbiting elements
          ...List.generate(6, (index) {
            final angle = (index * 60.0) * (3.14159 / 180);
            final radius = 100.0;
            final x = radius * cos(angle);
            final y = radius * sin(angle);
            
            return Transform.translate(
              offset: Offset(x, y),
              child: _buildOrbitingIcon(index),
            );
          }),

          // Journey path visualization
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width * 0.7, 200),
            painter: JourneyPathPainter(),
          ),
        ],
      ),
    );
  }

  Widget _buildOrbitingIcon(int index) {
    final icons = [
      Icons.location_on_rounded,
      Icons.camera_alt_rounded,
      Icons.restaurant_rounded,
      Icons.hotel_rounded,
      Icons.directions_car_rounded,
      Icons.favorite_rounded,
    ];

    return AnimatedBuilder(
      animation: _floatingController,
      builder: (context, child) {
        return Transform.rotate(
          angle: (_floatingController.value * 2 * 3.14159) + (index * 0.5),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(
              icons[index],
              color: Colors.white.withOpacity(0.8),
              size: 24,
            ),
          ),
        );
      },
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
          width: index == 2 ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            gradient: index == 2
                ? const LinearGradient(
                    colors: [Colors.white, Color(0xFFCCCCCC)],
                  )
                : null,
            color: index == 2 ? null : Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            boxShadow: index == 2
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

  Widget _buildGetStartedButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_pulseAnimation.value - 1.0) * 0.02,
            child: Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.white, Color(0xFFE5E5E5)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.4),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () {
                    // Navigate to main app or next screen
                    Navigator.pushReplacementNamed(context, '/select_user');
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
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
                            'Get Started',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(width: 12),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.black,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class JourneyPathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    
    // Create a curved journey path
    path.moveTo(size.width * 0.1, size.height * 0.8);
    path.quadraticBezierTo(
      size.width * 0.3, size.height * 0.2,
      size.width * 0.5, size.height * 0.6,
    );
    path.quadraticBezierTo(
      size.width * 0.7, size.height * 0.9,
      size.width * 0.9, size.height * 0.3,
    );

    canvas.drawPath(path, paint);

    // Add dotted effect
    final dashPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (double i = 0; i < 1; i += 0.05) {
      final metric = path.computeMetrics().first;
      final tangent = metric.getTangentForOffset(metric.length * i);
      if (tangent != null) {
        canvas.drawCircle(tangent.position, 1, dashPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}