import '../../features/tourguide/api/tour_package_api.dart';
import '../models/tour_package.dart';

class TourPackageService {
  final TourPackageApi _api;

  TourPackageService({required TourPackageApi api}) : _api = api;

  // Get tour packages for current guide
  Future<List<TourPackage>> getTourPackagesByGuideId({
    String? status,
    String? search,
    int page = 1,
    int limit = 10000,
  }) async {
    try {
      final response = await _api.getTourPackagesByGuideId(
        status: status,
        search: search,
        page: page,
        limit: limit,
      );

      if (response['success'] == true) {
        final data = response['data'];
        return _parseTourPackages(data);
      } else {
        throw Exception(response['message'] ?? 'Failed to load tour packages');
      }
    } catch (error) {
      print('Error in getTourPackagesByGuideId: $error');
      rethrow;
    }
  }

  // Parse tour packages from response data
  List<TourPackage> _parseTourPackages(dynamic data) {
    if (data is List) {
      return data.map((packageData) => TourPackage.fromJson(packageData)).toList();
    } else if (data is Map && data.containsKey('packages')) {
      final packages = data['packages'] as List;
      return packages.map((packageData) => TourPackage.fromJson(packageData)).toList();
    } else {
      throw Exception('Invalid data format in response');
    }
  }

  // Get tour package by ID
  Future<TourPackage> getTourPackageById(int id) async {
    try {
      final response = await _api.getTourPackageById(id);

      if (response['success'] == true) {
        return TourPackage.fromJson(response['data']);
      } else {
        throw Exception(response['message'] ?? 'Failed to load tour package');
      }
    } catch (error) {
      print('Error in getTourPackageById: $error');
      rethrow;
    }
  }

  // Update tour package status
  Future<void> updateTourPackageStatus(
    int id, {
    required PackageStatus status,
    String? rejectionReason,
  }) async {
    try {
      final response = await _api.updateTourPackageStatus(
        id,
        status: _statusToString(status),
        rejectionReason: rejectionReason,
      );

      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Failed to update tour package status');
      }
    } catch (error) {
      print('Error in updateTourPackageStatus: $error');
      rethrow;
    }
  }

  String _statusToString(PackageStatus status) {
    switch (status) {
      case PackageStatus.published:
        return 'published';
      case PackageStatus.pending_approval:
        return 'pending_approval';
      case PackageStatus.rejected:
        return 'rejected';
    }
  }
}