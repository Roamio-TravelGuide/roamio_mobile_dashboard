// services/media_service.dart
class MediaService {
  static const String baseUrl = 'http://localhost:3001'; // Your backend URL

  static String getFullUrl(String mediaPath) {
    if (mediaPath.startsWith('http')) {
      return mediaPath;
    }
    
    // Handle different path formats for images stored in public/uploads
    String cleanPath = mediaPath;
    
    // Remove leading slash if present
    if (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }
    
    // The server serves files from /uploads route which maps to public/uploads directory
    // So we need to construct URLs like: http://localhost:3001/uploads/filename
    
    if (cleanPath.startsWith('public/uploads/')) {
      // Remove 'public/' prefix since server serves from /uploads
      cleanPath = cleanPath.substring(7); // Remove 'public/'
    } else if (cleanPath.startsWith('uploads/')) {
      // Already has uploads/ prefix, keep as is
    } else if (!cleanPath.startsWith('uploads/')) {
      // Add uploads/ prefix for bare filenames or other paths
      cleanPath = 'uploads/$cleanPath';
    }
    
    final fullUrl = '$baseUrl/$cleanPath';
    print('MediaService: Converting "$mediaPath" to "$fullUrl"');
    return fullUrl;
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