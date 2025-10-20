// guide_landing.dart
import 'package:flutter/material.dart';
import '../../../../core/services/tour_package_service.dart';
import '../../../../core/models/tour_package.dart';
import '../../api/tour_package_api.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/config/env_config.dart';
import './tour_package_detail.dart';
import '../../../auth/api/auth_api.dart';

class GuideLandingScreen extends StatefulWidget {
  const GuideLandingScreen({Key? key}) : super(key: key);

  @override
  State<GuideLandingScreen> createState() => _GuideLandingScreenState();
}

class _GuideLandingScreenState extends State<GuideLandingScreen> {
  late TourPackageService _tourPackageService;
  List<TourPackage> _tourPackages = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String? _userName;

  @override
  void initState() {
    super.initState();
    _initializeService();
    _loadTourPackages();
    _loadUserName();
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

      final packages = await _tourPackageService.getTourPackagesByGuideId();
      
      setState(() {
        _tourPackages = packages;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserName() async {
    final name = await AuthApi.getUserName();
    setState(() {
      _userName = name ?? '';
    });
  }

  // Statistics calculations
  int get totalPackages => _tourPackages.length;
  
  int get approvedPackages => _tourPackages
      .where((pkg) => pkg.status == PackageStatus.published)
      .length;
  
  int get pendingPackages => _tourPackages
      .where((pkg) => pkg.status == PackageStatus.pending_approval)
      .length;
  
  int get totalDownloads => _tourPackages
      .fold(0, (sum, pkg) => sum + pkg.downloadCount);
  
  int get totalReviews => _tourPackages
      .fold(0, (sum, pkg) => sum + pkg.reviewCount);
  
  double get averageRating {
    if (_tourPackages.isEmpty) return 0.0;
    final totalRating = _tourPackages
        .fold(0.0, (sum, pkg) => sum + pkg.averageRating);
    return totalRating / _tourPackages.length;
  }

  // Popular packages (published packages sorted by downloads)
  List<TourPackage> get popularPackages {
    return _tourPackages
        .where((pkg) => pkg.status == PackageStatus.published)
        .toList()
      ..sort((a, b) => b.downloadCount.compareTo(a.downloadCount));
  }

  // Recent packages (sorted by creation date)
  List<TourPackage> get recentPackages {
    return _tourPackages.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _tourPackages.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Error: $_errorMessage',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadTourPackages,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadTourPackages,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good Morning',
                          style: TextStyle(color: Colors.grey[400], fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _userName ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Audio Tour Creator',
                          style: TextStyle(color: Colors.grey[400], fontSize: 14),
                        ),
                      ],
                    ),
                    Stack(
                      children: [
                        const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Statistics Cards - First Row
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        icon: Icons.audio_file,
                        value: '$totalPackages',
                        label: 'Total Packages',
                        iconColor: const Color(0xFF4A90E2),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: StatCard(
                        icon: Icons.verified,
                        value: '$approvedPackages',
                        label: 'Approved',
                        iconColor: const Color(0xFF4ECDC4),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // Statistics Cards - Second Row
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        icon: Icons.pending_actions,
                        value: '$pendingPackages',
                        label: 'Pending',
                        iconColor: const Color(0xFFFFA726),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: StatCard(
                        icon: Icons.download,
                        value: '$totalDownloads',
                        label: 'Total Downloads',
                        iconColor: const Color(0xFFFF6B6B),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // Statistics Cards - Third Row
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        icon: Icons.reviews,
                        value: '$totalReviews',
                        label: 'Total Reviews',
                        iconColor: const Color(0xFF9C27B0),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: StatCard(
                        icon: Icons.star,
                        value: averageRating.toStringAsFixed(1),
                        label: 'Avg Rating',
                        iconColor: Colors.amber,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Popular Audio Tours Section
                const Text(
                  'Popular Audio Tours',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                // Popular tours list
                if (popularPackages.isEmpty)
                  _buildEmptyState('No published tours yet')
                else
                  Column(
                    children: popularPackages
                        .take(4) // Show only top 4 popular packages
                        .map((package) => Column(
                              children: [
                                AudioTourItem(
                                  tourPackage: package,
                                ),
                                const SizedBox(height: 15),
                              ],
                            ))
                        .toList(),
                  ),

                const SizedBox(height: 30),

                // Recent Packages Section
                const Text(
                  'Recent Packages',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                // Recent packages list
                if (recentPackages.isEmpty)
                  _buildEmptyState('No packages created yet')
                else
                  Column(
                    children: recentPackages
                        .take(3) // Show only 3 recent packages
                        .map((package) => Column(
                              children: [
                                AudioTourItem(
                                  tourPackage: package,
                                ),
                                const SizedBox(height: 15),
                              ],
                            ))
                        .toList(),
                  ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}

// Keep all the widget classes (StatCard, AudioTourItem, InfoChip, QuickActionButton) the same
// ... [rest of your widget classes remain unchanged]

// ------------------------ WIDGETS ------------------------

class StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;

  const StatCard({
    Key? key,
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class AudioTourItem extends StatelessWidget {
  final TourPackage tourPackage;

  const AudioTourItem({
    Key? key,
    required this.tourPackage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to tour detail screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TourPackageDetailScreen(tourPackageId: tourPackage.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    tourPackage.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      tourPackage.averageRating.toStringAsFixed(1),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                InfoChip(
                  icon: Icons.access_time, 
                  text: tourPackage.durationFormatted
                ),
                const SizedBox(width: 12),
                InfoChip(
                  icon: Icons.location_on, 
                  text: '${tourPackage.tourStops.length} stops'
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${tourPackage.downloadCount} downloads',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const InfoChip({Key? key, required this.icon, required this.text})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.grey[400], size: 14),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
      ],
    );
  }
}
