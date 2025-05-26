import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  
  @override
  List<Object?> get props => [];
}

// BLoC-compatible event names (as expected by AuthBloc)
class SignInRequested extends AuthEvent {
  final String email;
  final String password;
  
  const SignInRequested({
    required this.email,
    required this.password,
  });
  
  @override
  List<Object> get props => [email, password];
}

class GoogleSignInRequested extends AuthEvent {
  const GoogleSignInRequested();
}

class ClearAuthErrorEvent extends AuthEvent {
  const ClearAuthErrorEvent();
}

class SendPasswordResetEvent extends AuthEvent {
  final String email;
  
  const SendPasswordResetEvent({required this.email});
  
  @override
  List<Object> get props => [email];
}

// Existing events (keeping for backward compatibility)
class SignUpWithEmailEvent extends AuthEvent {
  final String email;
  final String password;
  final String name;
  
  const SignUpWithEmailEvent({
    required this.email,
    required this.password,
    required this.name,
  });
  
  @override
  List<Object> get props => [email, password, name];
}

class SignInWithEmailEvent extends AuthEvent {
  final String email;
  final String password;
  
  const SignInWithEmailEvent({
    required this.email,
    required this.password,
  });
  
  @override
  List<Object> get props => [email, password];
}

class SignInWithGoogleEvent extends AuthEvent {
  const SignInWithGoogleEvent();
}

/// Switch to a different Google account
class SwitchGoogleAccountEvent extends AuthEvent {
  const SwitchGoogleAccountEvent();
}

class ResetPasswordEvent extends AuthEvent {
  final String email;
  
  const ResetPasswordEvent({required this.email});
  
  @override
  List<Object> get props => [email];
}

class SignOutEvent extends AuthEvent {
  const SignOutEvent();
}

class CheckAuthStatusEvent extends AuthEvent {
  const CheckAuthStatusEvent();
}

class RefreshUserSessionEvent extends AuthEvent {
  const RefreshUserSessionEvent();
}

class CompleteProfileSetupEvent extends AuthEvent {
  final String bio;
  final DateTime birthdate;
  final bool isGuide;
  final String? profileImagePath;
  
  const CompleteProfileSetupEvent({
    required this.bio,
    required this.birthdate,
    required this.isGuide,
    this.profileImagePath,
  });
  
  @override
  List<Object?> get props => [bio, birthdate, isGuide, profileImagePath];
}

class SetupGuideProfileEvent extends AuthEvent {
  final List<String> languages;
  final double hourlyRate;
  final String guideBio;
  
  const SetupGuideProfileEvent({
    required this.languages,
    required this.hourlyRate,
    required this.guideBio,
  });
  
  @override
  List<Object> get props => [languages, hourlyRate, guideBio];
}

class DeleteAccountEvent extends AuthEvent {
  final String password; // Confirmation password
  
  const DeleteAccountEvent({required this.password});
  
  @override
  List<Object> get props => [password];
}

class SendEmailVerificationEvent extends AuthEvent {
  const SendEmailVerificationEvent();
}

class VerifyEmailEvent extends AuthEvent {
  const VerifyEmailEvent();
}