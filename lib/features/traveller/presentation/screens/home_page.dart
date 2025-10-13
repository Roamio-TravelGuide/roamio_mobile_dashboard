import 'package:Roamio/core/config/env_config.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/models/destination.dart';
import '../../../../core/widgets/home/destination_card.dart';
import '../../../../core/widgets/home/search_bar.dart';
import '../../../../core/widgets/home/filter_screen.dart';
import '../../../../core/models/filter_options.dart';
import '../../api/dashboard_api.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/media_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String searchQuery = '';
  FilterOptions filterOptions = FilterOptions();
  String userName = 'Unknown Guest';
  String profilePictureUrl = '';
  
  // API client and state management
  late DashboardApi dashboardApi;
  late final ApiClient apiClient;
  
  // Separate loading states for better UX
  bool isLoading = true;
  bool isLoadingLocation = false;
  bool isLoadingNearby = false;
  bool isLoadingRecent = false;
  bool isLoadingTrending = false;
  bool isLoadingRecommended = false;
  
  String errorMessage = '';
  
  // Tour lists
  List<Destination> nearbyTours = [];
  List<Destination> recentTours = [];
  List<Destination> trendingTours = [];
  List<Destination> recommendedTours = [];
  
  // Location
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    apiClient = ApiClient(customBaseUrl: EnvConfig.baseUrl);
    dashboardApi = DashboardApi(apiClient: apiClient);
    _loadUserData();
    _getCurrentLocationAndLoadTours();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName') ?? 'Guest';
      profilePictureUrl = prefs.getString('profilePictureUrl') ?? '';
    });
  }

  Future<void> _getCurrentLocationAndLoadTours() async {
    setState(() {
      isLoadingLocation = true;
      isLoading = true;
      errorMessage = '';
    });

    try {
      final location = await LocationService.getCurrentLatLng();
      if (location != null && mounted) {
        setState(() {
          _currentLocation = location;
        });
      }
      
      await _loadAllTourCategories();
    } catch (error) {
      print('Error getting location: $error');
      setState(() {
        errorMessage = 'Failed to get location: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoadingLocation = false;
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadAllTourCategories() async {
    try {
      await Future.wait([
        _loadNearbyTours(),
        _loadRecentTours(),
        _loadTrendingTours(),
        _loadRecommendedTours(),
      ]);
    } catch (error) {
      print('Error loading tour categories: $error');
      setState(() {
        errorMessage = 'Failed to load tours: $error';
      });
    }
  }

  Future<void> _loadNearbyTours() async {
    if (_currentLocation == null) {
      setState(() {
        nearbyTours = [];
        isLoadingNearby = false;
      });
      return;
    }

    setState(() { isLoadingNearby = true; });

    try {
      final response = await dashboardApi.getPackagesByLocation(
        latitude: _currentLocation!.latitude,
        longitude: _currentLocation!.longitude,
        radiusKm: 50,
        limit: 4,
      );

      if (response['success'] == true) {
        final tours = _convertApiResponseToDestinations(response['data'] ?? []);
        setState(() { nearbyTours = tours; });
      }
    } catch (error) {
      print('Error loading nearby tours: $error');
    } finally {
      setState(() { isLoadingNearby = false; });
    }
  }

  Future<void> _loadRecentTours() async {
    setState(() { isLoadingRecent = true; });

    try {
      final response = await dashboardApi.getRecentTours(limit: 3, days: 30);
      if (response['success'] == true) {
        final tours = _convertApiResponseToDestinations(response['data'] ?? []);
        setState(() { recentTours = tours; });
      }
    } catch (error) {
      print('Error loading recent tours: $error');
    } finally {
      setState(() { isLoadingRecent = false; });
    }
  }

  Future<void> _loadTrendingTours() async {
    setState(() { isLoadingTrending = true; });

    try {
      final response = await dashboardApi.getTrendingTours(limit: 4, period: 'week');
      if (response['success'] == true) {
        final tours = _convertApiResponseToDestinations(response['data'] ?? []);
        setState(() { trendingTours = tours; });
      }
    } catch (error) {
      print('Error loading trending tours: $error');
    } finally {
      setState(() { isLoadingTrending = false; });
    }
  }

  Future<void> _loadRecommendedTours() async {
    setState(() { isLoadingRecommended = true; });

    try {
      final response = await dashboardApi.getRecommendedTours(limit: 6);
      if (response['success'] == true) {
        final tours = _convertApiResponseToDestinations(response['data'] ?? []);
        setState(() { recommendedTours = tours; });
      }
    } catch (error) {
      print('Error loading recommended tours: $error');
    } finally {
      setState(() { isLoadingRecommended = false; });
    }
  }

  List<Destination> _convertApiResponseToDestinations(List<dynamic> tourData) {
    return tourData.map((tour) {
      String? imageUrl;
      if (tour['cover_image'] != null && tour['cover_image']['url'] != null) {
        imageUrl = MediaService.getCoverImageUrl(tour['cover_image']['url']);
      }

      double? tourLat;
      double? tourLng;
      if (tour['tour_stops'] != null && tour['tour_stops'] is List && tour['tour_stops'].isNotEmpty) {
        final firstStop = tour['tour_stops'][0];
        if (firstStop['location'] != null) {
          tourLat = firstStop['location']['latitude']?.toDouble();
          tourLng = firstStop['location']['longitude']?.toDouble();
        }
      }

      return Destination.withDefaults(
        id: tour['id']?.toString() ?? '',
        name: tour['title'] ?? 'Unknown Destination',
        image: imageUrl ?? '',
        location: tour['location'] ?? 'Unknown Location',
        rating: (tour['averageRating'] as num?)?.toDouble() ?? 0.0,
        price: 'Rs. ${tour['price']?.toStringAsFixed(2) ?? '0'}',
        description: tour['description'] ?? '',
        isCompleted: false,
        downloadCount: (tour['downloadCount'] as num?)?.toInt() ?? 0,
        reviewCount: (tour['reviewCount'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.parse(tour['created_at'] ?? DateTime.now().toString()),
        latitude: tourLat,
        longitude: tourLng,
      );
    }).toList();
  }

  void _handleDestinationTap(Destination destination) {
    Navigator.pushNamed(context, '/tour-details', arguments: destination);
  }

  void _handleSearch(String query) {
    setState(() { searchQuery = query; });
  }

  void _handleFiltersChanged(FilterOptions newFilters) {
    setState(() { filterOptions = newFilters; });
    _getCurrentLocationAndLoadTours();
  }

  void _openFilterScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FilterScreen(
          initialFilters: filterOptions,
          onFiltersApplied: _handleFiltersChanged,
        ),
      ),
    );
  }

  void _retryLoading() {
    _getCurrentLocationAndLoadTours();
  }

  void _refreshData() {
    _getCurrentLocationAndLoadTours();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      body: SafeArea(
        child: RefreshIndicator(
          backgroundColor: const Color(0xFF0D0D12),
          color: Colors.blue,
          onRefresh: () async => _refreshData(),
          child: CustomScrollView(
            slivers: [
              // Header Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      const Text(
                        'Where do you want to explore today?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildSearchFilterRow(),
                      const SizedBox(height: 8),
                      if (filterOptions.hasActiveFilters) _buildActiveFilters(),
                    ],
                  ),
                ),
              ),

              // Main Content
              if (isLoading) _buildLoadingSliver(),
              if (errorMessage.isNotEmpty && _hasNoTours()) _buildErrorSliver(),
              if (_hasNoTours() && !isLoading) _buildEmptySliver(),
              if (!isLoading && !_hasNoTours()) _buildContentSlivers(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                image: profilePictureUrl.isNotEmpty ? DecorationImage(
                  image: NetworkImage(MediaService.getProfilePictureUrl(profilePictureUrl)),
                  fit: BoxFit.cover,
                ) : null,
              ),
              child: profilePictureUrl.isEmpty ? const Icon(
                Icons.person,
                color: Colors.white,
                size: 20,
              ) : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $userName!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (_currentLocation != null)
                  Text(
                    '📍 Nearby tours available',
                    style: TextStyle(
                      color: Colors.green.shade400,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: _refreshData,
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchFilterRow() {
    return Row(
      children: [
        Expanded(
          child: CustomSearchBar(
            placeholder: 'Search destinations, tours...',
            onChanged: _handleSearch,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: filterOptions.hasActiveFilters
                  ? [Colors.blue.shade500, Colors.blue.shade700]
                  : [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: _openFilterScreen,
            icon: Icon(
              Icons.filter_list_rounded,
              color: filterOptions.hasActiveFilters ? Colors.white : Colors.white70,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveFilters() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (filterOptions.location.isNotEmpty)
            _buildFilterChip('📍 ${filterOptions.location}'),
          if (filterOptions.selectedCategory.isNotEmpty)
            _buildFilterChip('🏷️ ${filterOptions.selectedCategory}'),
          if (filterOptions.minPrice > 0)
            _buildFilterChip('💰 Min: \$${filterOptions.minPrice.toStringAsFixed(0)}'),
          if (filterOptions.maxPrice < 1000)
            _buildFilterChip('💵 Max: \$${filterOptions.maxPrice.toStringAsFixed(0)}'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.blue,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // In your home_page.dart, update the _buildContentSlivers method:

SliverList _buildContentSlivers() {
  return SliverList(
    delegate: SliverChildListDelegate([
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nearby Tours Section - Use Standard Cards
            if (nearbyTours.isNotEmpty && _currentLocation != null) ...[
              _buildSectionHeader(
                Icons.near_me,
                'Tours Near You',
                'Based on your current location',
                isLoadingNearby,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 320,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: nearbyTours.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final tour = nearbyTours[index];
                    return SizedBox(
                      width: 300,
                      child: DestinationCard(
                        destination: tour,
                        onTap: () => _handleDestinationTap(tour),
                        cardType: CardType.standard,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
            ],

            // Recent Tours Section - Use Horizontal Cards
            if (recentTours.isNotEmpty) ...[
              _buildSectionHeader(
                Icons.access_time_filled,
                'Recent Tours',
                'Latest additions to our collection',
                isLoadingRecent,
              ),
              const SizedBox(height: 16),
              ...recentTours.map((tour) => DestinationCard(
                destination: tour,
                onTap: () => _handleDestinationTap(tour),
                cardType: CardType.horizontal,
              )).toList(),
              const SizedBox(height: 32),
            ],

            // Trending Tours Section - Use Compact Cards
            if (trendingTours.isNotEmpty) ...[
              _buildSectionHeader(
                Icons.trending_up_rounded,
                'Trending Now',
                'Most popular tours this week',
                isLoadingTrending,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: trendingTours.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final tour = trendingTours[index];
                    return DestinationCard(
                      destination: tour,
                      onTap: () => _handleDestinationTap(tour),
                      cardType: CardType.compact,
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
            ],

            // Recommended Tours Section - Use Standard Cards
            if (recommendedTours.isNotEmpty) ...[
              _buildSectionHeader(
                Icons.star_rounded,
                'Recommended For You',
                'Curated based on your preferences',
                isLoadingRecommended,
              ),
              const SizedBox(height: 16),
              ...recommendedTours.map((tour) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: DestinationCard(
                  destination: tour,
                  onTap: () => _handleDestinationTap(tour),
                  cardType: CardType.standard,
                ),
              )).toList(),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    ]),
  );
}

  Widget _buildSectionHeader(IconData icon, String title, String subtitle, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade500, Colors.blue.shade700],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (isLoading) ...[
              const SizedBox(width: 12),
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  SliverFillRemaining _buildLoadingSliver() {
    return const SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'Finding amazing tours for you...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  SliverFillRemaining _buildErrorSliver() {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline, color: Colors.red, size: 48),
              ),
              const SizedBox(height: 16),
              Text(
                'Oops! Something went wrong',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage,
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _retryLoading,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverFillRemaining _buildEmptySliver() {
    return const SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.travel_explore, color: Colors.grey, size: 80),
              SizedBox(height: 16),
              Text(
                'No Tours Available',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                'Check back later for new adventures',
                style: TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasNoTours() {
    return nearbyTours.isEmpty && recentTours.isEmpty && trendingTours.isEmpty && recommendedTours.isEmpty;
  }
}