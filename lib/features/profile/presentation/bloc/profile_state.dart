import 'package:equatable/equatable.dart';
import '../../../../models/user.dart';

// States
abstract class ProfileState extends Equatable {
  const ProfileState();
  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final User user;
  const ProfileLoaded(this.user);
  @override
  List<Object> get props => [user];
}

class ProfileUpdated extends ProfileState {
  final User user;
  const ProfileUpdated({required this.user});
  @override
  List<Object> get props => [user];
}

class ProfileUpdateSuccess extends ProfileState {
  final User user;
  const ProfileUpdateSuccess({required this.user});
  @override
  List<Object> get props => [user];
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

class ProfileError extends ProfileState {
  final String message;
  final String error;

  const ProfileError(this.message, {this.error = ''});

  @override
  List<Object> get props => [message, error];
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

