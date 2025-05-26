import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/tour_plan.dart';
import '../core/constants/app_constants.dart';

class TourPlanRepository {
  final FirebaseFirestore _firestore;

  TourPlanRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<TourPlan>> getAllTourPlans() async {
    try {
      final querySnapshot = await _firestore
          .collection(FirebaseCollections.tourPlans)
          .get();

      return querySnapshot.docs
          .map((doc) => TourPlan.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch tour plans: $e');
    }
  }

  Future<List<TourPlan>> getTourPlansByGuide(String guideId) async {
    try {
      final querySnapshot = await _firestore
          .collection(FirebaseCollections.tourPlans)
          .where('guideId', isEqualTo: guideId)
          .get();

      return querySnapshot.docs
          .map((doc) => TourPlan.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch guide tour plans: $e');
    }
  }

  Future<TourPlan?> getTourPlan(String id) async {
    try {
      final doc = await _firestore
          .collection(FirebaseCollections.tourPlans)
          .doc(id)
          .get();

      if (doc.exists) {
        return TourPlan.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch tour plan: $e');
    }
  }

  Future<TourPlan> createTourPlan(TourPlan tourPlan) async {
    try {
      final docRef = await _firestore
          .collection(FirebaseCollections.tourPlans)
          .add(tourPlan.toMap());

      // Create a new TourPlan with the generated ID
      return TourPlan(
        id: docRef.id,
        guideId: tourPlan.guideId,
        title: tourPlan.title,
        description: tourPlan.description,
        duration: tourPlan.duration,
        difficulty: tourPlan.difficulty,
        tags: tourPlan.tags,
        isPublic: tourPlan.isPublic,
        averageRating: tourPlan.averageRating,
        totalReviews: tourPlan.totalReviews,
        bookingCount: tourPlan.bookingCount,
        favoriteCount: tourPlan.favoriteCount,
        price: tourPlan.price,
        imageUrl: tourPlan.imageUrl,
        createdAt: tourPlan.createdAt,
        updatedAt: tourPlan.updatedAt,
      );
    } catch (e) {
      throw Exception('Failed to create tour plan: $e');
    }
  }

  Future<void> updateTourPlan(TourPlan tourPlan) async {
    try {
      await _firestore
          .collection(FirebaseCollections.tourPlans)
          .doc(tourPlan.id)
          .update(tourPlan.toMap());
    } catch (e) {
      throw Exception('Failed to update tour plan: $e');
    }
  }

  Future<void> deleteTourPlan(String id) async {
    try {
      await _firestore
          .collection(FirebaseCollections.tourPlans)
          .doc(id)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete tour plan: $e');
    }
  }

  Future<List<TourPlan>> searchTourPlans({
    String? query,
    String? location,
    double? maxPrice,
    List<String>? tags,
  }) async {
    try {
      Query<Map<String, dynamic>> queryRef = _firestore
          .collection(FirebaseCollections.tourPlans);

      if (location != null && location.isNotEmpty) {
        queryRef = queryRef.where('location', isEqualTo: location);
      }

      if (maxPrice != null) {
        queryRef = queryRef.where('price', isLessThanOrEqualTo: maxPrice);
      }

      final querySnapshot = await queryRef.get();
      List<TourPlan> results = querySnapshot.docs
          .map((doc) => TourPlan.fromMap(doc.data(), doc.id))
          .toList();

      // Filter by query text if provided
      if (query != null && query.isNotEmpty) {
        results = results.where((tourPlan) =>
            tourPlan.title.toLowerCase().contains(query.toLowerCase()) ||
            tourPlan.description.toLowerCase().contains(query.toLowerCase())
        ).toList();
      }

      // Filter by tags if provided
      if (tags != null && tags.isNotEmpty) {
        results = results.where((tourPlan) =>
            tags.any((tag) => tourPlan.tags.contains(tag))
        ).toList();
      }

      return results;
    } catch (e) {
      throw Exception('Failed to search tour plans: $e');
    }
  }

  Stream<List<TourPlan>> watchTourPlans() {
    return _firestore
        .collection(FirebaseCollections.tourPlans)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TourPlan.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<TourPlan>> watchTourPlansByGuide(String guideId) {
    return _firestore
        .collection(FirebaseCollections.tourPlans)
        .where('guideId', isEqualTo: guideId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TourPlan.fromMap(doc.data(), doc.id))
            .toList());
  }
}