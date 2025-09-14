class FilterOptions {
  String location;
  String selectedCategory;
  double minPrice;
  double maxPrice;

  FilterOptions({
    this.location = '',
    this.selectedCategory = '',
    this.minPrice = 0,
    this.maxPrice = 1000,
  });

  bool get hasActiveFilters {
    return location.isNotEmpty || 
           selectedCategory.isNotEmpty || 
           minPrice > 0 || 
           maxPrice < 1000;
  }

  void reset() {
    location = '';
    selectedCategory = '';
    minPrice = 0;
    maxPrice = 1000;
  }

  @override
  String toString() {
    return 'FilterOptions(location: $location, category: $selectedCategory, minPrice: $minPrice, maxPrice: $maxPrice)';
  }
}