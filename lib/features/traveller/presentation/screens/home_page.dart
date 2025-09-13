import 'package:flutter/material.dart';
import '../../../../core/models/destination.dart';
import '../../../../core/widgets/home/destination_card.dart';
import '../../../../core/widgets/home/search_bar.dart';
import '../../../../core/widgets/home/category_card.dart';
import '../../../../core/widgets/home/filter_screen.dart';
import '../../../../core/models/filter_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String searchQuery = '';
  FilterOptions filterOptions = FilterOptions();
  String userName = 'Guest'; // Default name
  String profilePictureUrl = ''; // Default empty URL

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName') ?? 'Guest';
      profilePictureUrl = prefs.getString('profilePictureUrl') ?? '';
    });
  }

  final List<Destination> featuredDestinations = [
    const Destination(
      name: 'Raja Ampat Islands',
      image: 'https://images.unsplash.com/photo-1501785888041-af3ef285b470?q=80&w=1600&auto=format&fit=crop',
      location: 'West Papua',
      rating: 4.9,
      price: '\$235.00',
      isCompleted: true,
      completedDate: 'March 30, 2025',
    ),
    const Destination(
      name: 'Tanah Lot Temple',
      image: 'https://images.unsplash.com/photo-1596436889106-be35e8435c76?q=80&w=1600&auto=format&fit=crop',
      location: 'Tabanan, South Kuta, Badung Regency, Bali',
      rating: 4.7,
      price: '\$15',
    ),
    const Destination(
      name: 'Borobudur Temple',
      image: 'https://images.unsplash.com/photo-1587334274527-33b5d72dd3ff?q=80&w=1600&auto=format&fit=crop',
      location: 'Borobudur, South Kuta, Badung Regency, Bali',
      rating: 4.7,
      price: '\$15',
    ),
  ];

  final List<Category> categories = [
    const Category(icon: Icons.waves, name: 'Beaches'),
    const Category(icon: Icons.terrain, name: 'Mountains'),
    const Category(icon: Icons.account_balance, name: 'Cultural'),
    const Category(icon: Icons.explore, name: 'Adventure'),
    const Category(icon: Icons.restaurant, name: 'Food'),
  ];

  void _handleDestinationTap() {
    Navigator.pushNamed(context, '/traveller');
  }

  void _handleSearch(String query) {
    setState(() {
      searchQuery = query;
    });
  }

  void _handleFiltersChanged(FilterOptions newFilters) {
    setState(() {
      filterOptions = newFilters;
    });
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

  // Add this method to filter destinations based on current filters
  List<Destination> get filteredDestinations {
    return featuredDestinations.where((destination) {
      // Filter by category if selected
      if (filterOptions.selectedCategory.isNotEmpty) {
        // You'll need to add a 'category' field to your Destination model
        // or implement your own logic here
        // if (destination.category != filterOptions.selectedCategory) return false;
      }
      
      // Filter by price if set - FIXED null safety issue
      final destinationPrice = double.tryParse(destination.price?.replaceAll('\$', '') ?? '0') ?? 0;
      if (destinationPrice < filterOptions.minPrice || 
          destinationPrice > filterOptions.maxPrice) {
        return false;
      }
      
      // Filter by search query
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        if (!destination.name.toLowerCase().contains(query) &&
            !destination.location.toLowerCase().contains(query)) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final destinationsToShow = filteredDestinations;
    
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header - UPDATED to use user data
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

              // Search Bar - Updated to include filter functionality
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

              // Recent Trip Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Trip',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'See All',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Recent Trip Card - Horizontal layout
              DestinationCard(
                destination: featuredDestinations[0],
                onTap: _handleDestinationTap,
                isRecentTrip: true,
              ),

              const SizedBox(height: 24),
              
              // Popular Destinations Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Popular Destinations',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'See All',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Popular Destinations List - Updated to use filtered destinations
              ...destinationsToShow.skip(1).map((destination) {
                return DestinationCard(
                  destination: destination,
                  onTap: _handleDestinationTap,
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}