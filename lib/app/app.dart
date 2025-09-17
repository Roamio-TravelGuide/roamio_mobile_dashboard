// app.dart
import 'package:Roamio/features/auth/presentation/screens/signup_screen.dart';
//import 'package:Roamio/features/traveller/presentation/screens/mytrip.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/traveller/presentation/screens/package-details.dart';
import '../features/traveller/presentation/screens/home_page.dart';
import '../features/traveller/presentation/screens/mytrip_bottomnavigationbar.dart';
import '../core/widgets/bottom_navigation.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Roamio',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routerConfig: _router,
    );
  }
}

// Define routes
final GoRouter _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),

    GoRoute(
      path:'/signup',
      builder: (context, state) => const SignUpScreen(), // Replace with SignupScreen when available
    ),
    // Screens with bottom navigation
    GoRoute(
      path: '/home',
      builder: (context, state) => const ScaffoldWithNavBar(
        currentIndex: 0,
        child: HomePage(),
      ),
    ),
    GoRoute(
      path: '/traveller',
      builder: (context, state) => const ScaffoldWithNavBar(
        currentIndex: 1,
        child: TravelApp(),
      ),
    ),

    GoRoute(
      path: '/MyTrips',
      builder: (context, state) =>  ScaffoldWithNavBar(
        currentIndex: 1,
        child: MyTrips(),
      ),
    ),
    
    GoRoute(
      path: '/favorites',
      builder: (context, state) => const ScaffoldWithNavBar(
        currentIndex: 3,
        child: FavoritesScreen(),
      ),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ScaffoldWithNavBar(
        currentIndex: 4,
        child: ProfileScreen(),
      ),
    ),
  ],
  // Add error builder for better debugging
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text(
        'Page not found: ${state.uri.toString()}',
        style: TextStyle(color: Colors.red),
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
      bottomNavigationBar: CustomBottomNavigationBar(currentIndex: currentIndex),
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