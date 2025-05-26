import 'package:equatable/equatable.dart';
import 'dart:io';
import 'package:tourpal/models/user.dart';

// Events
abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object?> get props => [];
}

class LoadProfile extends ProfileEvent {
  final String userId;
  const LoadProfile(this.userId);
  @override
  List<Object> get props => [userId];
}

class UpdateProfile extends ProfileEvent {
  final User user;
  const UpdateProfile(this.user);
  @override
  List<Object> get props => [user];
}

class UpdateProfileEvent extends ProfileEvent {
  final String? name;
  final String? bio;
  final String? profileImagePath;
  final File? profileImage;
  final bool? removeProfileImage;
  final DateTime? birthdate;
  
  const UpdateProfileEvent({
    this.name,
    this.bio,
    this.profileImagePath,
    this.profileImage,
    this.removeProfileImage,
    this.birthdate,
  });
  
  @override
  List<Object?> get props => [name, bio, profileImagePath, profileImage, removeProfileImage, birthdate];
}

class UpdateEmailEvent extends ProfileEvent {
  final String newEmail;
  final String password;
  
  const UpdateEmailEvent({
    required this.newEmail,
    required this.password,
  });
  
  @override
  List<Object> get props => [newEmail, password];
}

class UpdatePasswordEvent extends ProfileEvent {
  final String currentPassword;
  final String newPassword;
  
  const UpdatePasswordEvent({
    required this.currentPassword,
    required this.newPassword,
  });
  
  @override
  List<Object> get props => [currentPassword, newPassword];
}

class ClearErrorEvent extends ProfileEvent {
  const ClearErrorEvent();
}

class UpdateProfileRoleEvent extends ProfileEvent {
  final bool isGuide;
  
  const UpdateProfileRoleEvent({required this.isGuide});
  
  @override
  List<Object> get props => [isGuide];
}

class AddTourToFavorites extends ProfileEvent {
  final String userId;
  final String tourId;
  const AddTourToFavorites(this.userId, this.tourId);
  @override
  List<Object> get props => [userId, tourId];
}

class RemoveTourFromFavorites extends ProfileEvent {
  final String userId;
  final String tourId;
  const RemoveTourFromFavorites(this.userId, this.tourId);
  @override
  List<Object> get props => [userId, tourId];
}

