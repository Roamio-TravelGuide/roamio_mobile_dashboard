import 'package:flutter/material.dart';
import './tour_package_detail.dart';
import '../../../../core/services/tour_package_service.dart';
import '../../../../core/models/tour_package.dart';
import '../../api/tour_package_api.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/config/env_config.dart';
import '../../api/tour_package_api.dart';
import '../../../auth/api/auth_api.dart';

class GuideMyTripsScreen extends StatefulWidget {
  const GuideMyTripsScreen({super.key});

  @override
  State<GuideMyTripsScreen> createState() => _GuideMyTripsScreenState();
}

class _GuideMyTripsScreenState extends State<GuideMyTripsScreen> {
  late TourPackageService _tourPackageService;
  List<TourPackage> _trips = [];
  bool _isLoading = true;
  String _errorMessage = '';
  TripFilter _currentFilter = TripFilter.all;

  @override
  void initState() {
    super.initState();
    _initializeService();
    _loadTourPackages();
  }

  void _initializeService() {
    final apiClient = ApiClient(customBaseUrl: EnvConfig.baseUrl);
    final tourPackageApi = TourPackageApi(apiClient: apiClient);
    _tourPackageService = TourPackageService(api: tourPackageApi);
  }

  Future<void> _loadTourPackages() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final packages = await _tourPackageService.getTourPackagesByGuideId(
        status: _getStatusFilter(_currentFilter),
      );

      setState(() {
        _trips = packages;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  String? _getStatusFilter(TripFilter filter) {
    switch (filter) {
      case TripFilter.approved:
        return 'published';
      case TripFilter.pending:
        return 'pending_approval';
      case TripFilter.rejected:
        return 'rejected';
      case TripFilter.all:
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      body: Column(
        children: [
          _buildHeaderSection(),
          _buildFilterChips(),
          Expanded(child: _buildContent()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewTour,
        backgroundColor: const Color(0xFF6366F1),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1a1a2e).withOpacity(0.9),
            const Color(0xFF0D0D12).withOpacity(0.95),
          ],
        ),
      ),
      child: const Stack(
        children: [
          Center(
            child: Icon(
              Icons.travel_explore,
              color: Colors.white,
              size: 60,
            ),
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Text(
              'My Tour Submissions',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: TripFilter.values.map((filter) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(_getFilterLabel(filter)),
                selected: _currentFilter == filter,
                onSelected: (selected) {
                  setState(() {
                    _currentFilter = filter;
                  });
                  _loadTourPackages();
                },
                backgroundColor: const Color(0xFF1E1E2E),
                selectedColor: _getFilterColor(filter),
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: _currentFilter == filter ? Colors.white : Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Failed to load tours',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadTourPackages,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return _trips.isEmpty ? _buildEmptyState() : _buildTripsList();
  }

  Widget _buildTripsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _trips.length,
      itemBuilder: (context, index) {
        final trip = _trips[index];
        return _buildTripCard(trip, context);
      },
    );
  }

  Widget _buildTripCard(TourPackage trip, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          // In _buildTripCard method, update the onTap:
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TourPackageDetailScreen(tourPackageId: trip.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              _buildCoverImageSection(trip),
              _buildTripDetails(trip, context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverImageSection(TourPackage trip) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D3E),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        image: DecorationImage(
          image: NetworkImage(trip.coverImageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(trip.status).withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getStatusIcon(trip.status), color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    _getStatusText(trip.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripDetails(TourPackage trip, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  trip.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                trip.priceFormatted,
                style: const TextStyle(
                  color: Color(0xFF6366F1),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            trip.description ?? 'No description available',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          _buildDetailChips(trip),
          const SizedBox(height: 12),
          _buildActionButtons(trip, context),
        ],
      ),
    );
  }

  // ... (other helper methods remain the same as before)
  Widget _buildDetailChips(TourPackage trip) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildDetailChip(Icons.calendar_today, trip.formattedDate),
        _buildDetailChip(Icons.schedule, trip.durationFormatted),
        _buildDetailChip(Icons.star, trip.averageRating.toStringAsFixed(1)),
        _buildDetailChip(Icons.reviews, '${trip.reviewCount} reviews'),
      ],
    );
  }

  Widget _buildDetailChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white54, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(TourPackage trip, BuildContext context) {
    switch (trip.status) {
      case PackageStatus.published:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _manageTour(trip),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6366F1),
                  side: const BorderSide(color: Color(0xFF6366F1)),
                ),
                child: const Text('Manage Tour'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _viewBookings(trip),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                ),
                child: const Text('View Bookings'),
              ),
            ),
          ],
        );
      case PackageStatus.pending_approval:
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _viewSubmissionStatus(trip),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              side: const BorderSide(color: Colors.orange),
            ),
            child: const Text('View Submission Status'),
          ),
        );
      case PackageStatus.rejected:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reason: ${trip.rejectionReason ?? "No reason provided"}',
              style: const TextStyle(color: Colors.red, fontSize: 12),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _resubmitTour(trip),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                ),
                child: const Text('Resubmit for Review'),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getEmptyStateIcon(_currentFilter),
            color: Colors.white54,
            size: 80,
          ),
          const SizedBox(height: 16),
          Text(
            _getEmptyStateMessage(_currentFilter),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 20),
          if (_currentFilter == TripFilter.all)
            ElevatedButton(
              onPressed: _createNewTour,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
              ),
              child: const Text('Create Your First Tour'),
            ),
        ],
      ),
    );
  }

  // Utility methods
  String _getFilterLabel(TripFilter filter) {
    switch (filter) {
      case TripFilter.all: return 'All Tours';
      case TripFilter.approved: return 'Approved';
      case TripFilter.pending: return 'Pending';
      case TripFilter.rejected: return 'Rejected';
    }
  }

  Color _getFilterColor(TripFilter filter) {
    switch (filter) {
      case TripFilter.all: return const Color(0xFF6366F1);
      case TripFilter.approved: return Colors.green;
      case TripFilter.pending: return Colors.orange;
      case TripFilter.rejected: return Colors.red;
    }
  }

  Color _getStatusColor(PackageStatus status) {
    switch (status) {
      case PackageStatus.published: return Colors.green;
      case PackageStatus.pending_approval: return Colors.orange;
      case PackageStatus.rejected: return Colors.red;
    }
  }

  IconData _getStatusIcon(PackageStatus status) {
    switch (status) {
      case PackageStatus.published: return Icons.check_circle;
      case PackageStatus.pending_approval: return Icons.pending;
      case PackageStatus.rejected: return Icons.cancel;
    }
  }

  String _getStatusText(PackageStatus status) {
    switch (status) {
      case PackageStatus.published: return 'Approved';
      case PackageStatus.pending_approval: return 'Pending';
      case PackageStatus.rejected: return 'Rejected';
    }
  }

  IconData _getEmptyStateIcon(TripFilter filter) {
    switch (filter) {
      case TripFilter.all: return Icons.travel_explore_outlined;
      case TripFilter.approved: return Icons.check_circle_outline;
      case TripFilter.pending: return Icons.pending_actions;
      case TripFilter.rejected: return Icons.cancel_outlined;
    }
  }

  String _getEmptyStateMessage(TripFilter filter) {
    switch (filter) {
      case TripFilter.all: return 'No tour submissions yet.\nCreate your first tour to get started!';
      case TripFilter.approved: return 'No approved tours yet.\nYour approved tours will appear here.';
      case TripFilter.pending: return 'No pending submissions.\nTours under review will appear here.';
      case TripFilter.rejected: return 'No rejected tours.\nResubmit rejected tours after making changes.';
    }
  }

  // Action methods
  void _manageTour(TourPackage trip) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Managing ${trip.title}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _viewBookings(TourPackage trip) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing bookings for ${trip.title}'),
        backgroundColor: const Color(0xFF6366F1),
      ),
    );
  }

  void _viewSubmissionStatus(TourPackage trip) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Checking submission status for ${trip.title}'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _resubmitTour(TourPackage trip) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Resubmitting ${trip.title} for review'),
        backgroundColor: const Color(0xFF6366F1),
      ),
    );
  }

  void _createNewTour() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Creating new tour'),
        backgroundColor: Color(0xFF6366F1),
      ),
    );
  }
}

enum TripFilter { all, approved, pending, rejected }