// core/widgets/bottom_navigation.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../routes/app_router.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final String userRole;

  const CustomBottomNavigationBar({
    Key? key,
    required this.currentIndex,
    required this.userRole,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isGuide = userRole == 'travel_guide';
    
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
          // Home
          _NavItem(
            Icons.home_outlined,
            'Home',
            currentIndex == AppRoutes.homeTab,
            onTap: () => _navigateToHome(context),
          ),
          
          // My Trips
          _NavItem(
            Icons.location_on,
            'My Trip',
            currentIndex == AppRoutes.myTripsTab,
            onTap: () => _navigateToMyTrips(context),
          ),
          
          // Add for traveler, or empty space for guide
          if (isGuide)
            const SizedBox(width: 48) // Empty space to maintain layout
          else
            GestureDetector(
              onTap: () => context.go(AppRoutes.addHiddenPage),
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
          
          // Favorites for traveler, Earnings for guide
          isGuide
            ? _NavItem(
                Icons.attach_money,
                'Earnings',
                currentIndex == AppRoutes.earningsTab,
                onTap: () => _navigateToEarnings(context),
              )
            : _NavItem(
                Icons.favorite_outline,
                'Favorite',
                currentIndex == AppRoutes.favoritesTab,
                onTap: () => _navigateToFavorites(context),
              ),
          
          // Profile
          _NavItem(
            Icons.person_outline,
            'Profile',
            currentIndex == AppRoutes.profileTab,
            onTap: () => _navigateToProfile(context),
          ),
        ],
      ),
    );
  }

  void _navigateToHome(BuildContext context) {
    if (userRole == 'travel_guide') {
      context.go('${AppRoutes.guide}/${AppRoutes.guideHome}');
    } else {
      context.go('${AppRoutes.traveler}/${AppRoutes.travelerHome}');
    }
  }

  void _navigateToMyTrips(BuildContext context) {
    if (userRole == 'travel_guide') {
      context.go('${AppRoutes.guide}/${AppRoutes.guideMyTrips}');
    } else {
      context.go('${AppRoutes.traveler}/${AppRoutes.travelerMyTrips}');
    }
  }

  void _navigateToFavorites(BuildContext context) {
    context.go('${AppRoutes.traveler}/${AppRoutes.travelerFavorites}');
  }

  void _navigateToEarnings(BuildContext context) {
    context.go('${AppRoutes.guide}/${AppRoutes.guideEarnings}');
  }

  void _navigateToProfile(BuildContext context) {
    if (userRole == 'travel_guide') {
      context.go('${AppRoutes.guide}/${AppRoutes.guideProfile}');
    } else {
      context.go('${AppRoutes.traveler}/${AppRoutes.travelerProfile}');
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