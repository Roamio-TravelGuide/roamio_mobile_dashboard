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
  final double? latitude; // New: For location-based sorting
  final double? longitude; // New: For location-based sorting

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
    this.latitude, // New: nullable
    this.longitude, // New: nullable
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
    double? latitude, // New: optional
    double? longitude, // New: optional
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
      latitude: latitude, // New
      longitude: longitude, // New
    );
  }

  // Helper method to check if destination has location data
  bool get hasLocation => latitude != null && longitude != null;

  // Copy with method for creating modified copies
  Destination copyWith({
    String? id,
    String? name,
    String? image,
    String? location,
    double? rating,
    String? price,
    String? description,
    bool? isCompleted,
    int? downloadCount,
    int? reviewCount,
    DateTime? createdAt,
    double? latitude,
    double? longitude,
  }) {
    return Destination(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      location: location ?? this.location,
      rating: rating ?? this.rating,
      price: price ?? this.price,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      downloadCount: downloadCount ?? this.downloadCount,
      reviewCount: reviewCount ?? this.reviewCount,
      createdAt: createdAt ?? this.createdAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  // Convert to map for serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'location': location,
      'rating': rating,
      'price': price,
      'description': description,
      'isCompleted': isCompleted,
      'downloadCount': downloadCount,
      'reviewCount': reviewCount,
      'createdAt': createdAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  // Create from map for deserialization
  factory Destination.fromMap(Map<String, dynamic> map) {
    return Destination(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      image: map['image'],
      location: map['location'] ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      price: map['price'] ?? '',
      description: map['description'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      downloadCount: map['downloadCount'] ?? 0,
      reviewCount: map['reviewCount'] ?? 0,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }

  @override
  String toString() {
    return 'Destination(id: $id, name: $name, location: $location, rating: $rating, hasLocation: $hasLocation)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Destination && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}