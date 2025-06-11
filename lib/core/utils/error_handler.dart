import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';

import '../exceptions/app_exceptions.dart';
import 'logger.dart';

/// Centralized error handler for consistent error processing across the app
class ErrorHandler {
  static const String _className = 'ErrorHandler';

  /// Handles and transforms exceptions into appropriate AppException types
  static AppException handleError(
    dynamic error, {
    String? context,
    String? operation,
    Map<String, dynamic>? metadata,
  }) {
    AppLogger.error('$_className: Handling error in $operation', error);

    // Firebase exceptions
    if (error is FirebaseException) {
      return _handleFirebaseException(error, context: context, metadata: metadata);
    }

    // Firebase Auth exceptions
    if (error is FirebaseAuthException) {
      return _handleFirebaseAuthException(error, context: context, metadata: metadata);
    }

    // Socket/Network exceptions
    if (error is SocketException) {
      return NetworkException.noConnection();
    }

    // Timeout exceptions
    if (error is TimeoutException) {
      return NetworkException.timeout();
    }

    // Already handled AppExceptions - just pass through
    if (error is AppException) {
      return error;
    }

    // Generic exception fallback
    return UnknownException(
      error.toString(),
      code: 'UNKNOWN_ERROR',
      severity: ErrorSeverity.error,
    );
  }

  /// Handles Firebase-specific exceptions
  static AppException _handleFirebaseException(
    FirebaseException error, {
    String? context,
    Map<String, dynamic>? metadata,
  }) {
    switch (error.code) {
      case 'permission-denied':
        return DatabaseException.permissionDenied();
      case 'not-found':
        return DatabaseException.notFound(context ?? 'Resource');
      case 'unavailable':
        return NetworkException.serverError();
      case 'deadline-exceeded':
        return NetworkException.timeout();
      default:
        return DatabaseException(
          error.message ?? 'Database operation failed',
          code: error.code,
          context: metadata,
          originalException: error,
        );
    }
  }

  /// Handles Firebase Auth-specific exceptions
  static AppException _handleFirebaseAuthException(
    FirebaseAuthException error, {
    String? context,
    Map<String, dynamic>? metadata,
  }) {
    switch (error.code) {
      case 'user-not-found':
        return AuthenticationException.userNotFound();
      case 'wrong-password':
      case 'invalid-credential':
        return AuthenticationException.invalidCredentials();
      case 'user-disabled':
        return const AuthenticationException(
          'This account has been disabled',
          code: 'AUTH_USER_DISABLED',
        );
      case 'too-many-requests':
        return const AuthenticationException(
          'Too many failed attempts. Please try again later',
          code: 'AUTH_TOO_MANY_REQUESTS',
        );
      case 'email-already-in-use':
        return const AuthenticationException(
          'An account with this email already exists',
          code: 'AUTH_EMAIL_IN_USE',
        );
      case 'weak-password':
        return const ValidationException(
          'Password is too weak. Please use at least 6 characters',
          field: 'password',
          code: 'AUTH_WEAK_PASSWORD',
        );
      case 'invalid-email':
        return const ValidationException(
          'Please enter a valid email address',
          field: 'email',
          code: 'AUTH_INVALID_EMAIL',
        );
      case 'network-request-failed':
        return NetworkException.noConnection();
      default:
        return AuthenticationException(
          error.message ?? 'Authentication failed',
          code: error.code,
          context: metadata,
          originalException: error,
        );
    }
  }

  /// Logs error with appropriate severity and context
  static void logError(
    AppException error, {
    String? operation,
    String? service,
    Map<String, dynamic>? context,
  }) {
    final logContext = {
      'operation': operation,
      'service': service,
      'errorCode': error.code,
      'severity': error.severity.name,
      ...?error.context,
      ...?context,
    };

    switch (error.severity) {
      case ErrorSeverity.debug:
        AppLogger.debug(error.userMessage, logContext);
        break;
      case ErrorSeverity.info:
        AppLogger.info(error.userMessage, logContext);
        break;
      case ErrorSeverity.warning:
        AppLogger.warning(error.userMessage, logContext);
        break;
      case ErrorSeverity.error:
        AppLogger.error(error.userMessage, logContext);
        break;
      case ErrorSeverity.critical:
        AppLogger.critical(error.userMessage, logContext);
        break;
    }
  }

  /// Extracts user-friendly error message for UI display
  static String getUserMessage(AppException error) {
    return error.userMessage;
  }

  /// Determines if error should trigger a retry mechanism
  static bool shouldRetry(AppException error) {
    if (error is NetworkException) {
      return error.code != 'NETWORK_NO_CONNECTION';
    }
    
    if (error is DatabaseException) {
      return error.code != 'DATABASE_PERMISSION_DENIED';
    }
    
    if (error is AuthenticationException) {
      return error.code == 'AUTH_SESSION_EXPIRED';
    }
    
    return false;
  }

  /// Determines if error should be shown to user or handled silently
  static bool shouldShowToUser(AppException error) {
    // Don't show debug/info level errors to users
    return error.severity.index >= ErrorSeverity.warning.index;
  }

  /// Handles service-level errors with operation context
  static AppException handleServiceError(
    dynamic error, {
    String? operation,
    String? serviceName,
    Map<String, dynamic>? context,
  }) {
    final fullContext = {
      'service': serviceName,
      'operation': operation,
      ...?context,
    };

    final appException = handleError(
      error,
      context: operation,
      operation: operation,
      metadata: fullContext,
    );

    // Log the error with service context
    logError(
      appException,
      operation: operation,
      service: serviceName,
      context: fullContext,
    );

    return appException;
  }
}