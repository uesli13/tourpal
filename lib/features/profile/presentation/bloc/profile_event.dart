import 'package:equatable/equatable.dart';
import 'dart:io';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
  @override
  List<Object?> get props => [];
}

class LoadProfileEvent extends ProfileEvent {
  final String userId;
  
  const LoadProfileEvent(this.userId);
  
  @override
  List<Object> get props => [userId];
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

class UpdateProfileRoleEvent extends ProfileEvent {
  final bool isGuide;
  
  const UpdateProfileRoleEvent({required this.isGuide});
  
  @override
  List<Object> get props => [isGuide];
}

class UploadProfileImageEvent extends ProfileEvent {
  final String userId;
  final String imagePath;
  
  const UploadProfileImageEvent({
    required this.userId,
    required this.imagePath,
  });
  
  @override
  List<Object> get props => [userId, imagePath];
}

class DeleteProfileImageEvent extends ProfileEvent {
  final String userId;
  
  const DeleteProfileImageEvent(this.userId);
  
  @override
  List<Object> get props => [userId];
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

class ClearProfileErrorEvent extends ProfileEvent {
  const ClearProfileErrorEvent();
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