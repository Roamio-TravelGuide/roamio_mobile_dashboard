// app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import './route_guard.dart';
import '../features/auth/api/auth_api.dart';

import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/signup_screen.dart';
import '../features/Landing/presentation/screens/intro_1.dart';
import '../features/Landing/presentation/screens/intro_2.dart';
import '../features/Landing/presentation/screens/intro_3.dart';
import '../features/Landing/presentation/screens/select_user.dart';

import '../features/tourguide/presentation/screens/guide_landing.dart';
import '../features/tourguide/presentation/screens/earnings.dart';
import '../features/tourguide/presentation/screens/profile.dart';

import '../features/traveller/presentation/screens/home_page.dart';
import '../features/traveller/presentation/screens/mytrip.dart';
import '../features/traveller/presentation/screens/add_hidden_page.dart';
import '../features/traveller/presentation/screens/profile_screen.dart';
import '../core/widgets/bottom_navigation.dart';

class AppRoutes {
  // Auth routes
  static const String login = '/login';
  static const String signUp = '/signup';
  
  // Landing routes
  static const String intro1 = '/intro1';
  static const String intro2 = '/intro2';
  static const String intro3 = '/intro3';
  static const String selectUser = '/selectUser';
  
  // Tour Guide routes
  static const String guide = '/guide';
  static const String guideHome = 'home';
  static const String guideMyTrips = 'myTrips';
  static const String guideEarnings = 'earnings';
  static const String guideProfile = 'profile';
  
  // Traveler routes
  static const String traveler = '/traveler';
  static const String travelerHome = 'home';
  static const String travelerMyTrips = 'myTrips';
  static const String travelerFavorites = 'favorites';
  static const String travelerProfile = 'profile';
  
  // Common routes
  static const String addHiddenPage = '/addHiddenPage';
  
  // Bottom navigation indices
  static const int homeTab = 0;
  static const int myTripsTab = 1;
  static const int favoritesTab = 2;
  static const int earningsTab = 2;
  static const int profileTab = 3;
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.login,
  routes: [
    // Auth routes
    GoRoute(
      path: AppRoutes.login,
      builder: (_, __) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.signUp,
      builder: (_, __) => const SignUpScreen(),
    ),
    
    // Landing routes
    GoRoute(
      path: AppRoutes.intro1,
      builder: (_, __) => const Intro1Screen(),
    ),
    GoRoute(
      path: AppRoutes.intro2,
      builder: (_, __) => const Intro2Screen(),
    ),
    GoRoute(
      path: AppRoutes.intro3,
      builder: (_, __) => const Intro3Screen(),
    ),
    GoRoute(
      path: AppRoutes.selectUser,
      builder: (_, __) => const SelectUserScreen(),
    ),
    
    // Add Hidden Page (common for both roles)
    GoRoute(
      path: AppRoutes.addHiddenPage,
      builder: (_, __) => const AddHiddenPage(),
    ),
    
    // Tour Guide tabbed navigation
    ShellRoute(
      builder: (context, state, child) {
        int currentIndex = _getGuideCurrentIndex(state.uri.path);
        return FutureBuilder<String?>(
          future: AuthApi.getUserRole(),
          builder: (context, snapshot) {
            final role = snapshot.data ?? 'traveler';
            return Scaffold(
              body: child,
              bottomNavigationBar: CustomBottomNavigationBar(
                currentIndex: currentIndex, 
                userRole: role,
              ),
            );
          },
        );
      },
      routes: [
        // Guide home is the default route
        GoRoute(
          path: '${AppRoutes.guide}/:tab(${AppRoutes.guideHome}|${AppRoutes.guideMyTrips}|${AppRoutes.guideEarnings}|${AppRoutes.guideProfile})',
          builder: (context, state) {
            final tab = state.pathParameters['tab'] ?? AppRoutes.guideHome;
            switch (tab) {
              case AppRoutes.guideHome:
                return const GuideLandingScreen();
              case AppRoutes.guideMyTrips:
                return const MyTripScreen();
              case AppRoutes.guideEarnings:
                return const EarningsScreen();
              case AppRoutes.guideProfile:
                return const GuideProfilePage();
              default:
                return const GuideLandingScreen();
            }
          },
        ),
      ],
    ),
    
    // Traveler tabbed navigation
    ShellRoute(
      builder: (context, state, child) {
        int currentIndex = _getTravelerCurrentIndex(state.uri.path);
        return FutureBuilder<String?>(
          future: AuthApi.getUserRole(),
          builder: (context, snapshot) {
            final role = snapshot.data ?? 'traveler';
            return Scaffold(
              body: child,
              bottomNavigationBar: CustomBottomNavigationBar(
                currentIndex: currentIndex, 
                userRole: role,
              ),
            );
          },
        );
      },
      routes: [
        // Traveler home is the default route
        GoRoute(
          path: '${AppRoutes.traveler}/:tab(${AppRoutes.travelerHome}|${AppRoutes.travelerMyTrips}|${AppRoutes.travelerFavorites}|${AppRoutes.travelerProfile})',
          builder: (context, state) {
            final tab = state.pathParameters['tab'] ?? AppRoutes.travelerHome;
            switch (tab) {
              case AppRoutes.travelerHome:
                return const HomePage();
              case AppRoutes.travelerMyTrips:
                return const MyTripScreen();
              case AppRoutes.travelerFavorites:
                return const FavoritesScreen();
              case AppRoutes.travelerProfile:
                return const TravelerProfilePage();
              default:
                return const HomePage();
            }
          },
        ),
      ],
    ),
  ],
  
  redirect: (context, state) async {
    final authRedirect = await RouteGuard.redirectIfNotAuth(context, state);
    if (authRedirect != null) return authRedirect;
    
    final roleRedirect = await RouteGuard.redirectIfAuth(context, state);
    return roleRedirect;
  },
  
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('404 - Page Not Found')),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Page not found: ${state.uri}',
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () async {
              final role = await AuthApi.getUserRole();
              if (role == 'travel_guide') {
                context.go('${AppRoutes.guide}/${AppRoutes.guideHome}');
              } else {
                context.go('${AppRoutes.traveler}/${AppRoutes.travelerHome}');
              }
            },
            child: const Text('Go Home'),
          ),
        ],
      ),
    ),
  ),
);

int _getTravelerCurrentIndex(String path) {
  if (path.contains(AppRoutes.travelerHome)) return AppRoutes.homeTab;
  if (path.contains(AppRoutes.travelerMyTrips)) return AppRoutes.myTripsTab;
  if (path.contains(AppRoutes.travelerFavorites)) return AppRoutes.favoritesTab;
  if (path.contains(AppRoutes.travelerProfile)) return AppRoutes.profileTab;
  return AppRoutes.homeTab;
}

int _getGuideCurrentIndex(String path) {
  if (path.contains(AppRoutes.guideHome)) return AppRoutes.homeTab;
  if (path.contains(AppRoutes.guideMyTrips)) return AppRoutes.myTripsTab;
  if (path.contains(AppRoutes.guideEarnings)) return AppRoutes.earningsTab;
  if (path.contains(AppRoutes.guideProfile)) return AppRoutes.profileTab;
  return AppRoutes.homeTab;
}

// Placeholder screen for favorites
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Favorites Screen')),
    );
  }
}