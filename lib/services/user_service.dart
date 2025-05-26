import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/user.dart';
import '../core/errors/error_handler.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  static const String _usersCollection = 'users';

  /// Get user by ID
  Future<User?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(userId).get();
      
      if (doc.exists && doc.data() != null) {
        return User.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      AppErrorHandler.handleError(e);
      throw AppException('Failed to get user: $e');
    }
  }

  /// Create or update user
  Future<void> createOrUpdateUser(User user) async {
    try {
      await _firestore.collection(_usersCollection).doc(user.id).set(user.toMap());
    } catch (e) {
      AppErrorHandler.handleError(e);
      throw AppException('Failed to save user: $e');
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    required String userId,
    String? name,
    String? bio,
    String? profileImageUrl,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      if (name != null) updates['name'] = name;
      if (bio != null) updates['bio'] = bio;
      if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;

      await _firestore.collection(_usersCollection).doc(userId).update(updates);
    } catch (e) {
      AppErrorHandler.handleError(e);
      throw AppException('Failed to update user profile: $e');
    }
  }

  /// Listen to user changes
  Stream<User?> getUserStream(String userId) {
    return _firestore.collection(_usersCollection).doc(userId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return User.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  /// Get current authenticated user
  Future<User?> getCurrentUser() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;
      
      return await getUserById(currentUser.uid);
    } catch (e) {
      AppErrorHandler.handleError(e);
      throw AppException('Failed to get current user: $e');
    }
  }

  /// Update user's favorite tours (SIMPLE favorites feature)
  Future<void> updateFavorites(List<String> favoriteTourIds) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw AppException('User not authenticated');

      await _firestore.collection(_usersCollection).doc(currentUser.uid).update({
        'favoriteTours': favoriteTourIds,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      AppErrorHandler.handleError(e);
      throw AppException('Failed to update favorites: $e');
    }
  }
}