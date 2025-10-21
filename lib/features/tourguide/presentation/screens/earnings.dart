import 'package:flutter/material.dart';
import '../../../../core/api/api_client.dart';
import '../../../auth/api/auth_api.dart';
import '../../api/travel_guide_api.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({Key? key}) : super(key: key);

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  bool _isInitialized = false;
  String? _initializationError;

  late TravelGuideApi travelGuideApi;
  late ApiClient apiClient;

  late Future<Map<String, dynamic>> _revenueFuture;
  late Future<Map<String, dynamic>> _paidPackagesFuture;

  @override
  void initState() {
    super.initState();
    _initializeApis();
  }

  String _formatCurrency(dynamic value) {
    try {
      if (value == null) return 'Rs 0';
      num amount;
      if (value is String) {
        amount = num.parse(value);
      } else if (value is num) {
        amount = value;
      } else {
        return 'Rs 0';
      }
      final intPart = amount.toInt();
      final formatted = intPart.toString().replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (match) => ',');
      return 'Rs ${formatted}';
    } catch (e) {
      return 'Rs 0';
    }
  }

  Future<void> _initializeApis() async {
    try {
      final token = await AuthApi.getAuthToken();
      if (token == null) throw Exception('Not authenticated - no token');

      apiClient = ApiClient(token: token);
      travelGuideApi = TravelGuideApi(apiClient: apiClient);

  _revenueFuture = _fetchRevenue();
  _paidPackagesFuture = _fetchPaidPackages();

      setState(() {
        _isInitialized = true;
        _initializationError = null;
      });
    } catch (e) {
      setState(() {
        _isInitialized = true;
        _initializationError = e.toString();
      });
    }
  }

  Future<Map<String, dynamic>> _fetchRevenue() async {
    try {
      final userId = await AuthApi.getUserId();
      if (userId == null) throw Exception('User ID not found');

      final revenue = await travelGuideApi.getRevenueById(userId.toString());
      return revenue;
    } catch (e) {
      print('Error fetching revenue: $e');
      return {
        'success': false,
        'message': e.toString(),
        'data': null,
      };
    }
  }

  Future<Map<String, dynamic>> _fetchPaidPackages() async {
    try {
      final userId = await AuthApi.getUserId();
      if (userId == null) throw Exception('User ID not found');

      final res = await travelGuideApi.getPaidPackagesById(userId.toString());
      return res;
    } catch (e) {
      print('Error fetching paid packages: $e');
      return {'success': false, 'message': e.toString(), 'data': null};
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0D12),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_initializationError != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0D0D12),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                const Text('Initialization Error', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(_initializationError!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton(onPressed: _initializeApis, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: _revenueFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0D0D12),
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        final apiResponse = snapshot.data ?? {'success': false, 'data': null};

        // API sometimes returns data as a List (e.g. [{...}]) or as a Map ({...}).
        // Normalize to a Map by taking the first element if it's a List.
        dynamic rawData = apiResponse['data'];
        Map<String, dynamic>? data;

        if (rawData is List && rawData.isNotEmpty) {
          final first = rawData.first;
          if (first is Map) {
            data = Map<String, dynamic>.from(first);
          }
        } else if (rawData is Map) {
          data = Map<String, dynamic>.from(rawData);
        } else {
          data = null;
        }

        // Safely read fields with fallbacks
        String totalEarnings;
        // Prefer backend field names if present
        if (data != null && data['total_revenue'] != null) {
          totalEarnings = _formatCurrency(data['total_revenue']);
        } else if (data != null && data['totalEarnings'] != null) {
          totalEarnings = _formatCurrency(data['totalEarnings']);
        } else if (data != null && data['gross'] != null) {
          totalEarnings = _formatCurrency(data['gross']);
        } else {
          totalEarnings = 'Rs 0';
        }

    // Weekly revenue from backend
    final weeklyRevenue = (data != null && data['weekly_revenue'] != null)
      ? _formatCurrency(data['weekly_revenue'])
      : 'Rs 0';
    final downloads = (data != null && data['total_payments'] != null)
      ? data['total_payments'].toString()
      : (data != null && data['packages_sold'] != null) ? data['packages_sold'].toString() : '0';

  // We'll populate transactions from the paid packages API call below.

        return Scaffold(
          backgroundColor: const Color(0xFF1A1A1A),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          _buildHeader(),
                          
                          const SizedBox(height: 30),
                          _buildTotalEarningsCard(totalEarnings),
                          const SizedBox(height: 20),
                          _buildStatsRow(weeklyRevenue, downloads),
                          const SizedBox(height: 30),
                          // Recent transactions: use paid packages API
                          FutureBuilder<Map<String, dynamic>>(
                            future: _paidPackagesFuture,
                            builder: (context, paidSnap) {
                              if (paidSnap.connectionState == ConnectionState.waiting) {
                                return const SizedBox(
                                  height: 100,
                                  child: Center(child: CircularProgressIndicator(color: Colors.white)),
                                );
                              }

                              final paidResp = paidSnap.data ?? {'success': false, 'data': null};
                              dynamic paidRaw = paidResp['data'];
                              List<Map<String, dynamic>> paidList = [];

                              if (paidRaw is List) {
                                paidList = paidRaw.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
                              } else if (paidRaw is Map) {
                                paidList = [Map<String, dynamic>.from(paidRaw)];
                              }

                              return _buildRecentTransactionsFromApi(paidList);
                            },
                          ),
                          const Spacer(),
                          _buildEarningsSummaryFromApi(data),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // Parameterized / API-driven builders
  Widget _buildTotalEarningsCard(String totalEarnings) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Earnings', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            totalEarnings.startsWith('Rs') ? totalEarnings : 'Rs ${totalEarnings}',
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Row(
            children: const [
              SizedBox(width: 4),
              Text('', style: TextStyle(color: Color(0xFF4ECDC4), fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(String thisWeek, String downloads) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(child: StatCard(value: thisWeek, label: 'Weekly Revenue')),
          const SizedBox(width: 15),
          Expanded(child: StatCard(value: downloads, label: 'Downloads')),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsFromApi(List<Map<String, dynamic>> transactions) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Transactions', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          if (transactions.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Text('No paid packages found yet.', style: TextStyle(color: Colors.grey[400])),
            ),
          ] else ...[
            transactions.length <= 5
                ? Column(
                    children: transactions.map((tx) {
                      // Map API fields to UI
                      final title = tx['package_title']?.toString() ?? tx['packageTitle']?.toString() ?? tx['title']?.toString() ?? 'Package';
                      final paidAtRaw = tx['paid_at'] ?? tx['paidAt'] ?? tx['created_at'] ?? tx['date'];
                      String subtitle = '';
                      try {
                        if (paidAtRaw != null) {
                          final dt = DateTime.parse(paidAtRaw.toString());
                          subtitle = 'Downloaded • ${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
                        }
                      } catch (_) {
                        subtitle = paidAtRaw?.toString() ?? '';
                      }

                      final amountVal = tx['amount'] ?? tx['total'] ?? 0;
                      final amount = 'Rs ${_formatCurrency(amountVal).replaceAll('Rs ', '')}';
                      final status = tx['status']?.toString() ?? 'Completed';
                      return TransactionItem(title: title, subtitle: subtitle, amount: amount, status: status);
                    }).toList(),
                  )
                : SizedBox(
                    height: 300,
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final tx = transactions[index];
                        final title = tx['package_title']?.toString() ?? tx['packageTitle']?.toString() ?? tx['title']?.toString() ?? 'Package';
                        final paidAtRaw = tx['paid_at'] ?? tx['paidAt'] ?? tx['created_at'] ?? tx['date'];
                        String subtitle = '';
                        try {
                          if (paidAtRaw != null) {
                            final dt = DateTime.parse(paidAtRaw.toString());
                            subtitle = 'Downloaded • ${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
                          }
                        } catch (_) {
                          subtitle = paidAtRaw?.toString() ?? '';
                        }

                        final amountVal = tx['amount'] ?? tx['total'] ?? 0;
                        final amount = 'Rs ${_formatCurrency(amountVal).replaceAll('Rs ', '')}';
                        final status = tx['status']?.toString() ?? 'Completed';
                        return TransactionItem(title: title, subtitle: subtitle, amount: amount, status: status);
                      },
                    ),
                  ),
          ],
        ],
      ),
    );
  }

  Widget _buildEarningsSummaryFromApi(Map<String, dynamic>? data) {
    // Get total earnings (gross)
    num total = 0;
    if (data != null && data['total_revenue'] != null) {
      total = data['total_revenue'] is num ? data['total_revenue'] : num.tryParse(data['total_revenue'].toString()) ?? 0;
    } else if (data != null && data['totalEarnings'] != null) {
      total = data['totalEarnings'] is num ? data['totalEarnings'] : num.tryParse(data['totalEarnings'].toString()) ?? 0;
    } else if (data != null && data['gross'] != null) {
      total = data['gross'] is num ? data['gross'] : num.tryParse(data['gross'].toString()) ?? 0;
    }

    final gross = 'Rs ${_formatCurrency(total).replaceAll('Rs ', '')}';
    final feeNum = (total * 0.10);
    final platformFee = '-Rs ${_formatCurrency(feeNum).replaceAll('Rs ', '')}';
    final netNum = total - feeNum;
    final net = 'Rs ${_formatCurrency(netNum).replaceAll('Rs ', '')}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Earnings Summary', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          SummaryRow(label: 'Gross Earnings', value: gross),
          SummaryRow(label: 'Platform Fee (10%)', value: platformFee),
          const Divider(color: Colors.grey, height: 30),
          SummaryRow(label: 'Net Earnings', value: net, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Earnings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Track your audio tour revenue',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.download_outlined,
                color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  



 

 
}

// --- SUPPORTING WIDGETS (Replace with your actual widgets if already created) ---

class TimeFilterChip extends StatelessWidget {
  final String text;
  final bool isSelected;

  const TimeFilterChip({super.key, required this.text, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        text,
        style: TextStyle(color: isSelected ? Colors.black : Colors.white),
      ),
      backgroundColor: isSelected ? Colors.teal : const Color(0xFF2A2A2A),
    );
  }
}

class StatCard extends StatelessWidget {
  final String value;
  final String label;

  const StatCard({super.key, required this.value, required this.label});

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
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        ],
      ),
    );
  }
}

class TransactionItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final String status;

  const TransactionItem(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.amount,
      required this.status});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title,
          style: const TextStyle(color: Colors.white, fontSize: 14)),
      subtitle: Text(subtitle,
          style: TextStyle(color: Colors.grey[400], fontSize: 12)),
      trailing: Text(amount,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}

class SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const SummaryRow(
      {super.key, required this.label, required this.value, this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              )),
          Text(value,
              style: TextStyle(
                color: Colors.white,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              )),
        ],
      ),
    );
  }
}
