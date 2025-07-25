import 'package:go_router/go_router.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import 'route_guard.dart';

class AppRouter {
  static final router = GoRouter(
    routes: [
      GoRoute(
        path: '/login',
         builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        // builder: (_, __) => const DashboardScreen(),
        redirect: RouteGuard.redirectIfNotAuth,
      ),
    ],
    initialLocation: '/login',
  );
}