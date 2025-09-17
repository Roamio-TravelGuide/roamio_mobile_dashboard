// lib/core/config/env_config.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get baseUrl => dotenv.get('BASE_URL', fallback: 'http://localhost:3001/api/v1');
  static String get googleMapsApiKey => dotenv.get('GOOGLE_MAPS_API_KEY', fallback: '');
  static String get mapboxAccessToken => dotenv.get('MAPBOX_ACCESS_TOKEN', fallback: '');
  static String get stripePublishableKey => dotenv.get('STRIPE_PUBLISHABLE_KEY', fallback: '');
  static bool get debug => dotenv.get('DEBUG', fallback: 'true') == 'true';
  
  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
  }
}