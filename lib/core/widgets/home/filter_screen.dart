import 'package:flutter/material.dart';
import '../../models/filter_options.dart';

class FilterScreen extends StatefulWidget {
  final FilterOptions initialFilters;
  final Function(FilterOptions) onFiltersApplied;

  const FilterScreen({
    super.key,
    required this.initialFilters,
    required this.onFiltersApplied,
  });

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  late FilterOptions _currentFilters;
  final List<String> categories = [
    'Beach', 'Mountain', 'Cultural', 'Adventure', 'Food'
  ];

  @override
  void initState() {
    super.initState();
    _currentFilters = FilterOptions(
      location: widget.initialFilters.location,
      selectedCategory: widget.initialFilters.selectedCategory,
      minPrice: widget.initialFilters.minPrice,
      maxPrice: widget.initialFilters.maxPrice,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C23),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C23),
        title: const Text(
          'Filter Search',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _currentFilters.reset();
              });
            },
            child: const Text(
              'Reset',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location Filter
            const Text(
              'Location',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _currentFilters.location = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'New York, USA',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: Icon(Icons.location_on, color: Colors.white.withOpacity(0.7)),
                    onPressed: () {
                      // Implement location picker
                    },
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                controller: TextEditingController(text: _currentFilters.location),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Price Range Filter
            const Text(
              'Price Range',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _currentFilters.minPrice = double.tryParse(value) ?? 0;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Min',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                        border: InputBorder.none,
                        prefixText: '\$ ',
                        prefixStyle: const TextStyle(color: Colors.white),
                      ),
                      style: const TextStyle(color: Colors.white),
                      controller: TextEditingController(
                        text: _currentFilters.minPrice > 0 ? _currentFilters.minPrice.toStringAsFixed(2) : '',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _currentFilters.maxPrice = double.tryParse(value) ?? 1000;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Max',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                        border: InputBorder.none,
                        prefixText: '\$ ',
                        prefixStyle: const TextStyle(color: Colors.white),
                      ),
                      style: const TextStyle(color: Colors.white),
                      controller: TextEditingController(
                        text: _currentFilters.maxPrice < 1000 ? _currentFilters.maxPrice.toStringAsFixed(2) : '',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const Spacer(),
            
            // Apply Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onFiltersApplied(_currentFilters);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Apply Filter',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}