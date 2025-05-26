/// TOURPAL App Constants - UNIFIED VERSION
/// Central location for all application constants following TOURPAL development rules
library;


class AppInfo {
  static const String name = 'TOURPAL';
  static const String version = '1.0.0';
  static const String buildNumber = '1';
  static const String description = 'Your Personal Tour Guide - Discover and create incredible tours';
}

class ApiConstants {
  // Base URLs
  static const String baseUrl = 'https://api.tourpal.com/v1';
  
  // Endpoints
  static const String placesEndpoint = '/places';
  static const String toursEndpoint = '/tours';
  static const String usersEndpoint = '/users';
  static const String reviewsEndpoint = '/reviews';
  
  // Timeouts
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
  
  // Retry
  static const int maxRetryAttempts = 3;
}

class FirebaseCollections {
  static const String users = 'users';
  static const String tours = 'tours';
  static const String places = 'places';
  static const String reviews = 'reviews';
  static const String messages = 'messages';
  static const String conversations = 'conversations';
  static const String notifications = 'notifications';
  static const String journals = 'journals';
  static const String tourPlans = 'tourPlans';
}

class StoragePaths {
  static const String profileImages = 'users/{userId}/profile';
  static const String tourImages = 'tours/{tourId}/images';
  static const String placeImages = 'places/{placeId}/images';
  static const String messageImages = 'messages/{messageId}/images';
  static const String tempUploads = 'temp/{userId}';
  static const String testUploads = 'test_uploads/{userId}';
}

class UIConstants {
  // Padding
  static const double paddingXSmall = 4.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  static const double defaultPadding = 16.0;
  
  // Border Radius
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 12.0;
  static const double borderRadiusXLarge = 16.0;
  static const double defaultBorderRadius = 12.0;
  
  // Elevation
  static const double elevationLow = 1.0;
  static const double elevationMedium = 2.0;
  static const double elevationHigh = 4.0;
  static const double elevationXHigh = 8.0;
  static const double defaultElevation = 2.0;
  static const double cardElevation = 4.0;
  static const double buttonElevation = 1.0;
  
  // Font Sizes
  static const double fontSizeCaption = 12.0;
  static const double fontSizeBody = 16.0;
  static const double fontSizeTitle = 20.0;
  static const double fontSizeHeadline = 24.0;
  static const double fontSizeDisplay = 32.0;
}

class AnimationDurations {
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration extraSlow = Duration(milliseconds: 800);
  static const Duration defaultDuration = Duration(milliseconds: 300);
}

class ValidationConstants {
  // Text Lengths
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 128;
  static const int maxBioLength = 150;
  static const int maxMessageLength = 500;
  static const int maxTourNameLength = 100;
  static const int maxTourDescriptionLength = 1000;
  
  // Patterns
  static const String emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String strongPasswordPattern = r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+$';
  
  // File Constraints
  static const int maxImageSizeMB = 5;
  static const int maxImagesPerTour = 10;
  static const List<String> allowedImageFormats = ['jpg', 'jpeg', 'png', 'webp'];
}

class MapConstants {
  static const double defaultZoom = 15.0;
  static const double minZoom = 5.0;
  static const double maxZoom = 20.0;
  
  // Default location (Coimbra, Portugal - ICM area)
  static const double defaultLatitude = 40.63331744571426;
  static const double defaultLongitude = -8.659457453141433;
  
  // Map behavior
  static const double clusterRadius = 50.0;
  static const double locationAccuracy = 10.0; // meters
}

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String profileSetup = '/profile-setup';
  static const String main = '/main';
  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';
  static const String settings = '/settings';
  static const String tours = '/tours';
  static const String tourDetails = '/tours/details';
  static const String tourCreate = '/tours/create';
  static const String tourEdit = '/tours/edit';
  static const String messages = '/messages';
  static const String chat = '/messages/chat';
  static const String journals = '/journals';
  static const String journalDetails = '/journals/details';
  static const String journalCreate = '/journals/create';
  static const String journalEdit = '/journals/edit';
}

class StorageKeys {
  static const String userToken = 'user_token';
  static const String userId = 'user_id';
  static const String themeMode = 'theme_mode';
  static const String language = 'language';
  static const String firstTime = 'first_time';
  static const String profileCompleted = 'profile_completed';
}

class CacheConstants {
  static const Duration userCacheDuration = Duration(hours: 1);
  static const Duration tourCacheDuration = Duration(hours: 24);
  static const Duration imageCacheDuration = Duration(days: 7);
  static const int maxCachedImages = 100;
  static const int maxCachedTours = 50;
  static const int maxCacheSize = 100; // MB
}

class AssetPaths {
  static const String images = 'assets/images/';
  static const String icons = 'assets/icons/';
  static const String animations = 'assets/animations/';
  
  // Specific assets
  static const String appLogo = 'assets/images/tourpal_logo.png';
  static const String appIcon = 'assets/images/app_icon.png';
  static const String googleLogo = 'assets/images/google_logo.png';
  static const String placeholderImage = 'assets/images/placeholder.png';
}

class ErrorMessages {
  static const String networkError = 'Network connection error. Please check your internet connection.';
  static const String serverError = 'Server error. Please try again later.';
  static const String unknownError = 'An unknown error occurred. Please try again.';
  static const String authError = 'Authentication error. Please sign in again.';
  static const String permissionError = 'Permission denied. Please check your permissions.';
  static const String notFoundError = 'Requested resource not found.';
  static const String timeoutError = 'Request timeout. Please try again.';
  static const String validationError = 'Please check your input and try again.';
  static const String storageError = 'Storage operation failed. Please try again.';
  static const String genericError = 'Something went wrong. Please try again.';
}

class SuccessMessages {
  static const String profileUpdated = '🎉 Profile updated successfully!';
  static const String profileSetupComplete = '🎉 Profile setup complete! Welcome to TourPal!';
  static const String tourCreated = '✅ Tour created successfully!';
  static const String tourUpdated = '✅ Tour updated successfully!';
  static const String tourDeleted = '✅ Tour deleted successfully!';
  static const String reviewSubmitted = '✅ Review submitted successfully!';
  static const String messageSent = '✅ Message sent successfully!';
  static const String passwordUpdated = '🔒 Password updated successfully!';
  static const String emailUpdated = '📧 Email updated successfully!';
  static const String imageUploaded = '📸 Image uploaded successfully!';
  static const String dataSaved = '💾 Data saved successfully!';
}

class InfoMessages {
  static const String loading = 'Loading...';
  static const String uploading = 'Uploading...';
  static const String processing = 'Processing...';
  static const String saving = 'Saving...';
  static const String noData = 'No data available';
  static const String noResults = 'No results found';
  static const String comingSoon = 'Coming soon!';
  static const String offlineMode = 'You are currently offline';
}

class FeatureFlags {
  static const bool enableGoogleMaps = true;
  static const bool enableOfflineMode = true;
  static const bool enableAudioGuides = true;
  static const bool enableMessaging = true;
  static const bool enableJournals = true;
  static const bool enableNotifications = true;
  static const bool enableReviews = true;
  static const bool enableAdvancedSearch = true;
  static const bool enableDataExport = false;
  static const bool enableBetaFeatures = false;
  static const bool enableDebugMode = true; // TODO: Should be false in production
}

class AppSettings {
  // Performance
  static const int maxConcurrentRequests = 5;
  static const int imageCacheSize = 50; // MB
  static const int databaseCacheSize = 10; // MB
  
  // UI Behavior
  static const Duration splashScreenDuration = Duration(seconds: 2);
  static const Duration snackBarDuration = Duration(seconds: 4);
  static const Duration tooltipDuration = Duration(seconds: 3);
  
  // Notifications
  static const bool enablePushNotifications = true;
  static const bool enableEmailNotifications = true;
  static const bool enableSoundNotifications = true;
  
  // Location
  static const double locationUpdateInterval = 10.0; // seconds
  static const double locationAccuracyThreshold = 50.0; // meters
}

/// Layout options for tour cards
enum TourCardLayout {
  vertical,
  horizontal,
}