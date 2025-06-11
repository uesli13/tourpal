import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/tour_plan.dart';
import 'tour_data_source.dart';

class FirestoreTourDataSource implements TourDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<TourPlan>> getAllTours() async {
    try {
      final querySnapshot = await _firestore
          .collection('tourPlans')
          .where('status', isEqualTo: 'published')
          .get();

      return querySnapshot.docs.map((doc) {
        return TourPlan.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch tours: $e');
    }
  }

  @override
  Future<TourPlan?> getTourById(String id) async {
    try {
      final doc = await _firestore.collection('tourPlans').doc(id).get();
      
      if (!doc.exists) {
        return null;
      }

      return TourPlan.fromMap(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Failed to fetch tour: $e');
    }
  }

  @override
  Future<TourPlan> createTour(TourPlan tour) async {
    try {
      final docRef = await _firestore.collection('tourPlans').add(tour.toMap());
      
      // Return the tour with the new ID
      return tour.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Failed to create tour: $e');
    }
  }

  @override
  Future<TourPlan> updateTour(TourPlan tour) async {
    try {
      await _firestore
          .collection('tourPlans')
          .doc(tour.id)
          .update(tour.toMap());
      
      return tour;
    } catch (e) {
      throw Exception('Failed to update tour: $e');
    }
  }

  @override
  Future<void> deleteTour(String id) async {
    try {
      await _firestore.collection('tourPlans').doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete tour: $e');
    }
  }

  @override
  Future<List<TourPlan>> getToursByGuideId(String guideId) async {
    try {
      final querySnapshot = await _firestore
          .collection('tourPlans')
          .where('guideId', isEqualTo: guideId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return TourPlan.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch tours by guide: $e');
    }
  }

  @override
  Future<List<TourPlan>> searchTours(String query) async {
    try {
      final querySnapshot = await _firestore
          .collection('tourPlans')
          .where('status', isEqualTo: 'published')
          .get();

      // Filter results based on the search query
      final filteredTours = querySnapshot.docs.where((doc) {
        final data = doc.data();
        final title = (data['title'] as String? ?? '').toLowerCase();
        final description = (data['description'] as String? ?? '').toLowerCase();
        final searchLower = query.toLowerCase();
        
        return title.contains(searchLower) || description.contains(searchLower);
      }).map((doc) {
        return TourPlan.fromMap(doc.data(), doc.id);
      }).toList();

      return filteredTours;
    } catch (e) {
      throw Exception('Failed to search tours: $e');
    }
  }
}