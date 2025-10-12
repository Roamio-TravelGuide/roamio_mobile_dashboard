import 'package:intl/intl.dart';
import '../services/media_service.dart';
class TourPackage {
  final int id;
  final String title;
  final String? description;
  final double price;
  final int durationMinutes;
  final PackageStatus status;
  final int guideId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? rejectionReason;
  final Media? coverImage;
  final List<TourStop> tourStops;
  final TravelGuide guide;
  final int downloadCount;
  final int reviewCount;
  final double averageRating;


  TourPackage({
    required this.id,
    required this.title,
    this.description,
    required this.price,
    required this.durationMinutes,
    required this.status,
    required this.guideId,
    required this.createdAt,
    this.updatedAt,
    this.rejectionReason,
    this.coverImage,
    required this.tourStops,
    required this.guide,
    required this.downloadCount,
    required this.reviewCount,
    required this.averageRating,
  });

  factory TourPackage.fromJson(Map<String, dynamic> json) {
    return TourPackage(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      durationMinutes: json['duration_minutes'] ?? 0,
      status: _parsePackageStatus(json['status']),
      guideId: json['guide_id'] ?? 0,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      rejectionReason: json['rejection_reason'],
      coverImage: json['cover_image'] != null ? Media.fromJson(json['cover_image']) : null,
      tourStops: _parseTourStops(json['tour_stops'] ?? []),
      guide: TravelGuide.fromJson(json['guide'] ?? {}),
      downloadCount: json['downloadCount'] ?? json['_count']?['downloads'] ?? 0,
      reviewCount: json['reviewCount'] ?? json['_count']?['reviews'] ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
    );
  }

  static PackageStatus _parsePackageStatus(String? status) {
    switch (status) {
      case 'published':
        return PackageStatus.published;
      case 'rejected':
        return PackageStatus.rejected;
      case 'pending_approval':
      default:
        return PackageStatus.pending_approval;
    }
  }

  static List<TourStop> _parseTourStops(List<dynamic> stopsData) {
    return stopsData.map((stop) => TourStop.fromJson(stop)).toList();
  }

  // Helper methods
  String get durationFormatted {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    if (hours > 0) {
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
    return '${minutes}m';
  }

  int get durationDays => (durationMinutes / (60 * 24)).ceil();

  String get priceFormatted => '\$${price.toStringAsFixed(2)}';

  String get formattedDate => DateFormat('MMM dd, yyyy').format(createdAt);

  String get coverImageUrl => MediaService.getCoverImageUrl(coverImage?.url);


  bool get isPublished => status == PackageStatus.published;
  bool get isPending => status == PackageStatus.pending_approval;
  bool get isRejected => status == PackageStatus.rejected;
}

class TourStop {
  final int id;
  final int sequenceNo;
  final String stopName;
  final String? description;
  final Location? location;
  final List<Media> media;

  TourStop({
    required this.id,
    required this.sequenceNo,
    required this.stopName,
    this.description,
    this.location,
    required this.media,
  });

  factory TourStop.fromJson(Map<String, dynamic> json) {
    List<Media> mediaList = [];
    if (json['media'] is List) {
      mediaList = (json['media'] as List).map((mediaJson) {
        return Media.fromJson(mediaJson);
      }).toList();
    } else if (json['tour_stop_media'] is List) {
      mediaList = (json['tour_stop_media'] as List).map((tsm) {
        return Media.fromJson(tsm['media']);
      }).toList();
    }

    return TourStop(
      id: json['id'] ?? 0,
      sequenceNo: json['sequence_no'] ?? 0,
      stopName: json['stop_name'] ?? '',
      description: json['description'],
      location: json['location'] != null ? Location.fromJson(json['location']) : null,
      media: mediaList,
    );
  }

  List<String> get mediaUrls => media.map((m) => MediaService.getFullUrl(m.url)).toList();
}

class Media {
  final int id;
  final String url;
  final MediaType mediaType;
  final int? durationSeconds;
  final int? width;
  final int? height;

  Media({
    required this.id,
    required this.url,
    required this.mediaType,
    this.durationSeconds,
    this.width,
    this.height,
  });

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      id: json['id'] ?? 0,
      url: json['url'] ?? '',
      mediaType: _parseMediaType(json['media_type']),
      durationSeconds: json['duration_seconds'],
      width: json['width'],
      height: json['height'],
    );
  }

  static MediaType _parseMediaType(String? type) {
    switch (type) {
      case 'audio':
        return MediaType.audio;
      case 'image':
      default:
        return MediaType.image;
    }
  }
}

class Location {
  final int id;
  final double longitude;
  final double latitude;
  final String? address;
  final String? city;
  final String? province;
  final String? district;
  final String? postalCode;

  Location({
    required this.id,
    required this.longitude,
    required this.latitude,
    this.address,
    this.city,
    this.province,
    this.district,
    this.postalCode,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'] ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      address: json['address'],
      city: json['city'],
      province: json['province'],
      district: json['district'],
      postalCode: json['postal_code'],
    );
  }

  String get formattedAddress {
    final parts = [address, city, district, province].where((part) => part != null && part!.isNotEmpty).toList();
    return parts.isNotEmpty ? parts.join(', ') : 'Location details not available';
  }
}

class TravelGuide {
  final int id;
  final int userId;
  final List<String> verificationDocuments;
  final int? yearsOfExperience;
  final List<String> languagesSpoken;
  final User user;

  TravelGuide({
    required this.id,
    required this.userId,
    required this.verificationDocuments,
    this.yearsOfExperience,
    required this.languagesSpoken,
    required this.user,
  });

  factory TravelGuide.fromJson(Map<String, dynamic> json) {
    return TravelGuide(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      verificationDocuments: List<String>.from(json['verification_documents'] ?? []),
      yearsOfExperience: json['years_of_experience'],
      languagesSpoken: List<String>.from(json['languages_spoken'] ?? []),
      user: User.fromJson(json['user'] ?? {}),
    );
  }
}

class User {
  final int id;
  final String name;
  final String? profilePictureUrl;
  final String? bio;
  final UserRole role;

  User({
    required this.id,
    required this.name,
    this.profilePictureUrl,
    this.bio,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      profilePictureUrl: json['profile_picture_url'],
      bio: json['bio'],
      role: _parseUserRole(json['role']),
    );
  }

  static UserRole _parseUserRole(String? role) {
    switch (role) {
      case 'admin':
        return UserRole.admin;
      case 'moderator':
        return UserRole.moderator;
      case 'travel_guide':
        return UserRole.travel_guide;
      case 'vendor':
        return UserRole.vendor;
      case 'traveler':
      default:
        return UserRole.traveler;
    }
  }

  String get profilePictureUrlFormatted => MediaService.getProfilePictureUrl(profilePictureUrl);
}

enum PackageStatus {
  pending_approval,
  published,
  rejected,
}

enum MediaType {
  image,
  audio,
}

enum UserRole {
  admin,
  moderator,
  traveler,
  travel_guide,
  vendor,
}