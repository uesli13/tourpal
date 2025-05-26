/// Base exception class for all TourPal custom exceptions
/// 
/// Provides a foundation for structured error handling across the app
/// following the TOURPAL DEVELOPMENT RULES
abstract class TourPalException implements Exception {
  const TourPalException(this.message, [this.code]);

  /// Human-readable error message
  final String message;
  
  /// Optional error code for programmatic handling
  final String? code;

  @override
  String toString() => '$runtimeType: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Base class for validation-related exceptions
abstract class ValidationException extends TourPalException {
  const ValidationException(super.message, [super.code]);
}

/// Base class for service-related exceptions
abstract class ServiceException extends TourPalException {
  const ServiceException(super.message, [super.code]);
}

/// Base class for authentication-related exceptions
abstract class AuthException extends TourPalException {
  const AuthException(super.message, [super.code]);
}

/// Base class for network-related exceptions
abstract class NetworkException extends TourPalException {
  const NetworkException(super.message, [super.code]);
}