import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../models/user.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import 'profile_remote_data_source.dart';

class FirebaseProfileDataSource implements ProfileRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  FirebaseProfileDataSource({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  }) : _firestore = firestore,
       _storage = storage;

  @override
  Future<User> getProfile(String userId) async {
    try {
      AppLogger.info('FirebaseProfileDataSource: Getting profile for user $userId');
      
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (!doc.exists) {
        throw DatabaseException('User profile not found');
      }
      
      final user = User.fromMap(doc.data()!, doc.id);
      AppLogger.info('FirebaseProfileDataSource: Profile retrieved successfully');
      
      return user;
    } catch (e) {
      AppLogger.error('FirebaseProfileDataSource: Error getting profile', e);
      if (e is DatabaseException) rethrow;
      throw DatabaseException('Failed to get user profile');
    }
  }

  @override
  Future<void> updateProfile(User user) async {
    try {
      AppLogger.info('FirebaseProfileDataSource: Updating profile for user ${user.id}');
      
      await _firestore.collection('users').doc(user.id).update(user.toMap());
      
      AppLogger.info('FirebaseProfileDataSource: Profile updated successfully');
    } catch (e) {
      AppLogger.error('FirebaseProfileDataSource: Error updating profile', e);
      throw DatabaseException('Failed to update user profile');
    }
  }

  @override
  Future<String> uploadProfileImage(String userId, File imageFile) async {
    try {
      AppLogger.info('FirebaseProfileDataSource: Uploading profile image for user $userId');
      
      // Get the file extension to preserve original format
      final extension = imageFile.path.split('.').last.toLowerCase();
      final validExtensions = ['jpg', 'jpeg', 'png', 'webp'];
      final fileExtension = validExtensions.contains(extension) ? extension : 'jpg';
      
      // Use the storage path that matches our storage rules: profile_images/{userId}
      final ref = _storage.ref().child('profile_images/$userId.$fileExtension');
      
      // Add metadata for better file management
      final metadata = SettableMetadata(
        contentType: 'image/$fileExtension',
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'userId': userId,
        },
      );
      
      final uploadTask = await ref.putFile(imageFile, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      
      AppLogger.storage('Profile image upload', 'profile_images/$userId.$fileExtension', imageFile.lengthSync());
      AppLogger.info('FirebaseProfileDataSource: Profile image uploaded successfully');
      
      return downloadUrl;
    } catch (e) {
      AppLogger.error('FirebaseProfileDataSource: Error uploading profile image', e);
      throw StorageException('Failed to upload profile image');
    }
  }

  @override
  Future<void> deleteProfileImage(String userId) async {
    try {
      AppLogger.info('FirebaseProfileDataSource: Deleting profile image for user $userId');
      
      // Try to delete common image formats since we don't know the exact extension
      final extensions = ['jpg', 'jpeg', 'png', 'webp'];
      bool deleted = false;
      
      for (final ext in extensions) {
        try {
          final ref = _storage.ref().child('profile_images/$userId.$ext');
          await ref.delete();
          AppLogger.storage('Profile image delete', 'profile_images/$userId.$ext');
          deleted = true;
          break; // Stop after first successful deletion
        } catch (e) {
          // Continue trying other extensions
          continue;
        }
      }
      
      if (deleted) {
        AppLogger.info('FirebaseProfileDataSource: Profile image deleted successfully');
      } else {
        AppLogger.warning('FirebaseProfileDataSource: No profile image found to delete for user $userId');
      }
    } catch (e) {
      AppLogger.warning('FirebaseProfileDataSource: Failed to delete profile image', e);
      // Don't throw here as this is often a non-critical operation
    }
  }

  @override
  Stream<User?> watchProfile(String userId) {
    try {
      AppLogger.info('FirebaseProfileDataSource: Watching profile for user $userId');
      
      return _firestore
          .collection('users')
          .doc(userId)
          .snapshots()
          .map((doc) {
            if (!doc.exists) return null;
            return User.fromMap(doc.data()!, doc.id);
          });
    } catch (e) {
      AppLogger.error('FirebaseProfileDataSource: Error watching profile', e);
      throw DatabaseException('Failed to watch user profile');
    }
  }
}