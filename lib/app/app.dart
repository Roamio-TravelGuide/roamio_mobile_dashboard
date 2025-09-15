// app.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/screens/login_screen.dart';

import '../features/auth/presentation/screens/signup_screen.dart';

import '../features/traveller/presentation/screens/package-details.dart';

import '../features/traveller/presentation/screens/home_page.dart';
import '../features/traveller/presentation/screens/mytrip.dart';
import '../features/traveller/presentation/screens/package-details.dart';
import '../features/traveller/presentation/screens/add_hidden_page.dart';
import '../features/traveller/presentation/screens/mytrip_bottomnavigationbar.dart';
import '../core/widgets/bottom_navigation.dart';
import '../features/Landing/presentation/screens/home_screen.dart';
import '../features/Landing/presentation/screens/intro_1.dart';
import '../features/Landing/presentation/screens/intro_2.dart';
import '../features/Landing/presentation/screens/intro_3.dart';
import '../features/Landing/presentation/screens/select_user.dart';
import '../features/tourguide/presentation/screens/earnings.dart';
import '../features/tourguide/presentation/screens/profile.dart';
import '../features/tourguide/presentation/screens/guide_landing.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Roamio',
      theme: ThemeData(primarySwatch: Colors.blue),
      routerConfig: _router,
    );
  }
}

// Define routes
final GoRouter _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (context, state) => const SignUpScreen()),
    GoRoute(path: '/intro1', builder: (context, state) => const Intro1Screen()),
    GoRoute(path: '/intro2', builder: (context, state) => const Intro2Screen()),
    GoRoute(path: '/intro3', builder: (context, state) => const Intro3Screen()),
    GoRoute(
      path: '/selectUser',
      builder: (context, state) => const SelectUserScreen(),
    ),
    GoRoute(
      path: '/guideLanding',
      builder: (context, state) => const GuideLandingScreen(),
    ),
    GoRoute(
      path: '/earnings',
      builder: (context, state) => const EarningsScreen(),
    ),
    GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),

    // Screens with bottom navigation
    GoRoute(
      path: '/home',
      builder: (context, state) =>
          const ScaffoldWithNavBar(currentIndex: 0, child: HomePage()),
    ),
    GoRoute(
      path: '/traveller',
      builder: (context, state) =>
          const ScaffoldWithNavBar(currentIndex: 1, child: TravelApp()),
    ),
    GoRoute(
      path: '/MyTrips',
      builder: (context, state) =>
          ScaffoldWithNavBar(currentIndex: 1, child: MyTrips()),
    ),
    GoRoute(
      path: '/favorites',
      builder: (context, state) =>
          const ScaffoldWithNavBar(currentIndex: 3, child: FavoritesScreen()),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) =>
          const ScaffoldWithNavBar(currentIndex: 4, child: ProfileScreen()),
    ),
  ],

  // Error page for unknown routes
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
            onPressed: () => context.go('/home'),
            child: const Text('Go Home'),
          ),
        ],
      ),
    ),
  ),
);

// Scaffold wrapper for screens with bottom navigation
class ScaffoldWithNavBar extends StatelessWidget {
  final int currentIndex;
  final Widget child;

  const ScaffoldWithNavBar({
    Key? key,
    required this.currentIndex,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: currentIndex,
      ),
    );
  }
}

// Placeholder screens
class AddScreen extends StatelessWidget {
  const AddScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Add Screen'));
  }
}

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Favorites Screen'));
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Profile Screen'));
  }
}
