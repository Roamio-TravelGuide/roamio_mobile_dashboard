import 'package:Roamio/core/config/env_config.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/models/destination.dart';
import '../../../../core/widgets/home/destination_card.dart';
import '../../../../core/widgets/home/search_bar.dart';
import '../../../../core/widgets/home/filter_screen.dart';
import '../../../../core/models/filter_options.dart';
import '../../api/traveller_api.dart';
import '../../../../core/api/api_client.dart';

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
  late TravellerApi travellerApi;
  late final ApiClient apiClient;
  List<Destination> tours = [];
  List<Destination> recommendedTours = [];
  List<Destination> recentTours = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    apiClient = ApiClient(customBaseUrl: EnvConfig.baseUrl);
    travellerApi = TravellerApi(apiClient: apiClient);
    _loadUserData();
    _loadTours();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName') ?? 'Guest';
      profilePictureUrl = prefs.getString('profilePictureUrl') ?? '';
    });
  }

  Future<void> _loadTours() async {
  try {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    print('Loading tours...');
    final response = await travellerApi.getTours(
      search: searchQuery.isNotEmpty ? searchQuery : null,
      location: filterOptions.location.isNotEmpty ? filterOptions.location : null,
      status: 'published'
    );

    if (response['success'] == true) {
      if (response['data'] != null && response['data']['packages'] != null) {
        final tourData = response['data']['packages'] as List<dynamic>;
        print('Found ${tourData.length} tours');
        
        // Convert API data to Destination objects
        List<Destination> allTours = tourData.map((tour) {
          // Use the actual cover image URL if available, otherwise use default
          String? imageUrl;
            if (tour['cover_image'] != null && tour['cover_image']['url'] != null) {
              imageUrl = tour['cover_image']['url'];
            }

          return Destination.withDefaults(
            id: tour['id']?.toString() ?? '',
            name: tour['title'] ?? 'Unknown Destination',
            image: imageUrl ?? '', // Use empty string if no cover image
            location: tour['location'] ?? 'Unknown Location',
            rating: (tour['averageRating'] as num?)?.toDouble() ?? 0.0,
            price: 'Rs. ${tour['price']?.toStringAsFixed(2) ?? '0'}',
            description: tour['description'] ?? '',
            isCompleted: false,
            downloadCount: (tour['downloadCount'] as num?)?.toInt() ?? 0,
            reviewCount: (tour['reviewCount'] as num?)?.toInt() ?? 0,
            createdAt: DateTime.parse(tour['created_at'] ?? DateTime.now().toString()),
          );
        }).toList();

        // Sort by recency for recent tours (most recent first) and take only 3
        final recentToursSorted = List<Destination>.from(allTours)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Sort by recommendation score for recommended tours and take top 10
        final recommendedToursSorted = List<Destination>.from(allTours)
          ..sort((a, b) {
            final aScore = (a.rating * 2) + (a.reviewCount * 0.5) + (a.downloadCount * 0.3);
            final bScore = (b.rating * 2) + (b.reviewCount * 0.5) + (b.downloadCount * 0.3);
            return bScore.compareTo(aScore);
          });

        setState(() {
          recentTours = recentToursSorted.take(3).toList(); // Only 3 recent tours
          recommendedTours = recommendedToursSorted.take(10).toList();
        });
      } else {
        print('Invalid data structure in response: $response');
        throw Exception('Invalid data structure from API');
      }
    } else {
      final errorMsg = response['message'] ?? 'Failed to load tours';
      print('API returned error: $errorMsg');
      throw Exception(errorMsg);
    }
  } catch (error) {
    print('Error in _loadTours: $error');
    setState(() {
      errorMessage = error.toString();
    });
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}

  String _getDefaultImage() {
    return 'https://images.unsplash.com/photo-1501785888041-af3ef285b470?q=80&w=1600&auto=format&fit=crop';
  }

  void _handleDestinationTap(Destination destination) {
    Navigator.pushNamed(
      context, 
      '/tour-details', 
      arguments: destination
    );
  }

  void _handleSearch(String query) {
    setState(() {
      searchQuery = query;
    });
    _loadTours();
  }

  void _handleFiltersChanged(FilterOptions newFilters) {
    setState(() {
      filterOptions = newFilters;
    });
    _loadTours();
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
    _loadTours();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: profilePictureUrl.isNotEmpty
                            ? NetworkImage(profilePictureUrl)
                            : const NetworkImage(
                                'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?q=80&w=100&auto=format&fit=crop',
                              ) as ImageProvider,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Hello, $userName!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Welcome Message
              const Text(
                'Where do you want to explore today?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 16),

              // Search and Filter
              Row(
                children: [
                  Expanded(
                    child: CustomSearchBar(
                      placeholder: 'Explore by destination',
                      onChanged: _handleSearch,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: _openFilterScreen,
                      icon: Icon(
                        Icons.filter_list,
                        color: filterOptions.hasActiveFilters ? Colors.blue : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Show active filters if any
              if (filterOptions.hasActiveFilters)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Active Filters:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (filterOptions.location.isNotEmpty)
                          Chip(
                            label: Text('Location: ${filterOptions.location}'),
                            backgroundColor: Colors.blue.withOpacity(0.2),
                            labelStyle: const TextStyle(color: Colors.white),
                          ),
                        if (filterOptions.selectedCategory.isNotEmpty)
                          Chip(
                            label: Text('Category: ${filterOptions.selectedCategory}'),
                            backgroundColor: Colors.blue.withOpacity(0.2),
                            labelStyle: const TextStyle(color: Colors.white),
                          ),
                        if (filterOptions.minPrice > 0)
                          Chip(
                            label: Text('Min: \$${filterOptions.minPrice.toStringAsFixed(2)}'),
                            backgroundColor: Colors.blue.withOpacity(0.2),
                            labelStyle: const TextStyle(color: Colors.white),
                          ),
                        if (filterOptions.maxPrice < 1000)
                          Chip(
                            label: Text('Max: \$${filterOptions.maxPrice.toStringAsFixed(2)}'),
                            backgroundColor: Colors.blue.withOpacity(0.2),
                            labelStyle: const TextStyle(color: Colors.white),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),

              const SizedBox(height: 24),

              // Loading and Error States
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (errorMessage.isNotEmpty && recentTours.isEmpty)
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Error: $errorMessage',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _retryLoading,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else if (recentTours.isEmpty)
                const Center(
                  child: Text(
                    'No tours available',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recent Tours Section (Horizontal Scroll)
                    const Text(
                      'Recent Tours',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 140, // Height for horizontal recent cards
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: recentTours.length,
                        itemBuilder: (context, index) {
                          final tour = recentTours[index];
                          return Container(
                            width: MediaQuery.of(context).size.width * 0.8,
                            margin: EdgeInsets.only(
                              right: index == recentTours.length - 1 ? 0 : 12,
                            ),
                            child: DestinationCard(
                              destination: tour,
                              onTap: () => _handleDestinationTap(tour),
                              isRecentTrip: true, // Use recent trip card style
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Recommended Tours Section (Vertical List)
                    const Text(
                      'Recommended Tours',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Recommended tours in vertical list
                    ...recommendedTours.map((tour) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: DestinationCard(
                          destination: tour,
                          onTap: () => _handleDestinationTap(tour),
                          // isRecentTrip is false by default, so it uses popular destination style
                        ),
                      );
                    }).toList(),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}