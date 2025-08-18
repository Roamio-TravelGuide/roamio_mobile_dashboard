import 'package:go_router/go_router.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/signup_screen.dart';
import '../features/landing/presentation/screens/home_screen.dart';
import 'route_guard.dart';

class AppRoutes {
  static const String login = '/login';
  static const String signUp = '/signup';
  static const String dashboard = '/dashboard';
  static const String home = '/home';
}

final router = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(
      path: AppRoutes.login,
      builder: (_, __) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.signUp,
      builder: (_, __) => const SignUpScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (_, __) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.dashboard,
      redirect: RouteGuard.redirectIfNotAuth,
    ),
  ],
);