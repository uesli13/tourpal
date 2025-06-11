import 'package:equatable/equatable.dart';
import '../../../../core/utils/bloc_error_handler.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../models/user.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();
  
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  final User user;
  
  const ProfileLoaded(this.user);
  
  @override
  List<Object> get props => [user];
}

class ProfileError extends ProfileState implements BaseErrorState {
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
  
  const ProfileError(
    this.message, {
    this.errorCode,
    this.severity = ErrorSeverity.error,
    this.canRetry = true,
    this.context,
  });

  /// Factory constructor for creating ProfileError from AppException
  factory ProfileError.fromException(AppException exception) {
    return ProfileError(
      exception.userMessage,
      errorCode: exception.code,
      severity: exception.severity,
      canRetry: ErrorHandler.shouldRetry(exception),
      context: exception.context,
    );
  }
  
  @override
  List<Object?> get props => [message, errorCode, severity, canRetry, context];
}

class ProfileUpdateSuccess extends ProfileState {
  final User user;
  final String message;
  
  const ProfileUpdateSuccess({
    required this.user,
    required this.message,
  });
  
  @override
  List<Object> get props => [user, message];
}

class ProfileEmailUpdateSuccess extends ProfileState {
  final String newEmail;
  
  const ProfileEmailUpdateSuccess({required this.newEmail});
  
  @override
  List<Object> get props => [newEmail];
}

class ProfilePasswordUpdateSuccess extends ProfileState {
  const ProfilePasswordUpdateSuccess();
}

class TourAddedToFavorites extends ProfileState {
  final String tourId;
  final User updatedUser;
  
  const TourAddedToFavorites({
    required this.tourId,
    required this.updatedUser,
  });
  
  @override
  List<Object> get props => [tourId, updatedUser];
}

class TourRemovedFromFavorites extends ProfileState {
  final String tourId;
  final User updatedUser;
  
  const TourRemovedFromFavorites({
    required this.tourId,
    required this.updatedUser,
  });
  
  @override
  List<Object> get props => [tourId, updatedUser];
}

class ProfileUpdating extends ProfileState {
  const ProfileUpdating();
}

class ProfileUpdated extends ProfileState {
  final User user;
  
  const ProfileUpdated({required this.user});
  
  @override
  List<Object> get props => [user];
}

class ProfileImageUploading extends ProfileState {
  const ProfileImageUploading();
}

class ProfileImageUploaded extends ProfileState {
  final String imageUrl;
  
  const ProfileImageUploaded({required this.imageUrl});
  
  @override
  List<Object> get props => [imageUrl];
}