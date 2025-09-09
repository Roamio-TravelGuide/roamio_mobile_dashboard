import 'package:go_router/go_router.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/signup_screen.dart';
import '../features/landing/presentation/screens/home_screen.dart';
import '../features/landing/presentation/screens/intro_1.dart';
import '../features/landing/presentation/screens/intro_2.dart';
import '../features/landing/presentation/screens/intro_3.dart';
import '../features/landing/presentation/screens/select_user.dart';
import '../features/tourguide/presentation/screens/guide_landing.dart';
import '../features/tourguide/presentation/screens/earnings.dart';
import '../features/tourguide/presentation/screens/profile.dart';
import 'route_guard.dart';

class AppRoutes {
  static const String login = '/login';
  static const String signUp = '/signup';
  static const String dashboard = '/dashboard';
  static const String home = '/home';
  static const String intro1 = '/intro1';
  static const String intro2 = '/intro2';
  static const String intro3 = '/intro3';
  static const String selectUser = '/selectUser';
  static const String guideLanding = '/guideLanding';
  static const String earnings = '/earnings';
  static const String profile = '/profile';
}

final router = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
    GoRoute(path: AppRoutes.signUp, builder: (_, __) => const SignUpScreen()),
    GoRoute(path: AppRoutes.home, builder: (_, __) => const HomeScreen()),
    GoRoute(path: AppRoutes.intro1, builder: (_, __) => const Intro1Screen()),
    GoRoute(path: AppRoutes.intro2, builder: (_, __) => const Intro2Screen()),
    GoRoute(path: AppRoutes.intro3, builder: (_, __) => const Intro3Screen()),
    GoRoute(path: AppRoutes.selectUser, builder: (_, __) => const SelectUserScreen()),
    GoRoute(path: AppRoutes.guideLanding, builder: (_, __) => const GuideLandingScreen()),
    GoRoute(path: AppRoutes.earnings, builder: (_, __) => const EarningsScreen()),
    GoRoute(path: AppRoutes.profile, builder: (_, __) => const ProfilePage()),
    GoRoute(path: AppRoutes.dashboard, redirect: RouteGuard.redirectIfNotAuth),
  ],
);