import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/models/tour_package.dart';
import '../../../../core/services/tour_package_service.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/config/env_config.dart';
import '../../api/tour_package_api.dart';
import '../../../../core/widgets/tour_stop_card.dart';
import '../../../../core/widgets/tour_route_map.dart';
import '../../../../core/widgets/tour_stop_map.dart';

class TourPackageDetailScreen extends StatefulWidget {
  final int tourPackageId;

  const TourPackageDetailScreen({super.key, required this.tourPackageId});

  @override
  State<TourPackageDetailScreen> createState() => _TourPackageDetailScreenState();
}

class _TourPackageDetailScreenState extends State<TourPackageDetailScreen> {
  late Future<TourPackage> _tourPackageFuture;
  bool _isLoading = false;
  late TourPackageService _tourPackageService;
  int? _expandedStopIndex;

  @override
  void initState() {
    super.initState();
    _initializeService();
    _loadTourPackage();
  }

  void _initializeService() {
    final apiClient = ApiClient(customBaseUrl: EnvConfig.baseUrl);
    final tourPackageApi = TourPackageApi(apiClient: apiClient);
    _tourPackageService = TourPackageService(api: tourPackageApi);
  }

  void _loadTourPackage() {
    setState(() {
      _tourPackageFuture = _tourPackageService.getTourPackageById(widget.tourPackageId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      body: FutureBuilder<TourPackage>(
        future: _tourPackageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          if (!snapshot.hasData) {
            return _buildEmptyState();
          }

          final tourPackage = snapshot.data!;
          return _buildTourPackageDetail(tourPackage);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          Text(
            'Failed to load tour package',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadTourPackage,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.travel_explore, color: Colors.white54, size: 64),
          const SizedBox(height: 16),
          Text(
            'Tour package not found',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTourPackageDetail(TourPackage tourPackage) {
    return CustomScrollView(
      slivers: [
        _buildAppBar(tourPackage),
        _buildContent(tourPackage),
      ],
    );
  }

  SliverAppBar _buildAppBar(TourPackage tourPackage) {
    return SliverAppBar(
      expandedHeight: 300,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              tourPackage.coverImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFF1E1E2E),
                  child: const Icon(Icons.photo, color: Colors.white54, size: 64),
                );
              },
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        if (tourPackage.status == PackageStatus.published)
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit, color: Colors.white),
            ),
            onPressed: () => _editTourPackage(tourPackage),
          ),
      ],
    );
  }

  SliverToBoxAdapter _buildContent(TourPackage tourPackage) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusBadge(tourPackage.status),
            const SizedBox(height: 16),
            _buildTitleSection(tourPackage),
            const SizedBox(height: 16),
            _buildDescriptionSection(tourPackage),
            const SizedBox(height: 24),
            _buildTourDetailsSection(tourPackage),
            const SizedBox(height: 24),
            _buildGuideSection(tourPackage.guide),
            const SizedBox(height: 24),
            _buildTourStopsSection(tourPackage.tourStops),
            const SizedBox(height: 24),
            _buildActionButtons(tourPackage),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection(TourPackage tourPackage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and Price
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                tourPackage.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              tourPackage.priceFormatted,
              style: const TextStyle(
                color: Color(0xFF6366F1),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Rating and Duration
        Row(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 20),
            const SizedBox(width: 4),
            Text(
              tourPackage.averageRating.toStringAsFixed(1),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(${tourPackage.reviewCount} reviews)',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 16),
            const Icon(Icons.schedule, color: Colors.white54, size: 18),
            const SizedBox(width: 4),
            Text(
              tourPackage.durationFormatted,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(TourPackage tourPackage) {
    return Text(
      tourPackage.description ?? 'No description available',
      style: TextStyle(
        color: Colors.white.withOpacity(0.8),
        fontSize: 16,
        height: 1.5,
      ),
    );
  }

  Widget _buildTourDetailsSection(TourPackage tourPackage) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tour Details',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _buildDetailItem(Icons.download, 'Downloads', '${tourPackage.downloadCount}'),
              _buildDetailItem(Icons.calendar_today, 'Created', 
                DateFormat('MMM dd, yyyy').format(tourPackage.createdAt)),
              if (tourPackage.updatedAt != null)
                _buildDetailItem(Icons.update, 'Last Updated', 
                  DateFormat('MMM dd, yyyy').format(tourPackage.updatedAt!)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white54, size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(PackageStatus status) {
    final (backgroundColor, statusText) = _getStatusInfo(status);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: backgroundColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(status), color: backgroundColor, size: 16),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              color: backgroundColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  (Color, String) _getStatusInfo(PackageStatus status) {
    switch (status) {
      case PackageStatus.published:
        return (Colors.green, 'Published');
      case PackageStatus.pending_approval:
        return (Colors.orange, 'Pending Approval');
      case PackageStatus.rejected:
        return (Colors.red, 'Rejected');
    }
  }

  IconData _getStatusIcon(PackageStatus status) {
    switch (status) {
      case PackageStatus.published:
        return Icons.check_circle;
      case PackageStatus.pending_approval:
        return Icons.pending;
      case PackageStatus.rejected:
        return Icons.cancel;
    }
  }

  Widget _buildGuideSection(TravelGuide guide) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About Your Guide',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(guide.user.profilePictureUrlFormatted),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guide.user.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (guide.yearsOfExperience != null) ...[
                      Text(
                        '${guide.yearsOfExperience} years of experience',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (guide.languagesSpoken.isNotEmpty) ...[
                      Text(
                        'Languages: ${guide.languagesSpoken.join(', ')}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      guide.user.bio ?? 'No bio available',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTourStopsSection(List<TourStop> tourStops) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tour Route & Stops',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildFullRouteMap(tourStops),
        const SizedBox(height: 24),
        const Text(
          'Tour Stops',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        tourStops.isEmpty ? _buildEmptyStopsState() : _buildStopsList(tourStops),
      ],
    );
  }

  Widget _buildFullRouteMap(List<TourStop> tourStops) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Complete Route',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: TourRouteMap(
              tourStops: tourStops,
              showRouteLine: true,
              onStopTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tap on individual stops below for details'),
                    backgroundColor: Color(0xFF6366F1),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStopsList(List<TourStop> tourStops) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: tourStops.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return TourStopCard(
          stop: tourStops[index],
          index: index,
          isExpanded: _expandedStopIndex == index,
          onTap: () {
            setState(() {
              _expandedStopIndex = _expandedStopIndex == index ? null : index;
            });
          },
          onMapTap: () => _showStopMapFullScreen(tourStops[index], index),
        );
      },
    );
  }

  Widget _buildEmptyStopsState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          'No tour stops added yet',
          style: TextStyle(color: Colors.white54),
        ),
      ),
    );
  }

  void _showStopMapFullScreen(TourStop stop, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D0D12),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E1E2E),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${index + 1}. ${stop.stopName}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TourStopMap(
                  stopLocation: stop.location!,
                  stopName: stop.stopName,
                  stopNumber: index + 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(TourPackage tourPackage) {
    switch (tourPackage.status) {
      case PackageStatus.published:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _manageBookings(tourPackage),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6366F1),
                  side: const BorderSide(color: Color(0xFF6366F1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Manage Bookings'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _editTourPackage(tourPackage),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Edit Tour'),
              ),
            ),
          ],
        );

      case PackageStatus.pending_approval:
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _viewSubmissionStatus,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              side: const BorderSide(color: Colors.orange),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('View Submission Status'),
          ),
        );

      case PackageStatus.rejected:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rejection Reason:',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tourPackage.rejectionReason ?? 'No reason provided',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _resubmitTourPackage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Resubmit for Review'),
              ),
            ),
          ],
        );
    }
  }

  void _editTourPackage(TourPackage tourPackage) {
    Navigator.pushNamed(
      context,
      '/guide/edit-tour-package',
      arguments: tourPackage.id,
    );
  }

  void _manageBookings(TourPackage tourPackage) {
    Navigator.pushNamed(
      context,
      '/guide/tour-bookings',
      arguments: tourPackage.id,
    );
  }

  void _viewSubmissionStatus() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Viewing submission status'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _resubmitTourPackage() async {
    setState(() => _isLoading = true);
    try {
      await _tourPackageService.updateTourPackageStatus(
        widget.tourPackageId,
        status: PackageStatus.pending_approval,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tour package resubmitted for review'),
          backgroundColor: Colors.green,
        ),
      );
      _loadTourPackage();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to resubmit: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}