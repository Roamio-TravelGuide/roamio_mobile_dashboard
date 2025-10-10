import 'package:flutter/material.dart';

class EarningsScreen extends StatelessWidget {
  const EarningsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                      _buildTimeFilters(),
                      const SizedBox(height: 30),
                      _buildTotalEarningsCard(),
                      const SizedBox(height: 20),
                      _buildStatsRow(),
                      const SizedBox(height: 30),
                      _buildRecentTransactions(), // 👈 Scrollable section inside
                      const Spacer(),
                      _buildEarningsSummary(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
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

  Widget _buildTimeFilters() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: const [
          TimeFilterChip(text: 'This Week', isSelected: true),
          SizedBox(width: 8),
          TimeFilterChip(text: 'This Month', isSelected: false),
          SizedBox(width: 8),
          TimeFilterChip(text: 'Quarter', isSelected: false),
          SizedBox(width: 8),
          TimeFilterChip(text: 'Year', isSelected: false),
        ],
      ),
    );
  }

  Widget _buildTotalEarningsCard() {
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
          Text('Total Earnings',
              style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          const SizedBox(height: 8),
          const Text(
            '\$1,840',
            style: TextStyle(
                color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Row(
            children: const [
              Icon(Icons.trending_up, color: Color(0xFF4ECDC4), size: 16),
              SizedBox(width: 4),
              Text(
                '+12% from last month',
                style: TextStyle(color: Color(0xFF4ECDC4), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: const [
          Expanded(child: StatCard(value: '\$485', label: 'This Week')),
          SizedBox(width: 15),
          Expanded(child: StatCard(value: '17', label: 'Downloads')),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    final List<Map<String, String>> transactions = [
      {
        'title': 'Historic Downtown Audio Tour',
        'subtitle': 'Downloaded • 2024-03-15',
        'amount': '\$45',
        'status': 'Completed',
      },
      {
        'title': 'Art Museum Audio Guide',
        'subtitle': 'Downloaded • 2024-03-14',
        'amount': '\$32',
        'status': 'Completed',
      },
      {
        'title': 'Food District Audio Walk',
        'subtitle': 'Downloaded • 2024-03-13',
        'amount': '\$18',
        'status': 'Completed',
      },
      {
        'title': 'City Nightlife Audio Guide',
        'subtitle': 'Downloaded • 2024-03-12',
        'amount': '\$25',
        'status': 'Completed',
      },
      {
        'title': 'Cultural Heritage Walk',
        'subtitle': 'Downloaded • 2024-03-10',
        'amount': '\$50',
        'status': 'Completed',
      },
      {
        'title': 'Hidden Gems Tour',
        'subtitle': 'Downloaded • 2024-03-08',
        'amount': '\$20',
        'status': 'Completed',
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Transactions',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          transactions.length <= 5
              ? Column(
                  children: transactions
                      .map((tx) => TransactionItem(
                            title: tx['title']!,
                            subtitle: tx['subtitle']!,
                            amount: tx['amount']!,
                            status: tx['status']!,
                          ))
                      .toList(),
                )
              : SizedBox(
                  height: 300, // 👈 scrolling area height
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      return TransactionItem(
                        title: tx['title']!,
                        subtitle: tx['subtitle']!,
                        amount: tx['amount']!,
                        status: tx['status']!,
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildEarningsSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Earnings Summary',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          SizedBox(height: 15),
          SummaryRow(label: 'Gross Earnings', value: '\$2,044'),
          SummaryRow(label: 'Platform Fee (10%)', value: '-\$204'),
          SummaryRow(label: 'Tax', value: '-\$20'),
          Divider(color: Colors.grey, height: 30),
          SummaryRow(label: 'Net Earnings', value: '\$1,820', isTotal: true),
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
