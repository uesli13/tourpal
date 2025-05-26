import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/logger.dart';
import '../core/exceptions/app_exceptions.dart';
import '../models/user.dart';

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository(this._firestore, {required FirebaseFirestore firestore});

  Future<User?> getUserById(String userId) async {
    try {
      AppLogger.info('Fetching user by ID: $userId');
      
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!doc.exists) {
        AppLogger.warning('User not found: $userId');
        return null;
      }

      final user = User.fromMap(doc.data()!, userId);
      AppLogger.info('User fetched successfully: $userId');
      return user;
    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error fetching user', e);
      throw DatabaseException('Failed to fetch user: ${e.message}', code: e.code);
    } catch (e) {
      AppLogger.error('Unexpected error fetching user', e);
      throw const DatabaseException('Failed to fetch user');
    }
  }

  Future<void> updateUser(User user) async {
    try {
      AppLogger.info('Updating user: ${user.id}');
      
      await _firestore
          .collection('users')
          .doc(user.id)
          .update(user.toMap());
      
      AppLogger.info('User updated successfully: ${user.id}');
    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error updating user', e);
      throw DatabaseException('Failed to update user: ${e.message}', code: e.code);
    } catch (e) {
      AppLogger.error('Unexpected error updating user', e);
      throw const DatabaseException('Failed to update user');
    }
  }

  Future<void> addTourToUserList(String userId, String tourId, String listName) async {
    try {
      AppLogger.info('Adding tour $tourId to $listName for user $userId');
      
      await _firestore
          .collection('users')
          .doc(userId)
          .update({
            listName: FieldValue.arrayUnion([tourId]),
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      AppLogger.info('Tour added to $listName successfully');
    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error adding tour to list', e);
      throw DatabaseException('Failed to add tour: ${e.message}', code: e.code);
    } catch (e) {
      AppLogger.error('Unexpected error adding tour to list', e);
      throw const DatabaseException('Failed to add tour to favorites');
    }
  }

  Future<void> removeTourFromUserList(String userId, String tourId, String listName) async {
    try {
      AppLogger.info('Removing tour $tourId from $listName for user $userId');
      
      await _firestore
          .collection('users')
          .doc(userId)
          .update({
            listName: FieldValue.arrayRemove([tourId]),
            'updatedAt': FieldValue.serverTimestamp(),
          });
      
      AppLogger.info('Tour removed from $listName successfully');
    } on FirebaseException catch (e) {
      AppLogger.error('Firebase error removing tour from list', e);
      throw DatabaseException('Failed to remove tour: ${e.message}', code: e.code);
    } catch (e) {
      AppLogger.error('Unexpected error removing tour from list', e);
      throw const DatabaseException('Failed to remove tour from favorites');
    }
  }
}