import 'dart:io';
import '../../../../models/user.dart';

/// Enhanced profile repository interface supporting Google profile import
/// 
/// Handles comprehensive profile operations including:
/// - Profile data retrieval and updates
/// - Profile photo management with Google import support
/// - Real-time profile watching
/// 
/// Follows database documentation data formats for User collection
abstract class ProfileRepository {
  Future<User> getProfile(String userId);
  
  /// Enhanced profile update supporting Google profile import
  /// 
  /// Parameters align with User interface from DATABASE.md:
  /// - Profile image handling supports upload, URL preservation, and removal
  /// - Birthdate uses DateTime for proper Timestamp conversion
  /// - All parameters are optional to support partial updates
  Future<User> updateProfile({
    String? name,
    String? bio,
    DateTime? birthdate,
    File? profileImage,
    String? profileImagePath,
    bool removeProfileImage = false,
    bool? isGuide,
  });
  
  Future<String> uploadProfileImage(
    String userId,
    File imageFile,
  );
  
  Future<void> deleteProfileImage(String userId);
  
  Stream<User?> watchProfile(String userId);
}