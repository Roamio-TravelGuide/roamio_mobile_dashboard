import 'package:flutter/material.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/config/env_config.dart';
import '../../api/traveller_api.dart';
import '../../../tourguide/api/tour_package_api.dart';
import './hiddengem_detail_page.dart';

class HiddenGemsListScreen extends StatefulWidget {
  const HiddenGemsListScreen({Key? key}) : super(key: key);

  @override
  State<HiddenGemsListScreen> createState() => _HiddenGemsListScreenState();
}

class _HiddenGemsListScreenState extends State<HiddenGemsListScreen> {
  List<Map<String, dynamic>> hiddenGems = [];
  bool isLoading = true;
  String selectedStatus = 'all';
  int currentPage = 1;
  int totalPages = 1;
  int totalCount = 0;
  late TravellerApi travellerApi;
  String? userId;
  // Status filters
  final List<Map<String, dynamic>> statusFilters = [
    {'value': 'all', 'label': 'All', 'count': 0},
    {'value': 'pending', 'label': 'Pending', 'count': 0},
    {'value': 'approved', 'label': 'Approved', 'count': 0},
    {'value': 'rejected', 'label': 'Rejected', 'count': 0},
    {'value': 'draft', 'label': 'Draft', 'count': 0},
  ];

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient(customBaseUrl: EnvConfig.baseUrl);
    travellerApi = TravellerApi(apiClient: apiClient);
    _getUserId(); // Get user ID first
  }

  Future<void> _getUserId() async {
  try {
    final apiClient = ApiClient(customBaseUrl: EnvConfig.baseUrl);
    final tourPackageApi = TourPackageApi(apiClient: apiClient);
    
    final userId = await tourPackageApi.getGuideId();
    
    if (userId != null) {
      setState(() {
        this.userId = userId.toString();
      });
      await _loadHiddenGems();
      await _loadStats();
    } else {
      _showSnackBar('User not found', isError: true);
    }
  } catch (error) {
    print('Error getting user ID: $error');
    _showSnackBar('Failed to get user information', isError: true);
  }
}

  Future<void> _loadHiddenGems() async {
  if (userId == null) return;
  
  if (mounted) {
    setState(() {
      isLoading = true;
    });
  }

  try {
    final response = await travellerApi.getMyHiddenGems(
      travelerId: userId!, // Pass the user ID as travelerId
      status: selectedStatus,
      page: currentPage,
      limit: 10,
    );

    if (response['success'] == true) {
      final data = response['data'] as List;
      final pagination = response['pagination'] ?? {};
      
      if (mounted) {
        setState(() {
          hiddenGems = List<Map<String, dynamic>>.from(data);
          totalCount = pagination['totalCount'] ?? 0;
          totalPages = pagination['totalPages'] ?? 1;
          currentPage = pagination['currentPage'] ?? 1;
          isLoading = false;
        });
      }
    } else {
      throw Exception('Failed to load hidden gems');
    }
  } catch (error) {
    print('Error loading hidden gems: $error');
    if (mounted) {
      setState(() {
        isLoading = false;
      });
      _showSnackBar('Failed to load hidden gems', isError: true);
    }
  }
}

  Future<void> _loadStats() async {
  if (userId == null) return;
  
  try {
    final response = await travellerApi.getMyHiddenGemsStats(travelerId: userId!);
    if (response['success'] == true) {
      final stats = response['data'];
      if (mounted) {
        setState(() {
          statusFilters[0]['count'] = stats['total'] ?? 0;
          statusFilters[1]['count'] = stats['pending'] ?? 0;
          statusFilters[2]['count'] = stats['approved'] ?? 0;
          statusFilters[3]['count'] = stats['rejected'] ?? 0;
          statusFilters[4]['count'] = stats['draft'] ?? 0;
        });
      }
    }
  } catch (error) {
    print('Failed to load stats: $error');
  }
}

  Future<void> _deleteHiddenGem(int gemId) async {
    try {
      final response = await travellerApi.deleteHiddenGem(gemId);
      
      if (response['success'] == true) {
        _showSnackBar('Hidden gem deleted successfully');
        _loadHiddenGems();
        _loadStats();
      } else {
        throw Exception('Failed to delete hidden gem');
      }
    } catch (error) {
      print('Error deleting hidden gem: $error');
      _showSnackBar('Failed to delete hidden gem: $error', isError: true);
    }
  }

  void _showDeleteDialog(Map<String, dynamic> gem) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Delete Hidden Gem',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Are you sure you want to delete "${gem['title']}"?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteHiddenGem(gem['id']);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      case 'pending': return Colors.orange;
      case 'draft': return Colors.blue;
      default: return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'approved': return 'Approved';
      case 'rejected': return 'Rejected';
      case 'pending': return 'Pending Review';
      case 'draft': return 'Draft';
      default: return status;
    }
  }

  void _viewHiddenGemDetails(Map<String, dynamic> gem) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => HiddenGemDetailsScreen(hiddenGem: gem),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D12),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Hidden Gems',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: userId == null 
          ? _buildLoadingState()
          : Column(
              children: [
                // Status Filter
                _buildStatusFilter(),
                
                // Statistics
                _buildStatistics(),
                
                // Gems List
                Expanded(
                  child: isLoading ? _buildLoadingState() : _buildGemsList(),
                ),
              ],
            ),
    );
  }

  // ... rest of your UI widgets remain the same
  Widget _buildStatusFilter() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: statusFilters.length,
        itemBuilder: (context, index) {
          final filter = statusFilters[index];
          final isSelected = selectedStatus == filter['value'];
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text('${filter['label']} (${filter['count']})'),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  selectedStatus = filter['value'];
                  currentPage = 1;
                });
                _loadHiddenGems();
              },
              backgroundColor: const Color(0xFF2A2A2A),
              selectedColor: Colors.blue.withOpacity(0.3),
              labelStyle: TextStyle(
                color: isSelected ? Colors.blue : Colors.white,
              ),
              checkmarkColor: Colors.blue,
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatistics() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', statusFilters[0]['count'], Colors.blue),
          _buildStatItem('Pending', statusFilters[1]['count'], Colors.orange),
          _buildStatItem('Approved', statusFilters[2]['count'], Colors.green),
          _buildStatItem('Rejected', statusFilters[3]['count'], Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: Colors.blue,
      ),
    );
  }

  Widget _buildGemsList() {
    if (hiddenGems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.assignment_turned_in,
              color: Colors.white54,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'No ${selectedStatus == 'all' ? '' : selectedStatus} hidden gems found',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start adding your hidden gems!',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: hiddenGems.length,
      itemBuilder: (context, index) {
        final gem = hiddenGems[index];
        return _buildGemCard(gem);
      },
    );
  }

  Widget _buildGemCard(Map<String, dynamic> gem) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _getStatusColor(gem['status']).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getStatusColor(gem['status']),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _getStatusLabel(gem['status']),
                  style: TextStyle(
                    color: _getStatusColor(gem['status']),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  'ID: ${gem['id']}',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Image
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            gem['title'] ?? 'Untitled',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (gem['location'] != null)
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.white54,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    gem['location']['address'] ?? 'No address',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    if (gem['picture'] != null && gem['picture']['url'] != null)
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(gem['picture']['url']),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Description
                if (gem['description'] != null)
                  Text(
                    gem['description'],
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                const SizedBox(height: 12),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _viewHiddenGemDetails(gem),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.withOpacity(0.2),
                          foregroundColor: Colors.blue,
                        ),
                        child: const Text('View Details'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Only show delete button for rejected gems
                    if (gem['status'] == 'rejected')
                      ElevatedButton(
                        onPressed: () => _showDeleteDialog(gem),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.2),
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Delete'),
                      ),
                  ],
                ),

                // Rejection Reason
                if (gem['status'] == 'rejected' && gem['rejection_reason'] != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Rejection Reason: ${gem['rejection_reason']}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}