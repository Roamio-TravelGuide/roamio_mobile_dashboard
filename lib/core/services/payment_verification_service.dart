import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_client.dart';
import '../config/env_config.dart';
import '../utils/storage_helper.dart';

class PaymentVerificationService {
  static final ApiClient _apiClient = ApiClient(customBaseUrl: EnvConfig.baseUrl);

  /// Check if user has paid for a specific package
  static Future<bool> hasUserPaidForPackage(String packageId) async {
    try {
      String? userId;

      // 1️⃣ Try secure storage first
      userId = await StorageHelper.getUserId();

      // 2️⃣ Try SharedPreferences
      if (userId == null) {
        final prefs = await SharedPreferences.getInstance();
        final keysToCheck = ['user_id', 'userId'];

        for (final key in keysToCheck) {
          final storedValue = prefs.get(key); // can be int or String
          if (storedValue != null) {
            userId = storedValue.toString(); // convert int to String safely
            print('PaymentVerificationService: Using user ID from SharedPreferences ($key): $userId');
            break;
          }
        }
      }

      if (userId == null) {
        print('PaymentVerificationService: No user ID found in storage');
        return false;
      }

      print('PaymentVerificationService: Checking payment for package $packageId, user $userId');
      return await _checkPaymentStatus(packageId, userId);
    } catch (e) {
      print('PaymentVerificationService: Error checking payment status: $e');
      return false;
    }
  }

  /// Private method to call API and verify payment
  static Future<bool> _checkPaymentStatus(String packageId, String userId) async {
    try {
      // ✅ Corrected endpoint: removed duplicate /api/v1
      final response = await _apiClient.get(
        '/packages/$packageId/payment-status',
        queryParameters: {'userId': userId},
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        final data = responseBody['data'];

        if (data != null) {
          // Handle multiple possible fields for status
          if (data.containsKey('hasPaid')) {
            return data['hasPaid'] ?? false;
          } else if (data.containsKey('status')) {
            final status = data['status']?.toString().toLowerCase();
            return status == 'completed' || status == 'paid';
          } else if (data.containsKey('paymentStatus')) {
            final status = data['paymentStatus']?.toString().toLowerCase();
            return status == 'completed' || status == 'paid';
          }
        }
      }
      return false;
    } catch (e) {
      print('PaymentVerificationService: Error during payment API call: $e');
      return false;
    }
  }

  /// Get detailed payment information for a package
  static Future<Map<String, dynamic>?> getPaymentDetails(String packageId) async {
    try {
      final userId = await StorageHelper.getUserId();
      if (userId == null) return null;

      final response = await _apiClient.get(
        '/packages/$packageId/payment-status',
        queryParameters: {'userId': userId},
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody['success'] == true && responseBody['data'] != null) {
          return responseBody['data'];
        }
      }
      return null;
    } catch (e) {
      print('PaymentVerificationService: Error getting payment details: $e');
      return null;
    }
  }

  /// Verify access to package content based on payment status
  static Future<PackageAccessLevel> getPackageAccessLevel(String packageId) async {
    try {
      final hasPaid = await hasUserPaidForPackage(packageId);

      if (hasPaid) {
        return PackageAccessLevel.fullAccess;
      } else {
        return PackageAccessLevel.previewOnly;
      }
    } catch (e) {
      print('PaymentVerificationService: Error determining access level: $e');
      return PackageAccessLevel.previewOnly;
    }
  }

  /// Check if user can access a specific stop in a package
  static Future<bool> canAccessStop(String packageId, int stopIndex) async {
    try {
      final accessLevel = await getPackageAccessLevel(packageId);

      switch (accessLevel) {
        case PackageAccessLevel.fullAccess:
          return true;
        case PackageAccessLevel.previewOnly:
          // Allow access to first 2 stops only in preview mode
          return stopIndex < 2;
        case PackageAccessLevel.noAccess:
          return false;
      }
    } catch (e) {
      print('PaymentVerificationService: Error checking stop access: $e');
      return false;
    }
  }

  /// Get maximum number of stops accessible based on payment status
  static Future<int> getMaxAccessibleStops(String packageId) async {
    try {
      final accessLevel = await getPackageAccessLevel(packageId);

      switch (accessLevel) {
        case PackageAccessLevel.fullAccess:
          return -1; // -1 means unlimited access
        case PackageAccessLevel.previewOnly:
          return 2; // Preview limited to first 2 stops
        case PackageAccessLevel.noAccess:
          return 0;
      }
    } catch (e) {
      print('PaymentVerificationService: Error getting max accessible stops: $e');
      return 0;
    }
  }
}

enum PackageAccessLevel {
  fullAccess,    // User has paid - full access to all content
  previewOnly,   // User hasn't paid - limited preview access
  noAccess,      // No access at all
}
