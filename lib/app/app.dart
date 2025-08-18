import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// import '../features/auth/presentation/screens/login_screen.dart';
import '../features/Landing/presentation/screens/home_screen.dart';
// import '../routes/route_guard.dart';

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
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    // Other routes (dashboard, register, etc.)
  ],
  // redirect: RouteGuard.checkAuth, // Optional route guard
);
