import 'dart:io';

class ProfileUpdateRequest {
  final String? name;
  final String? bio;
  final File? profileImage;
  final bool removeProfileImage;

  const ProfileUpdateRequest({
    this.name,
    this.bio,
    this.profileImage,
    this.removeProfileImage = false,
  });
}