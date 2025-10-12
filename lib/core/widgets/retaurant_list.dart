import 'package:flutter/material.dart';

class RestaurantList extends StatelessWidget {
  final List<Map<String, dynamic>> restaurants;
  final ValueChanged<Map<String, dynamic>> onRestaurantTap;
  final bool isLoading;

  const RestaurantList({
    super.key,
    required this.restaurants,
    required this.onRestaurantTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _LoadingIndicator();
    }

    if (restaurants.isEmpty) {
      return const _EmptyState();
    }

    return Column(
      children: restaurants.map((restaurant) {
        return _RestaurantItem(
          restaurant: restaurant,
          onTap: () => onRestaurantTap(restaurant),
        );
      }).toList(),
    );
  }
}

class _RestaurantItem extends StatelessWidget {
  final Map<String, dynamic> restaurant;
  final VoidCallback onTap;

  const _RestaurantItem({
    required this.restaurant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 5, 11, 26),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildImage(),
              const SizedBox(width: 12),
              _buildInfo(),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 60,
        height: 60,
        child: Image.network(
          restaurant['image'],
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.blue.shade300,
              child: const Icon(
                Icons.restaurant,
                color: Colors.white,
                size: 24,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfo() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            restaurant['name'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            restaurant['description'],
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Text(
        'No restaurants found nearby',
        style: TextStyle(
          color: Colors.grey,
          fontSize: 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}