import 'package:equatable/equatable.dart';
import '../../../../models/user.dart';

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

class AuthSignedOut extends AuthState {
  const AuthSignedOut();
}

class AuthProfileSetupRequired extends AuthState {
  final User partialUser; // User with basic info, needs profile completion
  
  const AuthProfileSetupRequired({required this.partialUser});
  
  @override
  List<Object> get props => [partialUser];
}

class AuthGuideSetupRequired extends AuthState {
  final User user; // User chose to be a guide, needs guide profile setup
  
  const AuthGuideSetupRequired({required this.user});
  
  @override
  List<Object> get props => [user];
}

class AuthProfileSetupLoading extends AuthState {
  const AuthProfileSetupLoading();
}

class AuthGuideSetupLoading extends AuthState {
  const AuthGuideSetupLoading();
}

class AuthPasswordResetSent extends AuthState {
  const AuthPasswordResetSent();
}

class AuthEmailVerificationSent extends AuthState {
  const AuthEmailVerificationSent();
}

class AuthEmailVerified extends AuthState {
  const AuthEmailVerified();
}

class AuthAccountDeleted extends AuthState {
  const AuthAccountDeleted();
}

class AuthError extends AuthState {
  final String message;
  final String? errorCode;
  
  const AuthError({
    required this.message,
    this.errorCode,
  });
  
  @override
  List<Object?> get props => [message, errorCode];
}

class AuthSignInError extends AuthState {
  final String message;
  final String email; // Keep email for retry
  
  const AuthSignInError({
    required this.message,
    required this.email,
  });
  
  @override
  List<Object> get props => [message, email];
}

class AuthSignUpError extends AuthState {
  final String message;
  final String email; // Keep email for retry
  final String name;  // Keep name for retry
  
  const AuthSignUpError({
    required this.message,
    required this.email,
    required this.name,
  });
  
  @override
  List<Object> get props => [message, email, name];
}

class AuthValidationError extends AuthState {
  final String message;
  final String field; // Which field has validation error
  
  const AuthValidationError({
    required this.message,
    required this.field,
  });
  
  @override
  List<Object> get props => [message, field];
}

class AuthNetworkError extends AuthState {
  final String message;
  
  const AuthNetworkError({required this.message});
  
  @override
  List<Object> get props => [message];
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