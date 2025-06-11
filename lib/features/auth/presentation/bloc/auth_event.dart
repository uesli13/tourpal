import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  
  @override
  List<Object?> get props => [];
}

class CheckAuthStatusEvent extends AuthEvent {
  const CheckAuthStatusEvent();
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

class SignInWithGoogleEvent extends AuthEvent {
  const SignInWithGoogleEvent();
}

class SwitchGoogleAccountEvent extends AuthEvent {
  const SwitchGoogleAccountEvent();
}

class SignOutEvent extends AuthEvent {
  const SignOutEvent();
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

class VerifyEmailEvent extends AuthEvent {
  const VerifyEmailEvent();
}

class UpdateUserRoleEvent extends AuthEvent {
  final bool isGuide;
  
  const UpdateUserRoleEvent({required this.isGuide});
  
  @override
  List<Object> get props => [isGuide];
}