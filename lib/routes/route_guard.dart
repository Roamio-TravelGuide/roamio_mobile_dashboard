import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/utils/storage_helper.dart';
import './app_router.dart';
import '../features/auth/api/auth_api.dart';


class RouteGuard {
  static Future<String?> redirectIfNotAuth(BuildContext context, GoRouterState state) async {
    final token = await StorageHelper.getToken();
    final role = await AuthApi.getUserRole();
    final isAuthRoute = state.uri.path == AppRoutes.login || 
                        state.uri.path == AppRoutes.signUp;

    // If no token and trying to access protected route, redirect to login
    if (token == null && !isAuthRoute) {
      print('🔒 No token found, redirecting to login');
      return AppRoutes.login;
    }
    
    // If has token and not on auth/role-specific route, redirect to appropriate home
    if (token != null && !isAuthRoute) {
      final isTravelerRoute = state.uri.path.startsWith(AppRoutes.traveler);
      final isGuideRoute = state.uri.path.startsWith(AppRoutes.guide);
      
      if (!isTravelerRoute && !isGuideRoute) {
        if (role == 'traveler') {
          return '${AppRoutes.traveler}/${AppRoutes.travelerHome}';
        } else if (role == 'travel_guide') {
          return '${AppRoutes.guide}/${AppRoutes.guideHome}';
        }
      }
    }
    
    return null;
  }

  static Future<String?> redirectIfAuth(BuildContext context, GoRouterState state) async {
    final token = await StorageHelper.getToken();
    final isAuthRoute = state.uri.path == AppRoutes.login || 
                        state.uri.path == AppRoutes.signUp;
    
    // Skip redirect during logout process
    if (state.uri.path == AppRoutes.login && state.extra != null) {
      final Map<String, dynamic> extra = state.extra as Map<String, dynamic>;
      if (extra['isLogout'] == true) {
        return null;
      }
    }
    
    // ONLY redirect if token exists, is valid, AND on auth route
    if (token != null && token.isNotEmpty && isAuthRoute) {
      // Double check if the token is actually valid
      final role = await AuthApi.getUserRole();
      if (role == null) {
        // Invalid token, allow access to login
        return null;
      }
      
      print('✅ Has valid token, redirecting from auth page to home');
      if (role == 'travel_guide') {
        return '${AppRoutes.guide}/${AppRoutes.guideHome}';
      } else {
        return '${AppRoutes.traveler}/${AppRoutes.travelerHome}';
      }
    }
    
    return null;
  }
}