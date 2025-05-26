/// Custom exceptions for profile operations following TOURPAL DEVELOPMENT RULES
abstract class ProfileException implements Exception {
  final String message;
  const ProfileException(this.message);
  
  @override
  String toString() => 'ProfileException: $message';
}

/// Thrown when profile input validation fails
class ProfileValidationException extends ProfileException {
  const ProfileValidationException(super.message);
  
  /// Invalid name validation
  static const ProfileValidationException invalidName = 
    ProfileValidationException('Name is required and must be 1-50 characters');
    
  /// Invalid bio validation
  static const ProfileValidationException invalidBio = 
    ProfileValidationException('Bio must be 150 characters or less');
    
  /// Invalid email validation
  static const ProfileValidationException invalidEmail = 
    ProfileValidationException('Please enter a valid email address');
    
  /// Weak password validation
  static const ProfileValidationException weakPassword = 
    ProfileValidationException('Password must be at least 8 characters with uppercase, lowercase, and number');
    
  /// Invalid image validation
  static const ProfileValidationException invalidImage = 
    ProfileValidationException('Image must be JPG/PNG format and under 5MB');
  
  @override
  String toString() => 'ProfileValidationException: $message';
}

/// Thrown when profile service operations fail
class ProfileServiceException extends ProfileException {
  const ProfileServiceException(super.message);
  
  @override
  String toString() => 'ProfileServiceException: $message';
}

/// Thrown when profile authentication fails
class ProfileAuthException extends ProfileException {
  const ProfileAuthException(super.message);
  
  @override
  String toString() => 'ProfileAuthException: $message';
}

/// Thrown when profile network operations fail
class ProfileNetworkException extends ProfileException {
  const ProfileNetworkException(super.message);
  
  @override
  String toString() => 'ProfileNetworkException: $message';
}