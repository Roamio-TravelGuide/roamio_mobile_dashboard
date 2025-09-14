class Destination {
  final String id;
  final String name;
  final String? image; // Make image nullable
  final String location;
  final double rating;
  final String price;
  final String description;
  final bool isCompleted;
  final int downloadCount;
  final int reviewCount;
  final DateTime createdAt;

  const Destination({
    required this.id,
    required this.name,
    this.image, // Now nullable
    required this.location,
    required this.rating,
    required this.price,
    required this.description,
    required this.isCompleted,
    required this.downloadCount,
    required this.reviewCount,
    required this.createdAt,
  });

  // Factory constructor with default values
  factory Destination.withDefaults({
    required String id,
    required String name,
    String? image, // Make image nullable
    required String location,
    required double rating,
    required String price,
    required String description,
    required bool isCompleted,
    int downloadCount = 0,
    int reviewCount = 0,
    required DateTime createdAt,
  }) {
    return Destination(
      id: id,
      name: name,
      image: image, // Can be null
      location: location,
      rating: rating,
      price: price,
      description: description,
      isCompleted: isCompleted,
      downloadCount: downloadCount,
      reviewCount: reviewCount,
      createdAt: createdAt,
    );
  }
}