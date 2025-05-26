import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../features/tours/domain/enums/tour_category.dart';
import '../features/tours/domain/enums/tour_difficulty.dart';
import '../models/tour_plan.dart';
//import '../models/location_suggestion.dart';
import 'base_repository.dart';

class TourPlanRepository extends BaseRepository {
  TourPlanRepository(super.firestore);

  final String _collection = FirebaseCollections.tourPlans;

  /// Create a new tour plan
  Future<String> createTourPlan(TourPlan tourPlan) async {
    return await handleAsyncFirestoreError(() async {
      final docRef = await firestore.collection(_collection).add(tourPlan.toMap());
      return docRef.id;
    });
  }

  /// Update an existing tour plan
  Future<void> updateTourPlan(TourPlan tourPlan) async {
    return await handleAsyncFirestoreError(() async {
      await firestore.collection(_collection).doc(tourPlan.id).update(tourPlan.toMap());
    });
  }

  /// Delete a tour plan
  Future<void> deleteTourPlan(String tourPlanId) async {
    return await handleAsyncFirestoreError(() async {
      await firestore.collection(_collection).doc(tourPlanId).delete();
    });
  }

  /// Get tour plan by ID
  Future<TourPlan?> getTourPlanById(String tourPlanId) async {
    return await handleAsyncFirestoreError(() async {
      final doc = await firestore.collection(_collection).doc(tourPlanId).get();
      
      if (doc.exists && doc.data() != null) {
        return TourPlan.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  /// Get tour plans by creator
  Future<List<TourPlan>> getTourPlansByCreator(String creatorId) async {
    return await handleAsyncFirestoreError(() async {
      final query = await firestore
          .collection(_collection)
          .where('creatorId', isEqualTo: creatorId)
          .orderBy('updatedAt', descending: true)
          .get();

      return query.docs
          .map((doc) => TourPlan.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Get public tour plans with pagination
  Future<List<TourPlan>> getPublicTourPlans({
    DocumentSnapshot? lastDocument,
    int limit = 20,
    TourCategory? category,
    TourDifficulty? difficulty,
    String? searchQuery,
  }) async {
    return await handleAsyncFirestoreError(() async {
      Query query = firestore.collection(_collection)
          .where('isPublic', isEqualTo: true);

      // Apply filters
      if (category != null) {
        query = query.where('category', isEqualTo: category.name);
      }
      
      if (difficulty != null) {
        query = query.where('difficulty', isEqualTo: difficulty.name);
      }

      // Add search functionality (basic text search)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query
            .where('title', isGreaterThanOrEqualTo: searchQuery)
            .where('title', isLessThan: '${searchQuery}z');
      }

      // Order by creation date
      query = query.orderBy('createdAt', descending: true);

      // Pagination
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      query = query.limit(limit);

      final querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) => TourPlan.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  /// Get trending tour plans (based on likes and recent activity)
  Future<List<TourPlan>> getTrendingTourPlans({int limit = 10}) async {
    return await handleAsyncFirestoreError(() async {
      final query = await firestore
          .collection(_collection)
          .where('isPublic', isEqualTo: true)
          .orderBy('likes', descending: true)
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => TourPlan.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Get tour plans by location proximity
  Future<List<TourPlan>> getTourPlansByLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 50,
    int limit = 20,
  }) async {
    return await handleAsyncFirestoreError(() async {
      // For now, we'll implement basic location filtering
      // In production, you'd want to use GeoFirestore for proper geospatial queries
      final query = await firestore
          .collection(_collection)
          .where('isPublic', isEqualTo: true)
          .limit(limit * 2) // Get more to filter by distance
          .get();

      final tourPlans = query.docs
          .map((doc) => TourPlan.fromMap(doc.data(), doc.id))
          .toList();

      // Filter by distance (basic implementation)
      // In production, implement proper haversine distance calculation
      return tourPlans.take(limit).toList();
    });
  }

  /// Like/Unlike a tour plan
  Future<void> toggleLike(String tourPlanId, String userId, bool isLiked) async {
    return await handleAsyncFirestoreError(() async {
      final batch = firestore.batch();
      
      // Update likes count
      final tourPlanRef = firestore.collection(_collection).doc(tourPlanId);
      batch.update(tourPlanRef, {
        'likes': FieldValue.increment(isLiked ? 1 : -1),
      });

      // Update user's likes collection
      final userLikeRef = firestore
          .collection('users')
          .doc(userId)
          .collection('liked_tours')
          .doc(tourPlanId);

      if (isLiked) {
        batch.set(userLikeRef, {'likedAt': FieldValue.serverTimestamp()});
      } else {
        batch.delete(userLikeRef);
      }

      await batch.commit();
    });
  }

  /// Save/Unsave a tour plan
  Future<void> toggleSave(String tourPlanId, String userId, bool isSaved) async {
    return await handleAsyncFirestoreError(() async {
      final batch = firestore.batch();
      
      // Update saves count
      final tourPlanRef = firestore.collection(_collection).doc(tourPlanId);
      batch.update(tourPlanRef, {
        'saves': FieldValue.increment(isSaved ? 1 : -1),
      });

      // Update user's saved collection
      final userSaveRef = firestore
          .collection('users')
          .doc(userId)
          .collection('saved_tours')
          .doc(tourPlanId);

      if (isSaved) {
        batch.set(userSaveRef, {'savedAt': FieldValue.serverTimestamp()});
      } else {
        batch.delete(userSaveRef);
      }

      await batch.commit();
    });
  }

  /// Stream tour plans for real-time updates
  Stream<List<TourPlan>> streamPublicTourPlans({
    TourCategory? category,
    int limit = 20,
  }) {
    Query query = firestore.collection(_collection)
        .where('isPublic', isEqualTo: true);

    if (category != null) {
      query = query.where('category', isEqualTo: category.name);
    }

    query = query
        .orderBy('createdAt', descending: true)
        .limit(limit);

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => TourPlan.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  /// Get user's liked tour plans
  Future<List<String>> getUserLikedTourPlans(String userId) async {
    return await handleAsyncFirestoreError(() async {
      final query = await firestore
          .collection('users')
          .doc(userId)
          .collection('liked_tours')
          .get();

      return query.docs.map((doc) => doc.id).toList();
    });
  }

  /// Get user's saved tour plans
  Future<List<String>> getUserSavedTourPlans(String userId) async {
    return await handleAsyncFirestoreError(() async {
      final query = await firestore
          .collection('users')
          .doc(userId)
          .collection('saved_tours')
          .get();

      return query.docs.map((doc) => doc.id).toList();
    });
  }
}