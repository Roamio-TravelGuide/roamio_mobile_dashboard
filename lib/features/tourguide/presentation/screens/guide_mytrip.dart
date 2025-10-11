import 'package:flutter/material.dart';

class GuideMyTripsScreen extends StatefulWidget {
  const GuideMyTripsScreen({super.key});

  @override
  State<GuideMyTripsScreen> createState() => _GuideMyTripsScreenState();
}

class _GuideMyTripsScreenState extends State<GuideMyTripsScreen> {
  final List<TourTrip> _trips = [
    TourTrip(
      id: '1',
      title: 'Bali Cultural Tour',
      description: 'Explore the rich cultural heritage of Bali with traditional temple visits and local crafts',
      coverImage: 'https://images.unsplash.com/photo-1518548419970-58e3b4079ab2?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
      date: '2024-01-15',
      duration: '8 hours',
      price: '\$120',
      groupSize: 12,
      rating: 4.8,
      status: TripStatus.pending,
      bookings: 5,
    ),
    TourTrip(
      id: '2',
      title: 'Ubud Waterfall Adventure',
      description: 'Discover hidden waterfalls and lush jungles in the heart of Ubud',
      coverImage: 'https://images.unsplash.com/photo-1551632811-561732d1e306?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
      date: '2024-01-10',
      duration: '6 hours',
      price: '\$95',
      groupSize: 8,
      rating: 4.9,
      status: TripStatus.approved,
      bookings: 8,
    ),
    TourTrip(
      id: '3',
      title: 'Sunset Beach Tour',
      description: 'Experience breathtaking sunsets at Bali\'s most beautiful beaches',
      coverImage: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
      date: '2024-01-20',
      duration: '4 hours',
      price: '\$75',
      groupSize: 15,
      rating: 4.7,
      status: TripStatus.rejected,
      bookings: 0,
      rejectionReason: 'Insufficient safety documentation provided',
    ),
    TourTrip(
      id: '4',
      title: 'Traditional Cooking Class',
      description: 'Learn authentic Balinese cooking techniques with local chefs',
      coverImage: 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80',
      date: '2024-01-25',
      duration: '3 hours',
      price: '\$65',
      groupSize: 10,
      rating: 4.6,
      status: TripStatus.pending,
      bookings: 3,
    ),
  ];

  TripFilter _currentFilter = TripFilter.all;

  @override
  Widget build(BuildContext context) {
    final filteredTrips = _filterTrips(_trips, _currentFilter);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      body: Column(
        children: [
          // Header Section
          _buildHeaderSection(),
          
          // Filter Chips
          _buildFilterChips(),
          
          // Trips List
          Expanded(
            child: _buildTripsList(filteredTrips),
          ),
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
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1a1a2e).withOpacity(0.9),
            const Color(0xFF0D0D12).withOpacity(0.95),
          ],
        ),
      ),
      child: Stack(
        children: [
          const Center(
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
                shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: Colors.black.withOpacity(0.5),
                    offset: const Offset(1.0, 1.0),
                  ),
                ],
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
                label: Text(
                  _getFilterLabel(filter),
                  style: TextStyle(
                    color: _currentFilter == filter ? Colors.white : Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                selected: _currentFilter == filter,
                onSelected: (selected) {
                  setState(() {
                    _currentFilter = filter;
                  });
                },
                backgroundColor: const Color(0xFF1E1E2E),
                selectedColor: _getFilterColor(filter),
                checkmarkColor: Colors.white,
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

  Widget _buildTripsList(List<TourTrip> trips) {
    if (trips.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: trips.length,
      itemBuilder: (context, index) {
        final trip = trips[index];
        return _buildTripCard(trip, context);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getEmptyStateIcon(_currentFilter),
            color: Colors.white.withOpacity(0.5),
            size: 80,
          ),
          const SizedBox(height: 16),
          Text(
            _getEmptyStateMessage(_currentFilter),
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (_currentFilter == TripFilter.all)
            ElevatedButton(
              onPressed: _createNewTour,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Create Your First Tour'),
            ),
        ],
      ),
    );
  }

  Widget _buildTripCard(TourTrip trip, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image Area
            _buildCoverImageSection(trip),
            
            // Trip Details
            _buildTripDetailsSection(trip, context),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImageSection(TourTrip trip) {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D3E),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        image: DecorationImage(
          image: NetworkImage(trip.coverImage),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.5),
                ],
              ),
            ),
          ),
          
          // Status Badge
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

          // Bookings Count
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${trip.bookings}/${trip.groupSize}',
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

  Widget _buildTripDetailsSection(TourTrip trip, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Price
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
                trip.price,
                style: const TextStyle(
                  color: Color(0xFF6366F1),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Description
          Text(
            trip.description,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 12),

          // Trip Details Chips
          _buildDetailChips(trip),

          const SizedBox(height: 12),

          // Action Buttons
          _buildActionButtons(trip, context),
        ],
      ),
    );
  }

  Widget _buildDetailChips(TourTrip trip) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildDetailChip(Icons.calendar_today, _formatDate(trip.date)),
        _buildDetailChip(Icons.schedule, trip.duration),
        _buildDetailChip(Icons.star, trip.rating.toString()),
        _buildDetailChip(Icons.people, 'Max ${trip.groupSize}'),
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
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(TourTrip trip, BuildContext context) {
    switch (trip.status) {
      case TripStatus.approved:
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _manageTour(trip),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6366F1),
                  side: const BorderSide(color: Color(0xFF6366F1)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('View Bookings'),
              ),
            ),
          ],
        );
      
      case TripStatus.pending:
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _viewSubmissionStatus(trip),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              side: const BorderSide(color: Colors.orange),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('View Submission Status'),
          ),
        );
      
      case TripStatus.rejected:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reason: ${trip.rejectionReason ?? "No reason provided"}',
              style: TextStyle(
                color: Colors.red.withOpacity(0.8),
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _resubmitTour(trip),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Resubmit for Review'),
              ),
            ),
          ],
        );
    }
  }

  // Filter and Utility Methods
  List<TourTrip> _filterTrips(List<TourTrip> trips, TripFilter filter) {
    switch (filter) {
      case TripFilter.approved:
        return trips.where((trip) => trip.status == TripStatus.approved).toList();
      case TripFilter.pending:
        return trips.where((trip) => trip.status == TripStatus.pending).toList();
      case TripFilter.rejected:
        return trips.where((trip) => trip.status == TripStatus.rejected).toList();
      case TripFilter.all:
      default:
        return trips;
    }
  }

  String _getFilterLabel(TripFilter filter) {
    switch (filter) {
      case TripFilter.all:
        return 'All Tours';
      case TripFilter.approved:
        return 'Approved';
      case TripFilter.pending:
        return 'Pending';
      case TripFilter.rejected:
        return 'Rejected';
    }
  }

  Color _getFilterColor(TripFilter filter) {
    switch (filter) {
      case TripFilter.all:
        return const Color(0xFF6366F1);
      case TripFilter.approved:
        return Colors.green;
      case TripFilter.pending:
        return Colors.orange;
      case TripFilter.rejected:
        return Colors.red;
    }
  }

  Color _getStatusColor(TripStatus status) {
    switch (status) {
      case TripStatus.approved:
        return Colors.green;
      case TripStatus.pending:
        return Colors.orange;
      case TripStatus.rejected:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(TripStatus status) {
    switch (status) {
      case TripStatus.approved:
        return Icons.check_circle;
      case TripStatus.pending:
        return Icons.pending;
      case TripStatus.rejected:
        return Icons.cancel;
    }
  }

  String _getStatusText(TripStatus status) {
    switch (status) {
      case TripStatus.approved:
        return 'Approved';
      case TripStatus.pending:
        return 'Pending';
      case TripStatus.rejected:
        return 'Rejected';
    }
  }

  IconData _getEmptyStateIcon(TripFilter filter) {
    switch (filter) {
      case TripFilter.all:
        return Icons.travel_explore_outlined;
      case TripFilter.approved:
        return Icons.check_circle_outline;
      case TripFilter.pending:
        return Icons.pending_actions;
      case TripFilter.rejected:
        return Icons.cancel_outlined;
    }
  }

  String _getEmptyStateMessage(TripFilter filter) {
    switch (filter) {
      case TripFilter.all:
        return 'No tour submissions yet.\nCreate your first tour to get started!';
      case TripFilter.approved:
        return 'No approved tours yet.\nYour approved tours will appear here.';
      case TripFilter.pending:
        return 'No pending submissions.\nTours under review will appear here.';
      case TripFilter.rejected:
        return 'No rejected tours.\nResubmit rejected tours after making changes.';
    }
  }

  String _formatDate(String date) {
    final parts = date.split('-');
    if (parts.length == 3) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }
    return date;
  }

  // Action Methods
  void _manageTour(TourTrip trip) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Managing ${trip.title}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _viewBookings(TourTrip trip) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing bookings for ${trip.title}'),
        backgroundColor: const Color(0xFF6366F1),
      ),
    );
  }

  void _viewSubmissionStatus(TourTrip trip) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Checking submission status for ${trip.title}'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _resubmitTour(TourTrip trip) {
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

// Enums and Data Models
enum TripStatus {
  approved,
  pending,
  rejected,
}

enum TripFilter {
  all,
  approved,
  pending,
  rejected,
}

class TourTrip {
  final String id;
  final String title;
  final String description;
  final String coverImage;
  final String date;
  final String duration;
  final String price;
  final int groupSize;
  final double rating;
  final TripStatus status;
  final int bookings;
  final String? rejectionReason;

  const TourTrip({
    required this.id,
    required this.title,
    required this.description,
    required this.coverImage,
    required this.date,
    required this.duration,
    required this.price,
    required this.groupSize,
    required this.rating,
    required this.status,
    required this.bookings,
    this.rejectionReason,
  });
}