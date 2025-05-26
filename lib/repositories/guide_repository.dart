import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/guide.dart';
import '../core/exceptions/app_exceptions.dart';

class GuideRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'guides';

  // Get guide by user ID
  Future<Guide?> getGuideByUserId(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return Guide.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw DatabaseException('Failed to get guide: ${e.toString()}');
    }
  }

  // Create guide profile
  Future<void> createGuide(Guide guide) async {
    try {
      await _firestore.collection(_collection).doc(guide.userId).set(guide.toMap());
    } catch (e) {
      throw DatabaseException('Failed to create guide: ${e.toString()}');
    }
  }

  // Update guide profile
  Future<void> updateGuide(Guide guide) async {
    try {
      await _firestore.collection(_collection).doc(guide.userId).update(guide.toMap());
    } catch (e) {
      throw DatabaseException('Failed to update guide: ${e.toString()}');
    }
  }

  // Get available guides
  Future<List<Guide>> getAvailableGuides() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('isAvailable', isEqualTo: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => Guide.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw DatabaseException('Failed to get available guides: ${e.toString()}');
    }
  }

  // Update guide availability
  Future<void> updateAvailability(String userId, bool isAvailable) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'isAvailable': isAvailable,
      });
    } catch (e) {
      throw DatabaseException('Failed to update guide availability: ${e.toString()}');
    }
  }
}