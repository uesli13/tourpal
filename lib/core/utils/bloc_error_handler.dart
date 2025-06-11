import '../exceptions/app_exceptions.dart';
import '../utils/error_handler.dart';
import '../utils/logger.dart';

/// Utility class for standardized error handling in BLoCs
/// 
/// This class provides consistent error handling patterns that should be used
/// across all BLoCs in the TourPal application.
class BlocErrorHandler {
  
  /// Handles errors consistently across all BLoCs
  /// 
  /// This method should be called in all catch blocks within BLoC event handlers.
  /// It will:
  /// 1. Transform generic exceptions into AppExceptions
  /// 2. Log the error with appropriate context
  /// 3. Return the appropriate error state
  /// 
  /// Example usage:
  /// ```dart
  /// try {
  ///   // some operation
  /// } catch (error) {
  ///   final errorState = BlocErrorHandler.handleError(
  ///     error,
  ///     operation: 'loadProfile',
  ///     context: {'userId': userId},
  ///     createErrorState: (e) => ProfileError.fromException(e),
  ///   );
  ///   emit(errorState);
  /// }
  /// ```
  static S handleError<S>(
    dynamic error, {
    required String operation,
    required S Function(AppException error) createErrorState,
    String? service,
    Map<String, dynamic>? context,
  }) {
    final stopwatch = Stopwatch()..start();
    
    // Transform to AppException if needed
    final appException = ErrorHandler.handleError(
      error,
      operation: operation,
      context: operation,
      metadata: context,
    );

    // Log the error
    ErrorHandler.logError(
      appException,
      operation: operation,
      service: service ?? 'BLoC',
      context: context,
    );

    // Log performance if operation was being timed
    stopwatch.stop();
    if (service != null) {
      AppLogger.performance('$operation (failed)', stopwatch.elapsed);
      AppLogger.serviceOperation(service, operation, false);
    }

    // Return error state
    return createErrorState(appException);
  }

  /// Logs BLoC events consistently
  static void logEvent(String blocName, String eventName, [Map<String, dynamic>? context]) {
    AppLogger.blocEvent(blocName, eventName);
    if (context != null) {
      AppLogger.debug('$blocName event context', context);
    }
  }

  /// Logs BLoC state transitions consistently
  static void logTransition(String blocName, String currentState, String nextState) {
    AppLogger.blocTransition(blocName, currentState, nextState);
  }

  /// Wraps async operations with consistent error handling and performance logging
  /// 
  /// Example usage:
  /// ```dart
  /// await BlocErrorHandler.executeWithErrorHandling(
  ///   operation: () => profileService.updateProfile(user),
  ///   onSuccess: (user) => emit(ProfileLoaded(user)),
  ///   onError: (error) => emit(ProfileError.fromException(error)),
  ///   operationName: 'updateProfile',
  ///   serviceName: 'ProfileService',
  /// );
  /// ```
  static Future<void> executeWithErrorHandling<T>({
    required Future<T> Function() operation,
    required Function(T result) onSuccess,
    required Function(AppException error) onError,
    required String operationName,
    String? serviceName,
    Map<String, dynamic>? context,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      AppLogger.info('Starting $operationName');
      
      final result = await operation();
      
      stopwatch.stop();
      AppLogger.performance(operationName, stopwatch.elapsed);
      
      if (serviceName != null) {
        AppLogger.serviceOperation(serviceName, operationName, true);
      }
      
      onSuccess(result);
      
    } catch (error) {
      final appException = ErrorHandler.handleError(
        error,
        operation: operationName,
        context: operationName,
        metadata: context,
      );

      ErrorHandler.logError(
        appException,
        operation: operationName,
        service: serviceName ?? 'BLoC',
        context: context,
      );

      stopwatch.stop();
      if (serviceName != null) {
        AppLogger.performance('$operationName (failed)', stopwatch.elapsed);
        AppLogger.serviceOperation(serviceName, operationName, false);
      }

      onError(appException);
    }
  }
}

/// Base class for standardized error states
/// 
/// All BLoCs should have error states that implement this interface
/// to ensure consistent error handling patterns.
abstract class BaseErrorState {
  final String message;
  final String? errorCode;
  final ErrorSeverity severity;
  final bool canRetry;
  final Map<String, dynamic>? context;

  const BaseErrorState({
    required this.message,
    this.errorCode,
    this.severity = ErrorSeverity.error,
    this.canRetry = false,
    this.context,
  });

  /// Factory constructor for creating error states from AppExceptions
  static BaseErrorState fromException(AppException exception) {
    return _StandardErrorState(
      message: exception.userMessage,
      errorCode: exception.code,
      severity: exception.severity,
      canRetry: ErrorHandler.shouldRetry(exception),
      context: exception.context,
    );
  }
}

/// Private implementation of BaseErrorState
class _StandardErrorState extends BaseErrorState {
  const _StandardErrorState({
    required super.message,
    super.errorCode,
    super.severity,
    super.canRetry,
    super.context,
  });
}

/// Validation result helper for consistent validation patterns
class ValidationResult {
  final bool isValid;
  final List<ValidationException> errors;

  const ValidationResult({
    required this.isValid,
    this.errors = const [],
  });

  factory ValidationResult.valid() => const ValidationResult(isValid: true);
  
  factory ValidationResult.invalid(List<ValidationException> errors) => 
      ValidationResult(isValid: false, errors: errors);

  /// Gets the first error message, or null if valid
  String? get firstError => errors.isNotEmpty ? errors.first.userMessage : null;

  /// Gets all error messages
  List<String> get errorMessages => errors.map((e) => e.userMessage).toList();
}