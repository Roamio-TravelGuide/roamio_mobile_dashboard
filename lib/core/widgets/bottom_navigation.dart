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
        children: _buildNavigationItems(isGuide, context),
      ),
    );
  }

  List<Widget> _buildNavigationItems(bool isGuide, BuildContext context) {
    if (isGuide) {
      // Guide navigation - 4 items without add button
      return [
        // Home
        _NavItem(
          icon: Icons.home_outlined,
          label: 'Home',
          isActive: currentIndex == AppRoutes.homeTab,
          onTap: () => _navigateToHome(context),
        ),
        
        // My Trips
        _NavItem(
          icon: Icons.location_on,
          label: 'My Trip',
          isActive: currentIndex == AppRoutes.myTripsTab,
          onTap: () => _navigateToMyTrips(context),
        ),
        
        // Earnings
        _NavItem(
          icon: Icons.attach_money,
          label: 'Earnings',
          isActive: currentIndex == AppRoutes.earningsTab,
          onTap: () => _navigateToEarnings(context),
        ),
        
        // Profile
        _NavItem(
          icon: Icons.person_outline,
          label: 'Profile',
          isActive: currentIndex == AppRoutes.profileTab,
          onTap: () => _navigateToProfile(context),
        ),
      ];
    } else {
      // Traveler navigation - 5 items with add button in middle
      return [
        // Home
        _NavItem(
          icon: Icons.home_outlined,
          label: 'Home',
          isActive: currentIndex == AppRoutes.homeTab,
          onTap: () => _navigateToHome(context),
        ),
        
        // My Trips
        _NavItem(
          icon: Icons.location_on,
          label: 'My Trip',
          isActive: currentIndex == AppRoutes.myTripsTab,
          onTap: () => _navigateToMyTrips(context),
        ),
        
        // Add button - ONLY for travelers
        _AddButton(
          onTap: () => _navigateToAddHiddenPage(context),
        ),
        
        // Favorites
        _NavItem(
          icon: Icons.favorite_outline,
          label: 'Favorite',
          isActive: currentIndex == AppRoutes.favoritesTab,
          onTap: () => _navigateToFavorites(context),
        ),
        
        // Profile
        _NavItem(
          icon: Icons.person_outline,
          label: 'Profile',
          isActive: currentIndex == AppRoutes.profileTab,
          onTap: () => _navigateToProfile(context),
        ),
      ];
    }
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

  void _navigateToAddHiddenPage(BuildContext context) {
    // This is only for travelers now
    context.go('${AppRoutes.traveler}/${AppRoutes.addHiddenPage}');
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 60,
        height: 60,
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
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}