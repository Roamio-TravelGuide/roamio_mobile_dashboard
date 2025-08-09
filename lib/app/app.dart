import 'package:flutter/foundation.dart'; // for kDebugMode
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/traveller/presentation/screens/package-details.dart'; // Add your screen import

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

// Define routes with debug redirect
final GoRouter _router = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    // If in debug mode and trying to go to login, redirect to traveller
    if (kDebugMode && state.fullPath == '/login') {
      return '/traveller';
    }
    return null; // no redirect otherwise
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/traveller',
      builder: (context, state) =>  TravelApp(),
    ),
    // Other routes (dashboard, register, etc.)
  ],
  // redirect: RouteGuard.checkAuth, // Optional route guard
);
