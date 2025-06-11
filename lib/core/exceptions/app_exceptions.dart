/// Base exception class for all TourPal application errors
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final ErrorSeverity severity;
  final Map<String, dynamic>? context;
  final Exception? originalException;

  const AppException(
    this.message, {
    this.code,
    this.severity = ErrorSeverity.error,
    this.context,
    this.originalException,
  });

  @override
  String toString() => 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
  
  /// Returns user-friendly error message
  String get userMessage => message;
  
  /// Returns technical error details for logging
  String get technicalDetails => toString();
}

/// Error severity levels for better error handling and logging
enum ErrorSeverity {
  debug,
  info, 
  warning,
  error,
  critical,
}

/// Network-related exceptions
class NetworkException extends AppException {
  const NetworkException(
    super.message, {
    super.code,
    super.severity = ErrorSeverity.error,
    super.context,
    super.originalException,
  });

  factory NetworkException.noConnection() => const NetworkException(
    'No internet connection available',
    code: 'NETWORK_NO_CONNECTION',
  );

  factory NetworkException.timeout() => const NetworkException(
    'Request timeout. Please try again',
    code: 'NETWORK_TIMEOUT',
  );

  factory NetworkException.serverError() => const NetworkException(
    'Server error. Please try again later',
    code: 'NETWORK_SERVER_ERROR',
  );
}

/// Database-related exceptions
class DatabaseException extends AppException {
  const DatabaseException(
    super.message, {
    super.code,
    super.severity = ErrorSeverity.error,
    super.context,
    super.originalException,
  });

  factory DatabaseException.notFound(String resource) => DatabaseException(
    '$resource not found',
    code: 'DATABASE_NOT_FOUND',
    context: {'resource': resource},
  );

  factory DatabaseException.permissionDenied() => const DatabaseException(
    'Permission denied to access data',
    code: 'DATABASE_PERMISSION_DENIED',
  );
}

/// Input validation exceptions
class ValidationException extends AppException {
  final String field;
  
  const ValidationException(
    super.message, {
    required this.field,
    super.code,
    super.severity = ErrorSeverity.warning,
    super.context,
  });

  factory ValidationException.required(String field) => ValidationException(
    '$field is required',
    field: field,
    code: 'VALIDATION_REQUIRED',
  );

  factory ValidationException.invalid(String field, String reason) => ValidationException(
    'Invalid $field: $reason',
    field: field,
    code: 'VALIDATION_INVALID',
  );
}

/// Authentication-related exceptions
class AuthenticationException extends AppException {
  const AuthenticationException(
    super.message, {
    super.code,
    super.severity = ErrorSeverity.error,
    super.context,
    super.originalException,
  });

  factory AuthenticationException.invalidCredentials() => const AuthenticationException(
    'Invalid email or password',
    code: 'AUTH_INVALID_CREDENTIALS',
  );

  factory AuthenticationException.userNotFound() => const AuthenticationException(
    'No account found with this email',
    code: 'AUTH_USER_NOT_FOUND',
  );

  factory AuthenticationException.sessionExpired() => const AuthenticationException(
    'Your session has expired. Please sign in again',
    code: 'AUTH_SESSION_EXPIRED',
    severity: ErrorSeverity.warning,
  );
}

/// Storage-related exceptions
class StorageException extends AppException {
  const StorageException(
    super.message, {
    super.code,
    super.severity = ErrorSeverity.error,
    super.context,
    super.originalException,
  });

  factory StorageException.uploadFailed() => const StorageException(
    'Failed to upload file. Please try again',
    code: 'STORAGE_UPLOAD_FAILED',
  );

  factory StorageException.fileTooLarge() => const StorageException(
    'File is too large. Maximum size is 10MB',
    code: 'STORAGE_FILE_TOO_LARGE',
  );
}

// Feature-specific exceptions following TOURPAL rules
class ProfileException extends AppException {
  const ProfileException(
    super.message, {
    super.code,
    super.severity = ErrorSeverity.error,
    super.context,
    super.originalException,
  });
}

/// Generic concrete exception for unknown errors
class UnknownException extends AppException {
  const UnknownException(
    super.message, {
    super.code,
    super.severity = ErrorSeverity.error,
    super.context,
    super.originalException,
  });
}

class ProfileValidationException extends ProfileException {
  const ProfileValidationException(super.message, {super.code, super.context})
      : super(severity: ErrorSeverity.warning);
}

class ProfileServiceException extends ProfileException {
  const ProfileServiceException(super.message, {super.code, super.context});
}

class GuideException extends AppException {
  const GuideException(
    super.message, {
    super.code,
    super.severity = ErrorSeverity.error,
    super.context,
    super.originalException,
  });
}

class GuideValidationException extends GuideException {
  const GuideValidationException(super.message, {super.code, super.context})
      : super(severity: ErrorSeverity.warning);
}

class GuideServiceException extends GuideException {
  const GuideServiceException(super.message, {super.code, super.context});
}

class TourException extends AppException {
  const TourException(
    super.message, {
    super.code,
    super.severity = ErrorSeverity.error,
    super.context,
    super.originalException,
  });
}

class TourValidationException extends TourException {
  const TourValidationException(super.message, {super.code, super.context})
      : super(severity: ErrorSeverity.warning);
}

class TourServiceException extends TourException {
  const TourServiceException(super.message, {super.code, super.context});
}

class BookingException extends AppException {
  const BookingException(
    super.message, {
    super.code,
    super.severity = ErrorSeverity.error,
    super.context,
    super.originalException,
  });
}

class BookingValidationException extends BookingException {
  const BookingValidationException(super.message, {super.code, super.context})
      : super(severity: ErrorSeverity.warning);
}

class BookingServiceException extends BookingException {
  const BookingServiceException(super.message, {super.code, super.context});
}

class ReviewException extends AppException {
  const ReviewException(
    super.message, {
    super.code,
    super.severity = ErrorSeverity.error,
    super.context,
    super.originalException,
  });
}

class ReviewValidationException extends ReviewException {
  const ReviewValidationException(super.message, {super.code, super.context})
      : super(severity: ErrorSeverity.warning);
}

class ReviewServiceException extends ReviewException {
  const ReviewServiceException(super.message, {super.code, super.context});
}

class MessageException extends AppException {
  const MessageException(
    super.message, {
    super.code,
    super.severity = ErrorSeverity.error,
    super.context,
    super.originalException,
  });
}

class MessageValidationException extends MessageException {
  const MessageValidationException(super.message, {super.code, super.context})
      : super(severity: ErrorSeverity.warning);
}

class MessageServiceException extends MessageException {
  const MessageServiceException(super.message, {super.code, super.context});
}

class JournalException extends AppException {
  const JournalException(
    super.message, {
    super.code,
    super.severity = ErrorSeverity.error,
    super.context,
    super.originalException,
  });
}

class JournalValidationException extends JournalException {
  const JournalValidationException(super.message, {super.code, super.context})
      : super(severity: ErrorSeverity.warning);
}

class JournalServiceException extends JournalException {
  const JournalServiceException(super.message, {super.code, super.context});
}

class DashboardException extends AppException {
  const DashboardException(
    super.message, {
    super.code,
    super.severity = ErrorSeverity.error,
    super.context,
    super.originalException,
  });
}

class DashboardValidationException extends DashboardException {
  const DashboardValidationException(super.message, {super.code, super.context})
      : super(severity: ErrorSeverity.warning);
}

class DashboardServiceException extends DashboardException {
  const DashboardServiceException(super.message, {super.code, super.context});
}