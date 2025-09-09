// features/traveller/presentation/widgets/bottom_navigation.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNavigationBar({
    Key? key,
    required this.currentIndex,
  }) : super(key: key);

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
          _NavItem(
            Icons.home_outlined,
            'Home',
            currentIndex == 0,
            onTap: () => _navigateTo(context, 0),
          ),
          _NavItem(
            Icons.location_on,
            'My Trip',
            currentIndex == 1,
            onTap: () => _navigateTo(context, 1),
          ),
          GestureDetector(
            onTap: () => _navigateTo(context, 2),
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 24),
            ),
          ),
          _NavItem(
            Icons.favorite_outline,
            'Favorite',
            currentIndex == 3,
            onTap: () => _navigateTo(context, 3),
          ),
          _NavItem(
            Icons.person_outline,
            'Profile',
            currentIndex == 4,
            onTap: () => _navigateTo(context, 4),
          ),
        ],
      ),
    );
  }

  void _navigateTo(BuildContext context, int index) {
    if (index == currentIndex) return; // Already on this screen
    
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/traveller');
        break;
      case 2:
        context.go('/add');
        break;
      case 3:
        context.go('/favorites');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem(this.icon, this.label, this.isActive, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
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
      ),
    );
  }
}