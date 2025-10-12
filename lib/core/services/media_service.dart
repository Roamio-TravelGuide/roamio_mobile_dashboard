// services/media_service.dart
class MediaService {
  static const String baseUrl = 'http://localhost:3001'; // Your backend URL

  static String getFullUrl(String mediaPath) {
    if (mediaPath.startsWith('http')) {
      return mediaPath;
    }
    
    // Remove any leading slashes to avoid double slashes
    final cleanPath = mediaPath.startsWith('/') ? mediaPath.substring(1) : mediaPath;
    return '$baseUrl/$cleanPath';
  }

  static String getCoverImageUrl(String? mediaPath) {
    if (mediaPath == null || mediaPath.isEmpty) {
      return 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?ixlib=rb-4.0.3&auto=format&fit=crop&w=1000&q=80'; // Default image
    }
    return getFullUrl(mediaPath);
  }

  static String getProfilePictureUrl(String? profilePicturePath) {
    if (profilePicturePath == null || profilePicturePath.isEmpty) {
      return 'https://via.placeholder.com/150/cccccc/666666?text=User';
    }
    return getFullUrl(profilePicturePath);
  }
}