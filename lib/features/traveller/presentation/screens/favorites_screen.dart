import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../../core/api/api_client.dart';
import '../../../../core/config/env_config.dart';

class HiddenGemsStatusScreen extends StatefulWidget {
  const HiddenGemsStatusScreen({Key? key}) : super(key: key);

  @override
  State<HiddenGemsStatusScreen> createState() => _HiddenGemsStatusScreenState();
}

class _HiddenGemsStatusScreenState extends State<HiddenGemsStatusScreen> {
  List<Map<String, dynamic>> hiddenGems = [];
  bool isLoading = true;
  bool isLoadingStats = true;
  String selectedStatus = 'pending';
  String searchQuery = '';
  int currentPage = 1;
  int totalPages = 1;
  int totalCount = 0;
  late ApiClient apiClient;

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
    apiClient = ApiClient(customBaseUrl: EnvConfig.baseUrl);
    _loadHiddenGems();
    _loadModerationStats();
  }

  Future<void> _loadHiddenGems() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final Map<String, String> queryParams = {
        'status': selectedStatus,
        'search': searchQuery,
        'page': currentPage.toString(),
        'limit': '10',
        'sortBy': 'created_at',
        'sortOrder': 'desc',
      };

      // Remove search if empty
      if (searchQuery.isEmpty) {
        queryParams.remove('search');
      }

      final response = await apiClient.get(
        '/hiddenGem/moderation',
        queryParameters: queryParams,
      );

      print('Hidden Gems API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        
        if (responseBody is Map<String, dynamic> && responseBody['success'] == true) {
          final data = responseBody['data'] as List;
          final pagination = responseBody['pagination'] ?? {};
          
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
          throw Exception('Invalid response format');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else if (response.statusCode == 404) {
        throw Exception('Endpoint not found');
      } else {
        throw Exception('Failed to load hidden gems: ${response.statusCode}');
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

  Future<void> _loadModerationStats() async {
    try {
      final response = await apiClient.get('/hiddenGem/moderation/stats');

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        
        if (responseBody is Map<String, dynamic> && responseBody['success'] == true) {
          final stats = responseBody['data'];
          
          if (mounted) {
            setState(() {
              statusFilters[0]['count'] = stats['total'] ?? 0;
              statusFilters[1]['count'] = stats['pending'] ?? 0;
              statusFilters[2]['count'] = stats['approved'] ?? 0;
              statusFilters[3]['count'] = stats['rejected'] ?? 0;
              statusFilters[4]['count'] = stats['draft'] ?? 0;
              isLoadingStats = false;
            });
          }
        }
      }
    } catch (error) {
      print('Failed to load stats: $error');
      if (mounted) {
        setState(() {
          isLoadingStats = false;
        });
      }
    }
  }

  Future<void> _updateGemStatus(int gemId, String status, {String? rejectionReason}) async {
    try {
      final data = {
        'status': status,
        if (rejectionReason != null) 'rejectionReason': rejectionReason,
      };

      final response = await apiClient.patch(
        '/hiddenGem/$gemId/status',
        data,
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        
        if (responseBody is Map<String, dynamic> && responseBody['success'] == true) {
          _showSnackBar('Status updated successfully');
          _loadHiddenGems();
          _loadModerationStats();
        } else {
          throw Exception('API returned error');
        }
      } else {
        throw Exception('Failed to update status: ${response.statusCode}');
      }
    } catch (error) {
      print('Error updating status: $error');
      _showSnackBar('Failed to update status', isError: true);
    }
  }

  Future<void> _deleteHiddenGem(int gemId) async {
    try {
      // Since your backend doesn't have a delete endpoint yet, we'll update status to 'deleted'
      // You can modify this when you add a proper delete endpoint
      final response = await apiClient.patch(
        '/hiddenGem/$gemId/status',
        {'status': 'deleted'},
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        
        if (responseBody is Map<String, dynamic> && responseBody['success'] == true) {
          _showSnackBar('Hidden gem removed successfully');
          _loadHiddenGems();
          _loadModerationStats();
        }
      } else {
        throw Exception('Failed to remove hidden gem');
      }
    } catch (error) {
      print('Error removing hidden gem: $error');
      _showSnackBar('Failed to remove hidden gem', isError: true);
    }
  }

  void _showStatusUpdateDialog(Map<String, dynamic> gem) {
    // For rejected gems, only show delete option
    if (gem['status'] == 'rejected') {
      _showDeleteDialog(gem);
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Update Status',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                gem['title'] ?? 'Unknown Gem',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              if (gem['status'] != 'approved')
                _buildStatusButton('Approve', Colors.green, 'approved', gem),
              if (gem['status'] != 'rejected')
                _buildStatusButton('Reject', Colors.red, 'rejected', gem),
              if (gem['status'] != 'pending')
                _buildStatusButton('Mark as Pending', Colors.orange, 'pending', gem),
              if (gem['status'] != 'draft')
                _buildStatusButton('Move to Draft', Colors.blue, 'draft', gem),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusButton(String label, Color color, String status, Map<String, dynamic> gem) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
          if (status == 'rejected') {
            _showRejectionReasonDialog(gem);
          } else {
            _updateGemStatus(gem['id'], status);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.2),
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: color.withOpacity(0.5)),
          ),
        ),
        child: Text(label),
      ),
    );
  }

  void _showRejectionReasonDialog(Map<String, dynamic> gem) {
    final TextEditingController reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Rejection Reason',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: reasonController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Enter reason for rejection...',
              hintStyle: TextStyle(color: Colors.white54),
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red),
              ),
            ),
            maxLines: 3,
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
                if (reasonController.text.trim().isEmpty) {
                  _showSnackBar('Please provide a rejection reason', isError: true);
                  return;
                }
                Navigator.pop(context);
                _updateGemStatus(gem['id'], 'rejected', 
                  rejectionReason: reasonController.text.trim());
              },
              child: const Text(
                'Reject',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(Map<String, dynamic> gem) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text(
            'Remove Hidden Gem',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Are you sure you want to permanently remove "${gem['title']}"?',
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
                'Remove',
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'draft':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'pending':
        return 'Pending Review';
      case 'draft':
        return 'Draft';
      default:
        return status;
    }
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
          'Hidden Gems Status',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Status Filter Chips
          _buildStatusFilter(),
          
          // Search Bar
          _buildSearchBar(),
          
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
          // Debounce search
          Future.delayed(const Duration(milliseconds: 500), () {
            if (searchQuery == value) {
              currentPage = 1;
              _loadHiddenGems();
            }
          });
        },
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search hidden gems...',
          hintStyle: const TextStyle(color: Colors.white54),
          prefixIcon: const Icon(Icons.search, color: Colors.white54),
          filled: true,
          fillColor: const Color(0xFF1A1A1A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
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
          ],
        ),
      );
    }

    return Column(
      children: [
        // Pagination Info
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                'Showing ${hiddenGems.length} of $totalCount',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              if (totalPages > 1)
                Row(
                  children: [
                    IconButton(
                      onPressed: currentPage > 1
                          ? () {
                              setState(() {
                                currentPage--;
                              });
                              _loadHiddenGems();
                            }
                          : null,
                      icon: const Icon(Icons.chevron_left, color: Colors.white),
                    ),
                    Text(
                      '$currentPage / $totalPages',
                      style: const TextStyle(color: Colors.white54),
                    ),
                    IconButton(
                      onPressed: currentPage < totalPages
                          ? () {
                              setState(() {
                                currentPage++;
                              });
                              _loadHiddenGems();
                            }
                          : null,
                      icon: const Icon(Icons.chevron_right, color: Colors.white),
                    ),
                  ],
                ),
            ],
          ),
        ),

        // Gems List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: hiddenGems.length,
            itemBuilder: (context, index) {
              final gem = hiddenGems[index];
              return _buildGemCard(gem);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGemCard(Map<String, dynamic> gem) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
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
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),

                const SizedBox(height: 12),

                // Traveler Info
                if (gem['traveler'] != null)
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: gem['traveler']['user']['profile_picture_url'] != null
                            ? NetworkImage(gem['traveler']['user']['profile_picture_url'])
                            : null,
                        child: gem['traveler']['user']['profile_picture_url'] == null
                            ? const Icon(Icons.person, size: 16, color: Colors.white54)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        gem['traveler']['user']['name'] ?? 'Unknown Traveler',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 12),

                // Dates and Actions
                Row(
                  children: [
                    Text(
                      'Created: ${gem['created_at'] != null ? 
                        DateTime.parse(gem['created_at']).toLocal().toString().split(' ')[0] : 
                        'Unknown'}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    // For rejected gems, only show delete button
                    if (gem['status'] == 'rejected')
                      ElevatedButton(
                        onPressed: () => _showDeleteDialog(gem),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.2),
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Remove'),
                      )
                    else
                      // For other statuses, show update button
                      ElevatedButton(
                        onPressed: () => _showStatusUpdateDialog(gem),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.withOpacity(0.2),
                          foregroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Update Status'),
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
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
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