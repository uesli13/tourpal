import 'package:equatable/equatable.dart';
import 'package:tourpal/core/utils/bloc_error_handler.dart';
import 'package:tourpal/core/utils/error_handler.dart';
import 'package:tourpal/core/exceptions/app_exceptions.dart';
import 'package:tourpal/models/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthSigningIn extends AuthState {
  const AuthSigningIn();
}

class AuthSigningUp extends AuthState {
  const AuthSigningUp();
}

class AuthPasswordResetting extends AuthState {
  const AuthPasswordResetting();
}

class AuthAuthenticated extends AuthState {
  final User user;
  final bool isProfileComplete;
  
  const AuthAuthenticated({
    required this.user,
    required this.isProfileComplete,
  });

  // BLoC-compatible property name
  bool get needsProfileSetup => !isProfileComplete;
  
  @override
  List<Object> get props => [user, isProfileComplete];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthSignUpSuccess extends AuthState {
  final User user;
  
  const AuthSignUpSuccess({required this.user});
  
  @override
  List<Object> get props => [user];
}

class AuthProfileSetupRequired extends AuthState {
  final User partialUser;
  
  const AuthProfileSetupRequired({required this.partialUser});
  
  @override
  List<Object> get props => [partialUser];
}

class AuthPasswordResetSent extends AuthState {
  const AuthPasswordResetSent();
}

class AuthEmailVerified extends AuthState {
  const AuthEmailVerified();
}

class AuthAccountDeleted extends AuthState {
  const AuthAccountDeleted();
}

class AuthError extends AuthState implements BaseErrorState {
  @override
  final String message;
  @override
  final String? errorCode;
  @override
  final ErrorSeverity severity;
  @override
  final bool canRetry;
  @override
  final Map<String, dynamic>? context;
  
  const AuthError({
    required this.message,
    this.errorCode,
    this.severity = ErrorSeverity.error,
    this.canRetry = true,
    this.context,
  });

  /// Factory constructor for creating AuthError from AppException
  factory AuthError.fromException(AppException exception) {
    return AuthError(
      message: exception.userMessage,
      errorCode: exception.code,
      severity: exception.severity,
      canRetry: ErrorHandler.shouldRetry(exception),
      context: exception.context,
    );
  }
  
  @override
  List<Object?> get props => [message, errorCode, severity, canRetry, context];
}

class AuthSignInError extends AuthState implements BaseErrorState {
  @override
  final String message;
  @override
  final String? errorCode;
  @override
  final ErrorSeverity severity;
  @override
  final bool canRetry;
  @override
  final Map<String, dynamic>? context;
  final String email; // Keep email for retry
  
  const AuthSignInError({
    required this.message,
    required this.email,
    this.errorCode,
    this.severity = ErrorSeverity.error,
    this.canRetry = true,
    this.context,
  });

  /// Factory constructor for creating AuthSignInError from AppException
  factory AuthSignInError.fromException(AppException exception, String email) {
    return AuthSignInError(
      message: exception.userMessage,
      email: email,
      errorCode: exception.code,
      severity: exception.severity,
      canRetry: ErrorHandler.shouldRetry(exception),
      context: exception.context,
    );
  }
  
  @override
  List<Object?> get props => [message, email, errorCode, severity, canRetry, context];
}

class AuthSignUpError extends AuthState implements BaseErrorState {
  @override
  final String message;
  @override
  final String? errorCode;
  @override
  final ErrorSeverity severity;
  @override
  final bool canRetry;
  @override
  final Map<String, dynamic>? context;
  final String email; // Keep email for retry
  final String name;  // Keep name for retry
  
  const AuthSignUpError({
    required this.message,
    required this.email,
    required this.name,
    this.errorCode,
    this.severity = ErrorSeverity.error,
    this.canRetry = true,
    this.context,
  });

  /// Factory constructor for creating AuthSignUpError from AppException
  factory AuthSignUpError.fromException(
    AppException exception,
    String email,
    String name,
  ) {
    return AuthSignUpError(
      message: exception.userMessage,
      email: email,
      name: name,
      errorCode: exception.code,
      severity: exception.severity,
      canRetry: ErrorHandler.shouldRetry(exception),
      context: exception.context,
    );
  }
  
  @override
  List<Object?> get props => [message, email, name, errorCode, severity, canRetry, context];
}

class AuthValidationError extends AuthState implements BaseErrorState {
  @override
  final String message;
  @override
  final String? errorCode;
  @override
  final ErrorSeverity severity;
  @override
  final bool canRetry;
  @override
  final Map<String, dynamic>? context;
  final String field; // Which field has validation error
  
  const AuthValidationError({
    required this.message,
    required this.field,
    this.errorCode,
    this.severity = ErrorSeverity.warning,
    this.canRetry = false,
    this.context,
  });

  /// Factory constructor for creating AuthValidationError from ValidationException
  factory AuthValidationError.fromValidationException(ValidationException exception) {
    return AuthValidationError(
      message: exception.userMessage,
      field: exception.field,
      errorCode: exception.code,
      severity: exception.severity,
      canRetry: false,
      context: exception.context,
    );
  }
  
  @override
  List<Object?> get props => [message, field, errorCode, severity, canRetry, context];
}

class AuthNetworkError extends AuthState implements BaseErrorState {
  @override
  final String message;
  @override
  final String? errorCode;
  @override
  final ErrorSeverity severity;
  @override
  final bool canRetry;
  @override
  final Map<String, dynamic>? context;
  
  const AuthNetworkError({
    required this.message,
    this.errorCode,
    this.severity = ErrorSeverity.error,
    this.canRetry = true,
    this.context,
  });

  /// Factory constructor for creating AuthNetworkError from NetworkException
  factory AuthNetworkError.fromNetworkException(NetworkException exception) {
    return AuthNetworkError(
      message: exception.userMessage,
      errorCode: exception.code,
      severity: exception.severity,
      canRetry: ErrorHandler.shouldRetry(exception),
      context: exception.context,
    );
  }
  
  @override
  List<Object?> get props => [message, errorCode, severity, canRetry, context];
}

class AuthSessionExpired extends AuthState {
  const AuthSessionExpired();
}

class AuthSessionRefreshed extends AuthState {
  final User user;
  
  const AuthSessionRefreshed({required this.user});
  
  @override
  List<Object> get props => [user];
}

class AuthGoogleSignInLoading extends AuthState {
  const AuthGoogleSignInLoading();
}

class AuthGoogleSignInCancelled extends AuthState {
  const AuthGoogleSignInCancelled();
}