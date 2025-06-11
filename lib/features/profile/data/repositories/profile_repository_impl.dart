import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../models/user.dart' as AppUser;
import '../../../../core/utils/logger.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;

  ProfileRepositoryImpl({
    required ProfileRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<AppUser.User> getProfile(String userId) async {
    try {
      AppLogger.info('ProfileRepositoryImpl: Getting profile for user $userId');
      
      final user = await _remoteDataSource.getProfile(userId);
      
      AppLogger.info('ProfileRepositoryImpl: Profile retrieved successfully');
      return user;
    } catch (e) {
      AppLogger.error('ProfileRepositoryImpl: Error getting profile', e);
      rethrow;
    }
  }

  @override
  Future<AppUser.User> updateProfile({
    String? name,
    String? bio,
    DateTime? birthdate,
    File? profileImage,
    String? profileImagePath,
    bool removeProfileImage = false,
    bool? isGuide,
  }) async {
    try {
      AppLogger.info('ProfileRepositoryImpl: Updating profile with enhanced Google import support');
      
      // Get current user ID from Firebase Auth
      final currentFirebaseUser = FirebaseAuth.instance.currentUser;
      if (currentFirebaseUser == null) {
        throw Exception('No authenticated user found');
      }
      
      // Get current user data first
      final currentUser = await _remoteDataSource.getProfile(currentFirebaseUser.uid);
      
      // Handle profile image operations
      String? finalProfileImageUrl = currentUser.profileImageUrl;
      
      if (removeProfileImage) {
        // Remove existing profile image
        if (currentUser.profileImageUrl != null) {
          try {
            await _remoteDataSource.deleteProfileImage(currentUser.id);
            AppLogger.info('ProfileRepositoryImpl: Existing profile image removed');
          } catch (e) {
            AppLogger.warning('ProfileRepositoryImpl: Error removing existing image (continuing)', e);
          }
        }
        finalProfileImageUrl = null;
      } else if (profileImage != null) {
        // Upload new profile image
        AppLogger.info('ProfileRepositoryImpl: Uploading new profile image');
        finalProfileImageUrl = await _remoteDataSource.uploadProfileImage(currentUser.id, profileImage);
        AppLogger.info('ProfileRepositoryImpl: New profile image uploaded successfully');
      } else if (profileImagePath != null) {
        // Preserve imported Google profile image URL
        finalProfileImageUrl = profileImagePath;
        AppLogger.info('ProfileRepositoryImpl: Preserving imported Google profile image');
      }
      
      // Create updated user with new data following DATABASE.md schema
      final updatedUser = currentUser.copyWith(
        name: name,
        bio: bio,
        birthdate: birthdate != null ? Timestamp.fromDate(birthdate) : currentUser.birthdate,
        profileImageUrl: finalProfileImageUrl,
        isGuide: isGuide,
      );
      
      // Update through data source
      await _remoteDataSource.updateProfile(updatedUser);
      
      AppLogger.info('ProfileRepositoryImpl: Profile updated successfully with Google import support');
      return updatedUser;
    } catch (e) {
      AppLogger.error('ProfileRepositoryImpl: Error updating profile with enhanced features', e);
      rethrow;
    }
  }

  @override
  Future<String> uploadProfileImage(String userId, File imageFile) async {
    try {
      AppLogger.info('ProfileRepositoryImpl: Uploading profile image for user $userId');
      
      final imageUrl = await _remoteDataSource.uploadProfileImage(userId, imageFile);
      
      // Update user profile with new image URL
      final currentUser = await _remoteDataSource.getProfile(userId);
      final updatedUser = currentUser.copyWith(profileImageUrl: imageUrl);
      await _remoteDataSource.updateProfile(updatedUser);
      
      AppLogger.info('ProfileRepositoryImpl: Profile image uploaded and profile updated');
      return imageUrl;
    } catch (e) {
      AppLogger.error('ProfileRepositoryImpl: Error uploading profile image', e);
      rethrow;
    }
  }

  @override
  Future<void> deleteProfileImage(String userId) async {
    try {
      AppLogger.info('ProfileRepositoryImpl: Deleting profile image for user $userId');
      
      // Delete from storage
      await _remoteDataSource.deleteProfileImage(userId);
      
      // Update user profile to remove image URL
      final currentUser = await _remoteDataSource.getProfile(userId);
      final updatedUser = currentUser.copyWith(profileImageUrl: null);
      await _remoteDataSource.updateProfile(updatedUser);
      
      AppLogger.info('ProfileRepositoryImpl: Profile image deleted and profile updated');
    } catch (e) {
      AppLogger.error('ProfileRepositoryImpl: Error deleting profile image', e);
      rethrow;
    }
  }

  @override
  Stream<AppUser.User?> watchProfile(String userId) {
    try {
      AppLogger.info('ProfileRepositoryImpl: Watching profile for user $userId');
      
      return _remoteDataSource.watchProfile(userId);
    } catch (e) {
      AppLogger.error('ProfileRepositoryImpl: Error watching profile', e);
      rethrow;
    }
  }
}