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

    if (token == null && !isAuthRoute) {
      return AppRoutes.login;
    }
    
    // Redirect to appropriate home based on role
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
    final role = await AuthApi.getUserRole();
    final isAuthRoute = state.uri.path == AppRoutes.login || 
                        state.uri.path == AppRoutes.signUp;
    
    if (token != null && isAuthRoute) {
      if (role == 'travel_guide') {
        return '${AppRoutes.guide}/${AppRoutes.guideHome}';
      } else {
        return '${AppRoutes.traveler}/${AppRoutes.travelerHome}';
      }
    }
    return null;
  }
}