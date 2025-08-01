import 'package:go_router/go_router.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/signup_screen.dart';
import 'route_guard.dart';

class AppRoutes {
  static const String login = '/login';
  static const String signUp = '/signup';
  static const String dashboard = '/dashboard';
}

final router = GoRouter(
  initialLocation: AppRoutes.login,
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
      path: AppRoutes.dashboard,
      redirect: RouteGuard.redirectIfNotAuth,
    ),
  ],
);