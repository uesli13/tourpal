class FirebaseConfig {
  // Firebase configuration will be handled by firebase_options.dart
  // This file can contain additional Firebase-specific configurations
  
  static const int timeoutSeconds = 30;
  static const int retryAttempts = 3;
  
  // Collection names
  static const String usersCollection = 'users';
  static const String toursCollection = 'tours';
  static const String bookingsCollection = 'bookings';
  static const String reviewsCollection = 'reviews';
  static const String notificationsCollection = 'notifications';
  
  // Storage paths
  static const String userProfilesPath = 'users';
  static const String tourImagesPath = 'tours';
  static const String reviewImagesPath = 'reviews';
  static const String tempUploadsPath = 'temp';
}