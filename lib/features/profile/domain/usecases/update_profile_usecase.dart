import '../repositories/profile_repository.dart';
import '../../../../models/user.dart';
import 'dart:io';

/// Enhanced profile update usecase supporting Google profile import
/// 
/// Handles comprehensive profile updates including:
/// - Basic profile information (name, bio)
/// - Profile photo management (upload, URL preservation, removal)
/// - Birthdate updates with proper Timestamp conversion
/// - Guide status management
/// 
/// Follows database documentation data formats for User collection
class UpdateProfileUsecase {
  final ProfileRepository repository;

  UpdateProfileUsecase(this.repository);

  /// Update user profile with enhanced Google import support
  /// 
  /// Parameters follow database schema documented in DATABASE.md:
  /// - [name]: User's display name (required in User interface)
  /// - [bio]: User biography (optional)
  /// - [birthdate]: User's birthdate as DateTime (converted to Timestamp)
  /// - [profileImage]: New profile image file to upload
  /// - [profileImagePath]: Existing profile image URL to preserve (for Google imports)
  /// - [removeProfileImage]: Flag to remove current profile image
  /// - [isGuide]: Guide status flag
  Future<User> call({
    String? name,
    String? bio,
    DateTime? birthdate,
    File? profileImage,
    String? profileImagePath,
    bool removeProfileImage = false,
    bool? isGuide,
  }) async {
    return await repository.updateProfile(
      name: name,
      bio: bio,
      birthdate: birthdate,
      profileImage: profileImage,
      profileImagePath: profileImagePath,
      removeProfileImage: removeProfileImage,
      isGuide: isGuide,
    );
  }
}