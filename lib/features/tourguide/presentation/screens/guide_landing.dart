import 'package:flutter/material.dart';

class GuideLandingScreen extends StatelessWidget {
  const GuideLandingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good Morning',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'John Smith',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Audio Tour Creator',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Stack(
                    children: [
                      const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Statistics Cards
              Row(
                children: const [
                  Expanded(
                    child: StatCard(
                      icon: Icons.headphones,
                      value: '15',
                      label: 'Audio Tours',
                      iconColor: Color(0xFF4A90E2),
                    ),
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: StatCard(
                      icon: Icons.play_arrow,
                      value: '1,248',
                      label: 'Total Listens',
                      iconColor: Color(0xFFFF6B6B),
                    ),
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: StatCard(
                      icon: Icons.attach_money,
                      value: '\$5,240',
                      label: 'Revenue',
                      iconColor: Color(0xFF4ECDC4),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Popular Audio Tours Section
              const Text(
                'Popular Audio Tours',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: ListView(
                  children: const [
                    AudioTourItem(
                      title: 'Historic Downtown Audio Tour',
                      rating: 4.8,
                      duration: '45 min',
                      steps: '14 stops',
                      downloads: '324 downloads',
                    ),
                    SizedBox(height: 15),
                    AudioTourItem(
                      title: 'Art Museum Audio Guide',
                      rating: 4.6,
                      duration: '60 min',
                      steps: '12 stops',
                      downloads: '156 downloads',
                    ),
                    SizedBox(height: 15),
                    AudioTourItem(
                      title: 'Art Museum Audio Guide',
                      rating: 4.6,
                      duration: '60 min',
                      steps: '12 stops',
                      downloads: '156 downloads',
                    ),
                    SizedBox(height: 15),
                    AudioTourItem(
                      title: 'Art Museum Audio Guide',
                      rating: 4.6,
                      duration: '60 min',
                      steps: '12 stops',
                      downloads: '156 downloads',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Quick Actions Section
              const Text(
                'Quick Actions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  QuickActionButton(
                    icon: Icons.add_circle_outline,
                    label: 'Create',
                    color: Color(0xFF4A90E2),
                  ),
                  QuickActionButton(
                    icon: Icons.play_circle_outline,
                    label: 'Preview',
                    color: Color(0xFFFF6B6B),
                  ),
                  QuickActionButton(
                    icon: Icons.analytics_outlined,
                    label: 'Analytics',
                    color: Color(0xFF4ECDC4),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: Color(0xFF34495E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.dashboard, 'Dashboard', true),
          _buildNavItem(Icons.add_circle_outline, 'Create Tour', false),
          _buildNavItem(Icons.monetization_on, 'Earnings', false),
          _buildNavItem(Icons.person, 'Profile', false),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: isActive ? Colors.teal : Colors.white54,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.teal : Colors.white54,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

// ------------------------ WIDGETS ------------------------

class StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;

  const StatCard({
    Key? key,
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class AudioTourItem extends StatelessWidget {
  final String title;
  final double rating;
  final String duration;
  final String steps;
  final String downloads;

  const AudioTourItem({
    Key? key,
    required this.title,
    required this.rating,
    required this.duration,
    required this.steps,
    required this.downloads,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    rating.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              InfoChip(icon: Icons.access_time, text: duration),
              const SizedBox(width: 12),
              InfoChip(icon: Icons.location_on, text: steps),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            downloads,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const InfoChip({Key? key, required this.icon, required this.text})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.grey[400], size: 14),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ),
      ],
    );
  }
}

class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const QuickActionButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}