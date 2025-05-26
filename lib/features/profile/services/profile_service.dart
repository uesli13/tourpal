import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../../core/utils/logger.dart';
import '../../../core/exceptions/app_exceptions.dart';
import '../../../models/user.dart';
import '../../../models/guide.dart';

class ProfileService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final firebase_auth.FirebaseAuth _firebaseAuth;

  ProfileService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    firebase_auth.FirebaseAuth? firebaseAuth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance;

  Future<bool> isProfileComplete(String userId) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.profile('Checking if profile is complete', userId);

    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        AppLogger.warning('User document not found during profile check', userId);
        return false;
      }

      final userData = userDoc.data()!;
      
      // Check required fields for complete profile
      final isComplete = userData['bio'] != null && 
                        userData['bio'].toString().trim().isNotEmpty &&
                        userData['birthdate'] != null;

      stopwatch.stop();
      AppLogger.performance('Profile Complete Check', stopwatch.elapsed);
      AppLogger.profile('Profile complete status: $isComplete', userId);

      return isComplete;

    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error checking profile completion', e);
      throw DatabaseException('Failed to check profile: ${e.message}', code: e.code);
    } catch (e) {
      AppLogger.error('Unexpected error checking profile completion', e);
      throw const ProfileException('Failed to verify profile status');
    }
  }

  Future<User> completeProfile({
    required String bio,
    required DateTime birthdate,
    required bool isGuide,
    String? profileImagePath,
  }) async {
    final stopwatch = Stopwatch()..start();
    final currentUser = _firebaseAuth.currentUser;
    
    if (currentUser == null) {
      throw const AuthenticationException('No user signed in');
    }

    AppLogger.profile('Starting profile completion', currentUser.uid);

    try {
      // Validate inputs
      _validateProfileData(bio, birthdate);

      // Upload profile image if provided
      String? profileImageUrl;
      if (profileImagePath != null) {
        profileImageUrl = await _uploadProfileImage(
          currentUser.uid, 
          profileImagePath,
        );
      }

      // Update user document
      final updateData = {
        'bio': bio.trim(),
        'birthdate': Timestamp.fromDate(birthdate),
        'profileImageUrl': profileImageUrl ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .update(updateData);

      AppLogger.firebase('User profile updated', currentUser.uid);

      // Get updated user document
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final user = User.fromMap(userDoc.data()!, currentUser.uid);

      stopwatch.stop();
      AppLogger.performance('Complete Profile', stopwatch.elapsed);
      AppLogger.profile('Profile completion successful', user.id);

      return user;

    } on ValidationException catch (e) {
      AppLogger.warning('Validation error during profile completion: ${e.message}');
      rethrow;
    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error during profile completion', e);
      throw ProfileServiceException('Failed to update profile: ${e.message}');
    } catch (e) {
      AppLogger.error('Unexpected error during profile completion', e);
      throw const ProfileServiceException('Failed to complete profile setup');
    }
  }

  Future<User> setupGuideProfile({
    required List<String> languages,
    required double hourlyRate,
    required String guideBio,
  }) async {
    final stopwatch = Stopwatch()..start();
    final currentUser = _firebaseAuth.currentUser;
    
    if (currentUser == null) {
      throw const AuthenticationException('No user signed in');
    }

    AppLogger.guide('Starting guide profile setup', currentUser.uid);

    try {
      // Validate guide inputs
      _validateGuideData(languages, hourlyRate, guideBio);

      // Create guide document
      final guideData = {
        'userId': currentUser.uid,
        'bio': guideBio.trim(),
        'languages': languages,
        'hourlyRate': hourlyRate,
        'isAvailable': true,
        'availability': <Map<String, dynamic>>[], // Empty initially
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('guides')
          .doc(currentUser.uid)
          .set(guideData);

      AppLogger.firebase('Guide profile created', currentUser.uid);

      // Update user document to mark as guide
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .update({
            'isGuide': true,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      AppLogger.firebase('User marked as guide', currentUser.uid);

      // Get updated user document
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final user = User.fromMap(userDoc.data()!, currentUser.uid);

      stopwatch.stop();
      AppLogger.performance('Guide Profile Setup', stopwatch.elapsed);
      AppLogger.guide('Guide profile setup completed', user.id);

      return user;

    } on ValidationException catch (e) {
      AppLogger.warning('Validation error during guide setup: ${e.message}');
      rethrow;
    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error during guide setup', e);
      throw GuideServiceException('Failed to setup guide profile: ${e.message}');
    } catch (e) {
      AppLogger.error('Unexpected error during guide setup', e);
      throw const GuideServiceException('Failed to setup guide profile');
    }
  }

  Future<User> updateProfile({
    String? name,
    String? bio,
    String? profileImagePath,
    DateTime? birthdate,
    bool? isGuide,
  }) async {
    final stopwatch = Stopwatch()..start();
    final currentUser = _firebaseAuth.currentUser;
    
    if (currentUser == null) {
      throw const AuthenticationException('No user signed in');
    }

    AppLogger.profile('Starting profile update', currentUser.uid);

    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Validate and add fields to update
      if (name != null) {
        _validateName(name);
        updateData['name'] = name.trim();
        
        // Update Firebase Auth display name
        await currentUser.updateDisplayName(name.trim());
        AppLogger.auth('Display name updated', currentUser.uid);
      }

      if (bio != null) {
        _validateBio(bio);
        updateData['bio'] = bio.trim();
      }

      if (birthdate != null) {
        _validateBirthdate(birthdate);
        updateData['birthdate'] = Timestamp.fromDate(birthdate);
      }

      // Handle guide role toggle
      if (isGuide != null) {
        updateData['isGuide'] = isGuide;
        AppLogger.profile('Updating guide role to: $isGuide', currentUser.uid);
      }

      // Handle profile image updates
      if (profileImagePath != null) {
        if (profileImagePath.isEmpty) {
          // Remove profile image
          updateData['profileImageUrl'] = null;
          await currentUser.updatePhotoURL(null);
          AppLogger.auth('Photo URL removed', currentUser.uid);
        } else {
          // Upload new profile image
          final profileImageUrl = await _uploadProfileImage(
            currentUser.uid, 
            profileImagePath,
          );
          updateData['profileImageUrl'] = profileImageUrl;
          
          // Update Firebase Auth photo URL
          await currentUser.updatePhotoURL(profileImageUrl);
          AppLogger.auth('Photo URL updated', currentUser.uid);
        }
      }

      // Update user document
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .update(updateData);

      AppLogger.firebase('User profile updated', currentUser.uid);

      // Get updated user document
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final user = User.fromMap(userDoc.data()!, currentUser.uid);

      stopwatch.stop();
      AppLogger.performance('Update Profile', stopwatch.elapsed);
      AppLogger.profile('Profile update successful', user.id);

      return user;

    } on ValidationException catch (e) {
      AppLogger.warning('Validation error during profile update: ${e.message}');
      rethrow;
    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error during profile update', e);
      throw ProfileServiceException('Failed to update profile: ${e.message}');
    } catch (e) {
      AppLogger.error('Unexpected error during profile update', e);
      throw const ProfileServiceException('Failed to update profile');
    }
  }

  /// Update user profile - BLoC-compatible method name
  Future<User> updateUserProfile({
    String? name,
    String? bio,
    String? profileImagePath,
  }) async {
    // Delegate to existing updateProfile method
    return updateProfile(
      name: name,
      bio: bio,
      profileImagePath: profileImagePath,
    );
  }

  /// Update user email
  Future<void> updateEmail({
    required String newEmail,
    required String password,
  }) async {
    final stopwatch = Stopwatch()..start();
    final currentUser = _firebaseAuth.currentUser;
    
    if (currentUser == null) {
      throw const AuthenticationException('No user signed in');
    }

    AppLogger.profile('Starting email update', currentUser.uid);

    try {
      // Re-authenticate user with current password
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: currentUser.email!,
        password: password,
      );
      
      await currentUser.reauthenticateWithCredential(credential);
      AppLogger.auth('User re-authenticated for email update', currentUser.uid);

      // Update email in Firebase Auth
      await currentUser.updateEmail(newEmail);
      AppLogger.auth('Email updated in Firebase Auth', currentUser.uid);

      // Update email in Firestore
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .update({
            'email': newEmail,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      AppLogger.firebase('Email updated in Firestore', currentUser.uid);

      // Send verification email to new address
      await currentUser.sendEmailVerification();
      AppLogger.auth('Verification email sent', currentUser.uid);

      stopwatch.stop();
      AppLogger.performance('Update Email', stopwatch.elapsed);
      AppLogger.profile('Email update successful', currentUser.uid);

    } on firebase_auth.FirebaseAuthException catch (e) {
      AppLogger.error('Firebase Auth error updating email', e);
      switch (e.code) {
        case 'wrong-password':
          throw const AuthenticationException('Current password is incorrect');
        case 'email-already-in-use':
          throw const ValidationException('Email is already in use');
        case 'invalid-email':
          throw const ValidationException('Invalid email format');
        case 'requires-recent-login':
          throw const AuthenticationException('Please log in again to update email');
        default:
          throw AuthenticationException('Failed to update email: ${e.message}');
      }
    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error updating email', e);
      throw ProfileServiceException('Failed to update email: ${e.message}');
    } catch (e) {
      AppLogger.error('Unexpected error updating email', e);
      throw const ProfileServiceException('Failed to update email');
    }
  }

  /// Update user password
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final stopwatch = Stopwatch()..start();
    final currentUser = _firebaseAuth.currentUser;
    
    if (currentUser == null) {
      throw const AuthenticationException('No user signed in');
    }

    AppLogger.profile('Starting password update', currentUser.uid);

    try {
      // Validate new password
      _validatePassword(newPassword);

      // Re-authenticate user with current password
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: currentUser.email!,
        password: currentPassword,
      );
      
      await currentUser.reauthenticateWithCredential(credential);
      AppLogger.auth('User re-authenticated for password update', currentUser.uid);

      // Update password in Firebase Auth
      await currentUser.updatePassword(newPassword);
      AppLogger.auth('Password updated in Firebase Auth', currentUser.uid);

      // Update timestamp in Firestore
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .update({
            'passwordUpdatedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      AppLogger.firebase('Password update timestamp recorded', currentUser.uid);

      stopwatch.stop();
      AppLogger.performance('Update Password', stopwatch.elapsed);
      AppLogger.profile('Password update successful', currentUser.uid);

    } on firebase_auth.FirebaseAuthException catch (e) {
      AppLogger.error('Firebase Auth error updating password', e);
      switch (e.code) {
        case 'wrong-password':
          throw const AuthenticationException('Current password is incorrect');
        case 'weak-password':
          throw const ValidationException('New password is too weak');
        case 'requires-recent-login':
          throw const AuthenticationException('Please log in again to update password');
        default:
          throw AuthenticationException('Failed to update password: ${e.message}');
      }
    } on ValidationException catch (e) {
      AppLogger.warning('Validation error during password update: ${e.message}');
      rethrow;
    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error updating password', e);
      throw ProfileServiceException('Failed to update password: ${e.message}');
    } catch (e) {
      AppLogger.error('Unexpected error updating password', e);
      throw const ProfileServiceException('Failed to update password');
    }
  }

  Future<User> getUserProfile(String userId) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.profile('Getting user profile', userId);

    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) {
        throw const ProfileException('User profile not found');
      }

      final user = User.fromMap(userDoc.data()!, userId);

      stopwatch.stop();
      AppLogger.performance('Get User Profile', stopwatch.elapsed);
      AppLogger.profile('User profile retrieved', user.id);

      return user;

    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error getting user profile', e);
      throw DatabaseException('Failed to get user profile: ${e.message}', code: e.code);
    } catch (e) {
      AppLogger.error('Unexpected error getting user profile', e);
      throw const ProfileException('Failed to retrieve user profile');
    }
  }

  Future<Guide?> getGuideProfile(String userId) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.guide('Getting guide profile', userId);

    try {
      final guideDoc = await _firestore
          .collection('guides')
          .doc(userId)
          .get();

      if (!guideDoc.exists) {
        AppLogger.guide('Guide profile not found', userId);
        return null;
      }

      final guide = Guide.fromMap(guideDoc.data()!, userId);

      stopwatch.stop();
      AppLogger.performance('Get Guide Profile', stopwatch.elapsed);
      AppLogger.guide('Guide profile retrieved', userId);

      return guide;

    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error getting guide profile', e);
      throw DatabaseException('Failed to get guide profile: ${e.message}', code: e.code);
    } catch (e) {
      AppLogger.error('Unexpected error getting guide profile', e);
      throw const GuideException('Failed to retrieve guide profile');
    }
  }

  Future<String> _uploadProfileImage(String userId, String imagePath) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.profile('Uploading profile image', userId);

    try {
      final file = File(imagePath);
      if (!file.existsSync()) {
        throw const StorageException('Image file not found');
      }

      // Create storage reference
      final ref = _storage
          .ref()
          .child('profile_images')
          .child('$userId.jpg');

      // Upload file
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      stopwatch.stop();
      AppLogger.performance('Upload Profile Image', stopwatch.elapsed);
      AppLogger.profile('Profile image uploaded successfully', userId);

      return downloadUrl;

    } on FirebaseException catch (e) {
      AppLogger.error('Firebase Storage error uploading image', e);
      throw StorageException('Failed to upload image: ${e.message}');
    } catch (e) {
      AppLogger.error('Unexpected error uploading profile image', e);
      throw const StorageException('Failed to upload profile image');
    }
  }

  /// Add tour to user's favorites
  Future<void> addTourToFavorites(String userId, String tourId) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Adding tour $tourId to favorites for user $userId');

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update({
            'favoriteTours': FieldValue.arrayUnion([tourId]),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      stopwatch.stop();
      AppLogger.performance('Add Tour to Favorites', stopwatch.elapsed);
      AppLogger.serviceOperation('ProfileService', 'addTourToFavorites', true);

    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error adding tour to favorites', e);
      AppLogger.serviceOperation('ProfileService', 'addTourToFavorites', false);
      throw ProfileServiceException('Failed to add tour to favorites: ${e.message}');
    } catch (e) {
      AppLogger.error('Unexpected error adding tour to favorites', e);
      AppLogger.serviceOperation('ProfileService', 'addTourToFavorites', false);
      throw const ProfileServiceException('Failed to add tour to favorites');
    }
  }

  /// Remove tour from user's favorites
  Future<void> removeTourFromFavorites(String userId, String tourId) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.info('Removing tour $tourId from favorites for user $userId');

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update({
            'favoriteTours': FieldValue.arrayRemove([tourId]),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      stopwatch.stop();
      AppLogger.performance('Remove Tour from Favorites', stopwatch.elapsed);
      AppLogger.serviceOperation('ProfileService', 'removeTourFromFavorites', true);

    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error removing tour from favorites', e);
      AppLogger.serviceOperation('ProfileService', 'removeTourFromFavorites', false);
      throw ProfileServiceException('Failed to remove tour from favorites: ${e.message}');
    } catch (e) {
      AppLogger.error('Unexpected error removing tour from favorites', e);
      AppLogger.serviceOperation('ProfileService', 'removeTourFromFavorites', false);
      throw const ProfileServiceException('Failed to remove tour from favorites');
    }
  }

  void _validateProfileData(String bio, DateTime birthdate) {
    _validateBio(bio);
    _validateBirthdate(birthdate);
  }

  void _validateGuideData(List<String> languages, double hourlyRate, String guideBio) {
    if (languages.isEmpty) {
      throw const GuideValidationException('At least one language is required');
    }
    
    if (languages.length > 10) {
      throw const GuideValidationException('Maximum 10 languages allowed');
    }

    if (hourlyRate <= 0) {
      throw const GuideValidationException('Hourly rate must be greater than 0');
    }

    if (hourlyRate > 1000) {
      throw const GuideValidationException('Hourly rate cannot exceed €1000');
    }

    _validateGuideBio(guideBio);
  }

  void _validateName(String name) {
    if (name.trim().isEmpty) {
      throw const ProfileValidationException('Name cannot be empty');
    }
    if (name.trim().length < 2) {
      throw const ProfileValidationException('Name must be at least 2 characters');
    }
    if (name.trim().length > 50) {
      throw const ProfileValidationException('Name cannot exceed 50 characters');
    }
  }

  void _validateBio(String bio) {
    if (bio.trim().isEmpty) {
      throw const ProfileValidationException('Bio cannot be empty');
    }
    if (bio.trim().length < 10) {
      throw const ProfileValidationException('Bio must be at least 10 characters');
    }
    if (bio.trim().length > 150) {
      throw const ProfileValidationException('Bio cannot exceed 150 characters');
    }
  }

  void _validateGuideBio(String guideBio) {
    if (guideBio.trim().isEmpty) {
      throw const GuideValidationException('Guide bio cannot be empty');
    }
    if (guideBio.trim().length < 20) {
      throw const GuideValidationException('Guide bio must be at least 20 characters');
    }
    if (guideBio.trim().length > 300) {
      throw const GuideValidationException('Guide bio cannot exceed 300 characters');
    }
  }

  void _validateBirthdate(DateTime birthdate) {
    final now = DateTime.now();
    final age = now.difference(birthdate).inDays / 365.25;
    
    if (age < 18) {
      throw const ProfileValidationException('Must be at least 18 years old');
    }
    if (age > 120) {
      throw const ProfileValidationException('Invalid birthdate');
    }
  }

  void _validatePassword(String password) {
    if (password.length < 6) {
      throw const ValidationException('Password must be at least 6 characters');
    }
    if (password.length > 100) {
      throw const ValidationException('Password cannot exceed 100 characters');
    }
  }
}