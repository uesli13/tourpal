import 'base_exception.dart';

/// Authentication-specific validation exceptions
/// 
/// Used when authentication input fails validation rules
class AuthValidationException extends ValidationException {
  const AuthValidationException(super.message, [super.code]);

  /// Email validation failed
  static const AuthValidationException invalidEmail = 
    AuthValidationException('Please enter a valid email address', 'INVALID_EMAIL');

  /// Password validation failed
  static const AuthValidationException invalidPassword = 
    AuthValidationException('Password must be at least 6 characters', 'INVALID_PASSWORD');

  /// Name validation failed for signup
  static const AuthValidationException invalidName = 
    AuthValidationException('Name is required and must be 1-50 characters', 'INVALID_NAME');

  /// Password confirmation doesn't match
  static const AuthValidationException passwordMismatch = 
    AuthValidationException('Password confirmation does not match', 'PASSWORD_MISMATCH');
}

/// Authentication service exceptions
/// 
/// Used when Firebase Auth operations fail
class AuthServiceException extends ServiceException {
  const AuthServiceException(super.message, [super.code]);

  /// Email already in use
  static const AuthServiceException emailAlreadyInUse = 
    AuthServiceException('This email is already registered. Please sign in instead.', 'EMAIL_ALREADY_IN_USE');

  /// Invalid credentials
  static const AuthServiceException invalidCredentials = 
    AuthServiceException('Invalid email or password. Please try again.', 'INVALID_CREDENTIALS');

  /// User disabled
  static const AuthServiceException userDisabled = 
    AuthServiceException('This account has been disabled. Contact support.', 'USER_DISABLED');

  /// Too many requests
  static const AuthServiceException tooManyRequests = 
    AuthServiceException('Too many failed attempts. Please try again later.', 'TOO_MANY_REQUESTS');

  /// Google Sign-In failed
  static const AuthServiceException googleSignInFailed = 
    AuthServiceException('Google Sign-In failed. Please try again.', 'GOOGLE_SIGNIN_FAILED');

  /// Sign out failed
  static const AuthServiceException signOutFailed = 
    AuthServiceException('Sign out failed. Please try again.', 'SIGNOUT_FAILED');

  /// Email verification failed
  static const AuthServiceException emailVerificationFailed = 
    AuthServiceException('Failed to send verification email', 'EMAIL_VERIFICATION_FAILED');

  /// Password reset failed
  static const AuthServiceException passwordResetFailed = 
    AuthServiceException('Failed to send password reset email', 'PASSWORD_RESET_FAILED');
}

/// Authentication state exceptions
/// 
/// Used when authentication state is invalid for requested operation
class AuthStateException extends AuthException {
  const AuthStateException(super.message, [super.code]);

  /// User not authenticated
  static const AuthStateException notAuthenticated = 
    AuthStateException('You must be signed in to access this feature', 'NOT_AUTHENTICATED');

  /// Email not verified
  static const AuthStateException emailNotVerified = 
    AuthStateException('Please verify your email before continuing', 'EMAIL_NOT_VERIFIED');

  /// Account incomplete
  static const AuthStateException incompleteProfile = 
    AuthStateException('Please complete your profile setup', 'INCOMPLETE_PROFILE');

  /// Session expired
  static const AuthStateException sessionExpired = 
    AuthStateException('Your session has expired. Please sign in again.', 'SESSION_EXPIRED');
}

/// Authentication network exceptions
/// 
/// Used when network operations fail during authentication
class AuthNetworkException extends NetworkException {
  const AuthNetworkException(super.message, [super.code]);

  /// No internet connection
  static const AuthNetworkException noConnection = 
    AuthNetworkException('No internet connection. Authentication requires network access.', 'NO_CONNECTION');

  /// Request timeout
  static const AuthNetworkException timeout = 
    AuthNetworkException('Authentication request timed out. Please try again.', 'TIMEOUT');

  /// Firebase service unavailable
  static const AuthNetworkException serviceUnavailable = 
    AuthNetworkException('Authentication service temporarily unavailable', 'SERVICE_UNAVAILABLE');

  /// Network error during Google Sign-In
  static const AuthNetworkException googleNetworkError = 
    AuthNetworkException('Network error during Google Sign-In', 'GOOGLE_NETWORK_ERROR');
}