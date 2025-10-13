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
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentFilters = FilterOptions(
      location: widget.initialFilters.location,
      selectedCategory: widget.initialFilters.selectedCategory,
      minPrice: widget.initialFilters.minPrice,
      maxPrice: widget.initialFilters.maxPrice,
    );
    _initializeControllers();
  }

  void _initializeControllers() {
    _locationController.text = _currentFilters.location;
    _minPriceController.text = _currentFilters.minPrice > 0 ? _currentFilters.minPrice.toStringAsFixed(0) : '';
    _maxPriceController.text = _currentFilters.maxPrice < 1000 ? _currentFilters.maxPrice.toStringAsFixed(0) : '';
  }

  @override
  void dispose() {
    _locationController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _currentFilters.reset();
      _locationController.clear();
      _minPriceController.clear();
      _maxPriceController.clear();
    });
  }

  void _applyFilters() {
    // Validate price ranges
    if (_currentFilters.minPrice > _currentFilters.maxPrice) {
      // Swap values if min is greater than max
      final temp = _currentFilters.minPrice;
      _currentFilters.minPrice = _currentFilters.maxPrice;
      _currentFilters.maxPrice = temp;
    }
    
    widget.onFiltersApplied(_currentFilters);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Filters & Preferences',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: _resetFilters,
            child: const Text(
              'Reset All',
              style: TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location Filter
              _buildSectionHeader(
                Icons.location_on_outlined,
                'Destination Location',
              ),
              const SizedBox(height: 12),
              _buildLocationField(),
              
              const SizedBox(height: 24),
              
              // Price Range Filter
              _buildSectionHeader(
                Icons.attach_money_rounded,
                'Budget Range',
              ),
              const SizedBox(height: 12),
              _buildPriceRangeSection(),
              
              const SizedBox(height: 24),
              
              // Additional Filters Section
              _buildSectionHeader(
                Icons.tune_rounded,
                'Additional Preferences',
              ),
              const SizedBox(height: 12),
              _buildAdditionalFilters(),
              
              const Spacer(),
              
              // Apply Button
              _buildApplyButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.blue,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: _locationController,
        onChanged: (value) => setState(() => _currentFilters.location = value),
        textInputAction: TextInputAction.done,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Enter city, country or region...',
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 14,
          ),
          border: InputBorder.none,
          suffixIcon: IconButton(
            icon: Icon(
              Icons.my_location_rounded,
              color: Colors.blue.withOpacity(0.7),
              size: 20,
            ),
            onPressed: () {
              // TODO: Implement current location detection
            },
          ),
        ),
        cursorColor: Colors.blue,
      ),
    );
  }

  Widget _buildPriceRangeSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildPriceField(
                'Minimum Budget',
                _minPriceController,
                (value) => setState(() => _currentFilters.minPrice = value),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPriceField(
                'Maximum Budget',
                _maxPriceController,
                (value) => setState(() => _currentFilters.maxPrice = value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildPriceRangeIndicator(),
      ],
    );
  }

  Widget _buildPriceField(
    String hint,
    TextEditingController controller,
    Function(double) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        onChanged: (text) {
          final value = double.tryParse(text) ?? 0;
          onChanged(value);
        },
        textInputAction: TextInputAction.done,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 14,
          ),
          border: InputBorder.none,
          prefixText: 'Rs. ',
          prefixStyle: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        cursorColor: Colors.blue,
      ),
    );
  }

  Widget _buildPriceRangeIndicator() {
    final hasPriceRange = _currentFilters.minPrice > 0 || _currentFilters.maxPrice < 1000;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: hasPriceRange ? Colors.blue.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasPriceRange ? Colors.blue.withOpacity(0.3) : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: hasPriceRange ? Colors.blue : Colors.transparent,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            hasPriceRange 
                ? 'Range: Rs. ${_currentFilters.minPrice.toStringAsFixed(0)} - Rs. ${_currentFilters.maxPrice.toStringAsFixed(0)}'
                : 'No price range set',
            style: TextStyle(
              color: hasPriceRange ? Colors.blue : Colors.white.withOpacity(0.4),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.category_outlined,
                color: Colors.white.withOpacity(0.6),
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'More filters coming soon...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Duration, ratings, and categories will be available in the next update',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildApplyButton() {
    final hasActiveFilters = _currentFilters.hasActiveFilters;
    
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: hasActiveFilters
            ? LinearGradient(
                colors: [Colors.blue.shade500, Colors.blue.shade700],
              )
            : LinearGradient(
                colors: [Colors.grey.shade600, Colors.grey.shade700],
              ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: hasActiveFilters
            ? [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: hasActiveFilters ? _applyFilters : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          disabledBackgroundColor: Colors.grey.shade600,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasActiveFilters ? Icons.check_circle_outline_rounded : Icons.filter_alt_off_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              hasActiveFilters ? 'Apply Filters' : 'No Filters Selected',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}